import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/data/remote/remote_connectivity_failure.dart';
import 'package:ironsight_ai/domain/entities/company.dart';
import 'package:ironsight_ai/domain/exceptions/remote_service_unavailable_exception.dart';
import 'package:ironsight_ai/domain/use_cases/resolve_company_access.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'support/fake_auth_session_reader.dart';
import 'support/fake_company_repository.dart';
import 'support/fake_equipment_repository.dart';

void main() {
  late OfflineInspectionWorkspace workspace;
  late FakeCompanyRepository companies;

  final sampleCompany = Company(
    id: 'company-a',
    name: 'Hull Equipment',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: openMemoryAppDatabase(),
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(currentUserId: 'user-1'),
    );
    companies = FakeCompanyRepository(company: sampleCompany);
  });

  tearDown(() async {
    await workspace.dispose();
  });

  ResolveCompanyAccess buildResolve() {
    return ResolveCompanyAccess(companies, workspace.tenantContext);
  }

  Future<void> activateMatchingCache() {
    return workspace.tenantContext.activate(
      companyId: 'company-a',
      userId: 'user-1',
    );
  }

  test(
    'online resolution returns company and leaves cache for refresh',
    () async {
      final resolution = await buildResolve()(userId: 'user-1');

      expect(resolution.kind, CompanyAccessKind.online);
      expect(resolution.company?.id, 'company-a');
    },
  );

  test(
    'genuine network unavailability with matching cache restores workspace',
    () async {
      await activateMatchingCache();
      companies.getError = const RemoteServiceUnavailableException(
        'network unavailable',
      );

      final resolution = await buildResolve()(userId: 'user-1');

      expect(resolution.kind, CompanyAccessKind.cached);
      expect(resolution.companyId, 'company-a');
      expect(resolution.userId, 'user-1');
      expect(resolution.resolvedCompanyId, 'company-a');
    },
  );

  test(
    'mapped TimeoutException connectivity failure restores matching cache',
    () async {
      await activateMatchingCache();
      final mapped = mapRemoteFailure(TimeoutException('connection timed out'));
      expect(mapped, isA<RemoteServiceUnavailableException>());
      companies.getError = mapped;

      final resolution = await buildResolve()(userId: 'user-1');

      expect(resolution.kind, CompanyAccessKind.cached);
      expect(resolution.companyId, 'company-a');
    },
  );

  test(
    'authorization or authentication failure does not use the cache',
    () async {
      await activateMatchingCache();
      companies.getError = Exception('Invalid JWT / not authorized');

      final resolution = await buildResolve()(userId: 'user-1');

      expect(resolution.kind, CompanyAccessKind.lookupFailed);
      expect(await workspace.tenantContext.getActive(), isNotNull);
    },
  );

  test('server or malformed-response failure does not use the cache', () async {
    await activateMatchingCache();
    companies.getError = StateError(
      'Current user profile is missing a company_id',
    );

    final resolution = await buildResolve()(userId: 'user-1');

    expect(resolution.kind, CompanyAccessKind.lookupFailed);
    expect(resolution.error, isA<StateError>());
  });

  test('unexpected exceptions do not use the cache', () async {
    await activateMatchingCache();
    companies.getError = FormatException('unexpected payload shape');

    final resolution = await buildResolve()(userId: 'user-1');

    expect(resolution.kind, CompanyAccessKind.lookupFailed);
    expect(resolution.error, isA<FormatException>());
  });

  test(
    'user mismatch rejects another user\'s cached company context',
    () async {
      await workspace.tenantContext.activate(
        companyId: 'company-a',
        userId: 'user-1',
      );
      companies.getError = const RemoteServiceUnavailableException(
        'network unavailable',
      );

      final resolution = await buildResolve()(userId: 'user-2');

      expect(resolution.kind, CompanyAccessKind.offlineUnavailable);
    },
  );

  test(
    'tenant isolation: company B cache is not used for user A offline',
    () async {
      await workspace.tenantContext.activate(
        companyId: 'company-b',
        userId: 'user-b',
      );
      companies.getError = const RemoteServiceUnavailableException(
        'network unavailable',
      );

      final resolution = await buildResolve()(userId: 'user-a');

      expect(resolution.kind, CompanyAccessKind.offlineUnavailable);
      final stillCached = await workspace.tenantContext.getActive();
      expect(stillCached?.companyId, 'company-b');
      expect(stillCached?.userId, 'user-b');
    },
  );

  test('no-cache offline failure is recoverable offlineUnavailable', () async {
    companies.getError = const RemoteServiceUnavailableException(
      'network unavailable',
    );

    final resolution = await buildResolve()(userId: 'user-1');

    expect(resolution.kind, CompanyAccessKind.offlineUnavailable);
    expect(resolution.error, isA<RemoteServiceUnavailableException>());
  });

  test('sign-out clear prevents stale cached context restore', () async {
    await activateMatchingCache();
    await workspace.tenantContext.clear();
    companies.getError = const RemoteServiceUnavailableException(
      'network unavailable',
    );

    final resolution = await buildResolve()(userId: 'user-1');

    expect(resolution.kind, CompanyAccessKind.offlineUnavailable);
  });

  test('online null membership returns onboarding', () async {
    companies.company = null;

    final resolution = await buildResolve()(userId: 'user-1');

    expect(resolution.kind, CompanyAccessKind.onboarding);
  });

  test(
    'online success is preferred over existing cache (refresh path)',
    () async {
      await workspace.tenantContext.activate(
        companyId: 'company-old',
        userId: 'user-1',
      );
      companies.company = sampleCompany.copyWith(id: 'company-new');

      final resolution = await buildResolve()(userId: 'user-1');

      expect(resolution.kind, CompanyAccessKind.online);
      expect(resolution.company?.id, 'company-new');
    },
  );

  test('rejects empty userId', () async {
    expect(() => buildResolve()(userId: '  '), throwsA(isA<ArgumentError>()));
  });

  group('remote connectivity classification', () {
    test('treats TimeoutException as connectivity failure', () {
      expect(
        isRemoteConnectivityFailure(TimeoutException('timed out')),
        isTrue,
      );
    });

    test('does not treat Auth-like or PostgREST-like failures as offline', () {
      expect(
        isRemoteConnectivityFailure(Exception('Invalid login credentials')),
        isFalse,
      );
      expect(
        isRemoteConnectivityFailure(
          StateError('Current user profile is missing a company_id'),
        ),
        isFalse,
      );
      expect(isRemoteConnectivityFailure(FormatException('bad json')), isFalse);
      expect(
        isRemoteConnectivityFailure(
          const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
        ),
        isFalse,
      );
    });

    test('mapRemoteFailure wraps only connectivity failures', () {
      final wrapped = mapRemoteFailure(TimeoutException('timed out'));
      expect(wrapped, isA<RemoteServiceUnavailableException>());

      final unchanged = FormatException('bad json');
      expect(identical(mapRemoteFailure(unchanged), unchanged), isTrue);

      final postgrest = const PostgrestException(
        message: 'row-level security',
        code: '42501',
      );
      expect(identical(mapRemoteFailure(postgrest), postgrest), isTrue);
    });

    test(
      'classifies http IOClient failed-host-lookup wrapper '
      '(_ClientSocketException), not merely a plain ClientException',
      () async {
        final transport = await _captureIoClientFailedHostLookup();

        // Exact Android/PostgREST transport shape from http 1.6 IOClient:
        // private `_ClientSocketException extends ClientException
        // implements SocketException`.
        expect(transport, isA<http.ClientException>());
        expect(transport, isA<SocketException>());
        expect(
          transport.runtimeType.toString(),
          '_ClientSocketException',
          reason:
              'Regression guard: classifier must not rely on runtimeType '
              'name ClientException/SocketException alone',
        );
        expect(
          isRemoteConnectivityFailure(transport),
          isTrue,
          reason:
              'Samsung S22 airplane-mode path: PostgREST rethrows this '
              'wrapper unchanged from PostgrestBuilder._executeWithRetry',
        );

        final mapped = mapRemoteFailure(transport);
        expect(mapped, isA<RemoteServiceUnavailableException>());
        expect(
          (mapped as RemoteServiceUnavailableException).cause,
          same(transport),
        );
      },
    );

    test(
      'mapped IOClient failed-host-lookup restores matching company cache',
      () async {
        await activateMatchingCache();
        final transport = await _captureIoClientFailedHostLookup();
        companies.getError = mapRemoteFailure(transport);

        final resolution = await buildResolve()(userId: 'user-1');

        expect(resolution.kind, CompanyAccessKind.cached);
        expect(resolution.companyId, 'company-a');
        expect(resolution.userId, 'user-1');
      },
    );

    test(
      'PostgREST application exception after cache does not restore workspace',
      () async {
        await activateMatchingCache();
        companies.getError = mapRemoteFailure(
          const PostgrestException(
            message: 'new row violates row-level security policy',
            code: '42501',
          ),
        );

        final resolution = await buildResolve()(userId: 'user-1');

        expect(resolution.kind, CompanyAccessKind.lookupFailed);
        expect(resolution.error, isA<PostgrestException>());
      },
    );
  });
}

/// Produces the real http 1.6 `IOClient` failed-host-lookup exception
/// (`_ClientSocketException`), matching PostgREST's Android transport path.
Future<Object> _captureIoClientFailedHostLookup() async {
  final client = http.Client();
  try {
    await client.get(Uri.http('http.invalid', '/'));
    fail('Expected failed host lookup against http.invalid');
  } catch (error) {
    return error;
  } finally {
    client.close();
  }
}
