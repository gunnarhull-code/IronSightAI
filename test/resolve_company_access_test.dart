import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/company.dart';
import 'package:ironsight_ai/domain/use_cases/resolve_company_access.dart';

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
    return ResolveCompanyAccess(
      companyRepository: companies,
      tenantContextRepository: workspace.tenantContext,
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
    'offline cold start restores cached context for matching user',
    () async {
      await workspace.tenantContext.activate(
        companyId: 'company-a',
        userId: 'user-1',
      );
      companies.getError = Exception('network unavailable');

      final resolution = await buildResolve()(userId: 'user-1');

      expect(resolution.kind, CompanyAccessKind.cached);
      expect(resolution.companyId, 'company-a');
      expect(resolution.userId, 'user-1');
      expect(resolution.resolvedCompanyId, 'company-a');
    },
  );

  test('no-cache offline failure is recoverable offlineUnavailable', () async {
    companies.getError = Exception('network unavailable');

    final resolution = await buildResolve()(userId: 'user-1');

    expect(resolution.kind, CompanyAccessKind.offlineUnavailable);
    expect(resolution.error, isA<Exception>());
  });

  test('sign-out clear prevents stale cached context restore', () async {
    await workspace.tenantContext.activate(
      companyId: 'company-a',
      userId: 'user-1',
    );
    await workspace.tenantContext.clear();
    companies.getError = Exception('network unavailable');

    final resolution = await buildResolve()(userId: 'user-1');

    expect(resolution.kind, CompanyAccessKind.offlineUnavailable);
  });

  test(
    'user mismatch rejects another user\'s cached company context',
    () async {
      await workspace.tenantContext.activate(
        companyId: 'company-a',
        userId: 'user-1',
      );
      companies.getError = Exception('network unavailable');

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
      companies.getError = Exception('network unavailable');

      final resolution = await buildResolve()(userId: 'user-a');

      expect(resolution.kind, CompanyAccessKind.offlineUnavailable);
      final stillCached = await workspace.tenantContext.getActive();
      expect(stillCached?.companyId, 'company-b');
      expect(stillCached?.userId, 'user-b');
    },
  );

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
}
