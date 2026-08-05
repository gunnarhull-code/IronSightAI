import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/app/app.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/company.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/exceptions/remote_service_unavailable_exception.dart';
import 'package:ironsight_ai/features/auth/presentation/auth_gate.dart';
import 'package:ironsight_ai/features/company/presentation/company_gate.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_company_repository.dart';
import 'support/fake_equipment_repository.dart';

void main() {
  late OfflineInspectionWorkspace workspace;
  late FakeAuthSessionReader authSession;
  late FakeCompanyRepository companies;

  final sampleCompany = Company(
    id: 'company-a',
    name: 'Hull Equipment',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    authSession = FakeAuthSessionReader(currentUserId: 'user-1');
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: openMemoryAppDatabase(),
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: authSession,
    );
    companies = FakeCompanyRepository(company: sampleCompany);
  });

  tearDown(() async {
    await workspace.dispose();
  });

  Future<void> pumpGate(
    WidgetTester tester, {
    required bool isSignedIn,
    StreamController<bool>? signedIn,
    Future<void> Function()? signOut,
  }) async {
    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          signedInHome: CompanyGate(
            repository: companies,
            workspace: workspace,
            authSession: authSession,
            signOut: signOut,
          ),
          isSignedIn: () => isSignedIn,
          onSignedInChanged: () =>
              signedIn?.stream ?? const Stream<bool>.empty(),
        ),
        workspaceOverride: workspace,
        companyRepositoryOverride: companies,
        authSessionOverride: authSession,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'offline cold start restores workspace when cache matches auth user',
    (tester) async {
      await workspace.prepareTenant(companyId: 'company-a', userId: 'user-1');
      companies.getError = const RemoteServiceUnavailableException(
        'network unavailable',
      );

      await pumpGate(tester, isSignedIn: true);

      expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
      expect(find.text('Start Quick Appraisal'), findsOneWidget);
      expect(
        find.text('Starts from equipment cached on this device'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing);

      final active = await workspace.tenantContext.getActive();
      expect(active?.companyId, 'company-a');
      expect(active?.userId, 'user-1');
    },
  );

  testWidgets('offline cold start keeps existing local drafts reachable', (
    tester,
  ) async {
    await workspace.prepareTenant(companyId: 'company-a', userId: 'user-1');
    final now = DateTime.utc(2026, 8, 1);
    await workspace.equipmentCatalog.replaceCompanyCatalog(
      companyId: 'company-a',
      equipment: [
        Equipment(
          id: 'eq-1',
          companyId: 'company-a',
          assetName: 'Loader 1',
          manufacturer: 'Caterpillar',
          model: '950',
          serialNumber: 'SN-1',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    final draft = await workspace.inspections.createDraft(
      companyId: 'company-a',
      equipmentId: 'eq-1',
      createdByUserId: 'user-1',
    );
    companies.getError = const RemoteServiceUnavailableException(
      'network unavailable',
    );

    await pumpGate(tester, isSignedIn: true);

    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);

    final drafts = await workspace.inspections.listForCompany('company-a');
    expect(drafts, hasLength(1));
    expect(drafts.single.id, draft.id);
    expect(drafts.single.companyId, 'company-a');
  });

  testWidgets('online resolution refreshes cached tenant context', (
    tester,
  ) async {
    await workspace.tenantContext.activate(
      companyId: 'company-old',
      userId: 'user-1',
    );
    companies.company = sampleCompany;

    await pumpGate(tester, isSignedIn: true);

    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);
    final active = await workspace.tenantContext.getActive();
    expect(active?.companyId, 'company-a');
    expect(active?.userId, 'user-1');
  });

  testWidgets('no usable cache shows recoverable offline message', (
    tester,
  ) async {
    companies.getError = const RemoteServiceUnavailableException(
      'network unavailable',
    );

    await pumpGate(tester, isSignedIn: true);

    expect(
      find.textContaining('You\'re offline and no company is cached'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Heavy Equipment Inspections'), findsNothing);
  });

  testWidgets('authorization failure with cache does not open the workspace', (
    tester,
  ) async {
    await workspace.prepareTenant(companyId: 'company-a', userId: 'user-1');
    companies.getError = Exception('Invalid JWT / not authorized');

    await pumpGate(tester, isSignedIn: true);

    expect(
      find.text('Could not load your company. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Heavy Equipment Inspections'), findsNothing);
    expect(
      find.textContaining('You\'re offline and no company is cached'),
      findsNothing,
    );
  });

  testWidgets('sign-out clears cached company context', (tester) async {
    final signedIn = StreamController<bool>.broadcast();
    addTearDown(signedIn.close);
    var signedInFlag = true;

    await workspace.prepareTenant(companyId: 'company-a', userId: 'user-1');

    await tester.pumpWidget(
      IronSightApp(
        authGate: AuthGate(
          signedInHome: CompanyGate(
            repository: companies,
            workspace: workspace,
            authSession: authSession,
            signOut: () async {
              signedInFlag = false;
              signedIn.add(false);
            },
          ),
          isSignedIn: () => signedInFlag,
          onSignedInChanged: () => signedIn.stream,
        ),
        workspaceOverride: workspace,
        companyRepositoryOverride: companies,
        authSessionOverride: authSession,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heavy Equipment Inspections'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(await workspace.tenantContext.getActive(), isNull);
  });

  testWidgets('cached context for another user is rejected offline', (
    tester,
  ) async {
    await workspace.tenantContext.activate(
      companyId: 'company-a',
      userId: 'user-other',
    );
    companies.getError = const RemoteServiceUnavailableException(
      'network unavailable',
    );
    authSession.currentUserId = 'user-1';

    await pumpGate(tester, isSignedIn: true);

    expect(
      find.textContaining('You\'re offline and no company is cached'),
      findsOneWidget,
    );
    expect(find.text('Heavy Equipment Inspections'), findsNothing);

    // Cache row is left untouched — rejection must not clear another identity.
    final active = await workspace.tenantContext.getActive();
    expect(active?.userId, 'user-other');
    expect(active?.companyId, 'company-a');
  });
}
