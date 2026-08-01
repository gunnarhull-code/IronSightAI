import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/condition_rating.dart';
import 'package:ironsight_ai/domain/entities/detailed_category_response.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/inspection.dart';
import 'package:ironsight_ai/domain/entities/inspection_depth.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/entities/scorecard_category.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';
import 'package:ironsight_ai/domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import 'package:ironsight_ai/domain/inspection_review_summary.dart';
import 'package:ironsight_ai/domain/repositories/local_inspection_repository.dart';
import 'package:ironsight_ai/domain/use_cases/find_active_drafts_for_equipment.dart';
import 'package:ironsight_ai/features/equipment_id_capture/presentation/equipment_id_capture_labels.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_list_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_review_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_workspace_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/widgets/condition_rating_controls.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_id_capture.dart';
import 'support/fake_equipment_repository.dart';

EquipmentIdCaptureController _manualCaptureController({
  required EquipmentIdCaptureKind kind,
  ConfirmedEquipmentIdValue? initialConfirmed,
}) {
  return EquipmentIdCaptureController(
    kind: kind,
    imageCapture: FakeImageCapture(isSupported: false),
    textRecognition: FakeTextRecognition(isSupported: false),
    cameraPermission: FakeCameraPermission(),
    initialConfirmed: initialConfirmed,
  );
}

Equipment _equipment({
  required String id,
  required String companyId,
  String assetName = 'Excavator 1',
}) {
  final now = DateTime.utc(2026, 7, 1);
  return Equipment(
    id: id,
    companyId: companyId,
    assetName: assetName,
    manufacturer: 'Caterpillar',
    model: '320',
    serialNumber: 'SN-$id',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late OfflineInspectionWorkspace workspace;

  setUp(() {
    final database = openMemoryAppDatabase();
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: database,
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
    );
  });

  tearDown(() async {
    await workspace.dispose();
  });

  group('tenant-scoped local context', () {
    test('persists active company/user context', () async {
      final activated = await workspace.tenantContext.activate(
        companyId: 'company-a',
        userId: 'user-1',
      );
      expect(activated.companyId, 'company-a');
      expect(activated.userId, 'user-1');

      final active = await workspace.tenantContext.getActive();
      expect(active?.companyId, 'company-a');
      expect(active?.userId, 'user-1');
    });

    test('clears other company equipment on tenant switch', () async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_equipment(id: 'eq-a', companyId: 'company-a')],
      );
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-b',
        equipment: [_equipment(id: 'eq-b', companyId: 'company-b')],
      );

      await workspace.tenantContext.activate(
        companyId: 'company-a',
        userId: 'user-1',
      );
      expect(
        await workspace.equipmentCatalog.listForCompany('company-a'),
        hasLength(1),
      );
      expect(
        await workspace.equipmentCatalog.listForCompany('company-b'),
        hasLength(1),
      );

      await workspace.tenantContext.activate(
        companyId: 'company-b',
        userId: 'user-2',
      );
      expect(
        await workspace.equipmentCatalog.listForCompany('company-a'),
        isEmpty,
      );
      expect(
        await workspace.equipmentCatalog.listForCompany('company-b'),
        hasLength(1),
      );
    });
  });

  group('local equipment cache', () {
    test('lists and reads only the requested company catalog', () async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [
          _equipment(id: 'eq-1', companyId: 'company-a', assetName: 'A1'),
          _equipment(id: 'eq-2', companyId: 'company-a', assetName: 'A2'),
        ],
      );
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-b',
        equipment: [
          _equipment(id: 'eq-9', companyId: 'company-b', assetName: 'B1'),
        ],
      );

      final listed = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(listed.map((e) => e.id), ['eq-1', 'eq-2']);
      expect(
        await workspace.equipmentCatalog.getById(
          companyId: 'company-a',
          equipmentId: 'eq-9',
        ),
        isNull,
      );
    });

    test(
      'refresh updates local catalog from remote without throwing',
      () async {
        final remote = FakeEquipmentRepository(
          equipment: [
            _equipment(id: 'eq-1', companyId: 'company-a', assetName: 'Remote'),
          ],
        );
        final refreshWorkspace = OfflineInspectionWorkspace.fromDatabase(
          database: openMemoryAppDatabase(),
          remoteEquipmentRepository: remote,
          authSession: FakeAuthSessionReader(),
        );
        addTearDown(refreshWorkspace.dispose);

        final ok = await refreshWorkspace.catalogRefresh.refreshCompanyCatalog(
          'company-a',
        );
        expect(ok, isTrue);
        final local = await refreshWorkspace.equipmentCatalog.listForCompany(
          'company-a',
        );
        expect(local.single.assetName, 'Remote');
      },
    );

    test('refresh failure leaves existing local catalog intact', () async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [
          _equipment(id: 'eq-1', companyId: 'company-a', assetName: 'Cached'),
        ],
      );
      final remote = FakeEquipmentRepository(getError: Exception('offline'));
      final refreshWorkspace = OfflineInspectionWorkspace.fromDatabase(
        database: workspace.database,
        remoteEquipmentRepository: remote,
        authSession: FakeAuthSessionReader(),
      );

      final ok = await refreshWorkspace.catalogRefresh.refreshCompanyCatalog(
        'company-a',
      );
      expect(ok, isFalse);
      final local = await workspace.equipmentCatalog.listForCompany(
        'company-a',
      );
      expect(local.single.assetName, 'Cached');
    });
  });

  group('offline inspection drafts', () {
    test(
      'creates draft from locally available equipment and reopens it',
      () async {
        await workspace.equipmentCatalog.replaceCompanyCatalog(
          companyId: 'company-a',
          equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
        );
        final draft = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: 'eq-1',
          createdByUserId: 'user-1',
        );

        final reopened = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: draft.id,
        );
        expect(reopened?.id, draft.id);
        expect(
          reopened?.completionStatus,
          InspectionCompletionStatus.inProgress,
        );
      },
    );

    test(
      'duplicate active drafts are discoverable for Resume/Create Another',
      () async {
        final first = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: 'eq-1',
          createdByUserId: 'user-1',
        );
        final second = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: 'eq-1',
          createdByUserId: 'user-1',
        );

        final drafts = await FindActiveDraftsForEquipment(
          workspace.inspections,
        )(companyId: 'company-a', equipmentId: 'eq-1');
        expect(drafts.map((d) => d.id), containsAll([first.id, second.id]));
      },
    );

    test(
      'persists ratings, detailed responses, and notes immediately',
      () async {
        final draft = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: 'eq-1',
          createdByUserId: 'user-1',
        );

        await workspace.inspections.saveCategoryRating(
          companyId: 'company-a',
          inspectionId: draft.id,
          category: ScorecardCategory.engine,
          rating: ConditionRating.good,
          updatedByUserId: 'user-1',
        );
        await workspace.inspections.saveDetailedCategoryResponse(
          companyId: 'company-a',
          inspectionId: draft.id,
          response: const DetailedCategoryResponse(
            category: ScorecardCategory.engine,
            items: [
              DetailedChecklistItemResponse(
                itemKey: 'oil',
                labelSnapshot: 'Oil',
                sortOrder: 0,
                rating: ConditionRating.fair,
              ),
            ],
          ),
          updatedByUserId: 'user-1',
        );
        await workspace.inspections.updateMetadata(
          companyId: 'company-a',
          inspectionId: draft.id,
          overallNotes: 'Field notes',
          updatedByUserId: 'user-1',
        );

        final saved = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: draft.id,
        );
        expect(
          saved!.ratingFor(ScorecardCategory.engine),
          ConditionRating.good,
        );
        expect(
          saved.detailedFor(ScorecardCategory.engine).items.single.rating,
          ConditionRating.fair,
        );
        expect(saved.overallNotes, 'Field notes');
        expect(saved.syncStatus, InspectionSyncStatus.localOnly);
      },
    );

    test('review summary highlights incomplete categories', () async {
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );
      await workspace.inspections.saveCategoryRating(
        companyId: 'company-a',
        inspectionId: draft.id,
        category: ScorecardCategory.engine,
        rating: ConditionRating.good,
      );
      final loaded = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      final summary = buildInspectionReviewSummary(loaded!);
      expect(summary.hasIncompleteCategories, isTrue);
      expect(
        summary.incompleteCategories,
        isNot(contains(ScorecardCategory.engine)),
      );
      expect(summary.incompleteCategories, contains(ScorecardCategory.cab));
    });

    test('completes locally and blocks later mutation', () async {
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );
      final completed = await workspace.inspections.complete(
        companyId: 'company-a',
        inspectionId: draft.id,
        updatedByUserId: 'user-1',
      );
      expect(completed.completionStatus, InspectionCompletionStatus.completed);
      expect(completed.syncStatus, InspectionSyncStatus.localOnly);

      expect(
        () => workspace.inspections.saveCategoryRating(
          companyId: 'company-a',
          inspectionId: draft.id,
          category: ScorecardCategory.engine,
          rating: ConditionRating.poor,
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });

    test('discarded drafts cannot be mutated or completed', () async {
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );
      await workspace.inspections.discardIncomplete(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(
        () => workspace.inspections.complete(
          companyId: 'company-a',
          inspectionId: draft.id,
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });
  });

  group('persistence after database reconstruction', () {
    test('tenant context, equipment, and inspections survive reopen', () async {
      // Avoid dual AppDatabase wrappers over one file during sequential reopen.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(() {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      });

      final directory = await Directory.systemTemp.createTemp('ironsight_ws_');
      addTearDown(() async {
        await directory.delete(recursive: true);
      });
      final file = File('${directory.path}/ws.sqlite');
      final fileDb = openFileAppDatabase(
        file,
        encryptionKey: 'persist-key',
        requireCipher: false,
      );
      final fileWorkspace = OfflineInspectionWorkspace.fromDatabase(
        database: fileDb,
        remoteEquipmentRepository: FakeEquipmentRepository(),
        authSession: FakeAuthSessionReader(),
      );
      await fileWorkspace.tenantContext.activate(
        companyId: 'company-a',
        userId: 'user-1',
      );
      await fileWorkspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
      );
      final created = await fileWorkspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );
      await fileWorkspace.inspections.updateMetadata(
        companyId: 'company-a',
        inspectionId: created.id,
        overallNotes: 'survives',
      );
      await fileWorkspace.dispose();

      final reopenedDb = openFileAppDatabase(
        file,
        encryptionKey: 'persist-key',
        requireCipher: false,
      );
      final reopened = OfflineInspectionWorkspace.fromDatabase(
        database: reopenedDb,
        remoteEquipmentRepository: FakeEquipmentRepository(),
        authSession: FakeAuthSessionReader(),
      );
      addTearDown(reopened.dispose);

      expect(
        (await reopened.tenantContext.getActive())?.companyId,
        'company-a',
      );
      expect(
        (await reopened.equipmentCatalog.listForCompany('company-a')).single.id,
        'eq-1',
      );
      final restored = await reopened.inspections.getById(
        companyId: 'company-a',
        inspectionId: created.id,
      );
      expect(restored?.overallNotes, 'survives');
    });
  });

  group('inspection UI states', () {
    testWidgets('list shows empty and populated states', (tester) async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InspectionListScreen(
            companyId: 'company-a',
            userId: 'user-1',
            inspections: workspace.inspections,
            equipmentCatalog: workspace.equipmentCatalog,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No local inspections yet'), findsOneWidget);

      await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );
      await tester.tap(find.byTooltip('Refresh list'));
      await tester.pumpAndSettle();
      expect(find.text('Excavator 1'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.textContaining('Saved on this device only'), findsWidgets);
    });

    testWidgets('workspace persists rating tap and supports keyboard notes', (
      tester,
    ) async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
      );
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InspectionWorkspaceScreen(
            companyId: 'company-a',
            userId: 'user-1',
            inspectionId: draft.id,
            inspections: workspace.inspections,
            equipmentCatalog: workspace.equipmentCatalog,
            captureControllerFactory: _manualCaptureController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Engine'),
        200,
        scrollable: scrollable,
      );
      expect(find.text('Engine'), findsOneWidget);
      expect(find.byType(ConditionRatingControls), findsWidgets);

      final engineCard = find.widgetWithText(Card, 'Engine');
      await tester.tap(
        find.descendant(of: engineCard, matching: find.text('Good')),
      );
      await tester.pumpAndSettle();

      final saved = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(saved!.ratingFor(ScorecardCategory.engine), ConditionRating.good);

      await tester.scrollUntilVisible(
        find.text('Cosmetic'),
        200,
        scrollable: scrollable,
      );
      expect(find.text('Cosmetic'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Save notes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final notesField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration is InputDecoration &&
            (widget.decoration as InputDecoration).hintText ==
                'Optional notes (saved on this device)',
      );
      await tester.enterText(notesField, 'Walkaround notes');
      await tester.tap(find.text('Save notes'));
      await tester.pumpAndSettle();

      final withNotes = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(withNotes!.overallNotes, 'Walkaround notes');
    });

    testWidgets('manual serial and hours confirm persist on the local draft', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
      );
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InspectionWorkspaceScreen(
            companyId: 'company-a',
            userId: 'user-1',
            inspectionId: draft.id,
            inspections: workspace.inspections,
            equipmentCatalog: workspace.equipmentCatalog,
            captureControllerFactory: _manualCaptureController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Equipment identification'), findsOneWidget);

      final serialField = find.bySemanticsLabel(
        EquipmentIdCaptureLabels.serialManualField,
      );
      await tester.ensureVisible(serialField);
      await tester.enterText(serialField, 'sn-abc-99');
      await tester.pumpAndSettle();
      final serialConfirm = find.descendant(
        of: find.byKey(const ValueKey('qa-serial-capture')),
        matching: find.text('Confirm'),
      );
      await tester.ensureVisible(serialConfirm);
      await tester.tap(serialConfirm);
      await tester.pumpAndSettle();

      final hoursField = find.bySemanticsLabel(
        EquipmentIdCaptureLabels.hourManualField,
      );
      await tester.ensureVisible(hoursField);
      await tester.enterText(hoursField, '1234.5');
      await tester.pumpAndSettle();
      final hoursConfirm = find.descendant(
        of: find.byKey(const ValueKey('qa-hours-capture')),
        matching: find.text('Confirm'),
      );
      await tester.ensureVisible(hoursConfirm);
      await tester.tap(hoursConfirm);
      await tester.pumpAndSettle();

      final saved = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(saved!.serialNumber, isNotNull);
      expect(saved.serialCaptureMethod, EquipmentIdCaptureMethod.manual);
      expect(saved.hourMeterReading, 1234.5);
      expect(saved.hourMeterCaptureMethod, EquipmentIdCaptureMethod.manual);
    });

    testWidgets('reopening workspace restores confirmed equipment ID values', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
      );
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: draft.id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.serialNumber,
          value: 'CAT320GX',
          method: EquipmentIdCaptureMethod.manual,
        ),
        updatedByUserId: 'user-1',
      );
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: draft.id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.hourMeter,
          value: '2500',
          method: EquipmentIdCaptureMethod.ocrConfirmed,
          hours: 2500,
        ),
        updatedByUserId: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InspectionWorkspaceScreen(
            companyId: 'company-a',
            userId: 'user-1',
            inspectionId: draft.id,
            inspections: workspace.inspections,
            equipmentCatalog: workspace.equipmentCatalog,
            captureControllerFactory: _manualCaptureController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Confirmed: CAT320GX'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Confirmed: 2500'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Confirmed: 2500'), findsOneWidget);
      expect(find.text('Edit confirmed value'), findsNWidgets(2));
    });

    testWidgets(
      'workspace keeps scroll position after equipment ID confirm save',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await workspace.equipmentCatalog.replaceCompanyCatalog(
          companyId: 'company-a',
          equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
        );
        final draft = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: 'eq-1',
          createdByUserId: 'user-1',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: InspectionWorkspaceScreen(
              companyId: 'company-a',
              userId: 'user-1',
              inspectionId: draft.id,
              inspections: workspace.inspections,
              equipmentCatalog: workspace.equipmentCatalog,
              captureControllerFactory: _manualCaptureController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Cosmetic'),
          200,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();

        double scrollPixels() =>
            tester.state<ScrollableState>(scrollable).position.pixels;
        final before = scrollPixels();

        final cosmeticCard = find.widgetWithText(Card, 'Cosmetic');
        await tester.tap(
          find.descendant(of: cosmeticCard, matching: find.text('Fair')),
        );
        await tester.pumpAndSettle();

        expect(
          scrollPixels(),
          closeTo(before, 1.0),
          reason: 'in-place save must not jump Quick Appraisal scroll',
        );

        final saved = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: draft.id,
        );
        expect(
          saved!.ratingFor(ScorecardCategory.cosmetic),
          ConditionRating.fair,
        );
      },
    );
    testWidgets(
      'workspace keeps scroll position after in-place rating and notes save',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await workspace.equipmentCatalog.replaceCompanyCatalog(
          companyId: 'company-a',
          equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
        );
        final draft = await workspace.inspections.createDraft(
          companyId: 'company-a',
          equipmentId: 'eq-1',
          createdByUserId: 'user-1',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: InspectionWorkspaceScreen(
              companyId: 'company-a',
              userId: 'user-1',
              inspectionId: draft.id,
              inspections: workspace.inspections,
              equipmentCatalog: workspace.equipmentCatalog,
              captureControllerFactory: _manualCaptureController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Cosmetic'),
          200,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();

        double scrollPixels() =>
            tester.state<ScrollableState>(scrollable).position.pixels;

        final afterScrollToCosmetic = scrollPixels();
        expect(afterScrollToCosmetic, greaterThan(0));

        final cosmeticCard = find.widgetWithText(Card, 'Cosmetic');
        await tester.tap(
          find.descendant(of: cosmeticCard, matching: find.text('Fair')),
        );
        await tester.pumpAndSettle();

        expect(
          scrollPixels(),
          closeTo(afterScrollToCosmetic, 1.0),
          reason: 'rating save reload must not jump the Quick Appraisal list',
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        final afterRating = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: draft.id,
        );
        expect(
          afterRating!.ratingFor(ScorecardCategory.cosmetic),
          ConditionRating.fair,
        );

        await tester.scrollUntilVisible(
          find.text('Save notes'),
          200,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        final afterScrollToNotes = scrollPixels();
        expect(afterScrollToNotes, greaterThan(0));

        final notesField = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration is InputDecoration &&
              (widget.decoration as InputDecoration).hintText ==
                  'Optional notes (saved on this device)',
        );
        await tester.enterText(notesField, 'Keep my place');
        await tester.tap(find.text('Save notes'));
        await tester.pumpAndSettle();

        expect(
          scrollPixels(),
          closeTo(afterScrollToNotes, 1.0),
          reason: 'notes save reload must not jump the Quick Appraisal list',
        );

        final afterNotes = await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: draft.id,
        );
        expect(afterNotes!.overallNotes, 'Keep my place');
        expect(
          afterNotes.ratingFor(ScorecardCategory.cosmetic),
          ConditionRating.fair,
        );
      },
    );

    testWidgets('review shows incomplete categories and completes locally', (
      tester,
    ) async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
      );
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InspectionReviewScreen(
            companyId: 'company-a',
            userId: 'user-1',
            inspectionId: draft.id,
            inspections: workspace.inspections,
            equipmentCatalog: workspace.equipmentCatalog,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Incomplete:'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Incomplete:'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Complete locally'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Complete locally'));
      await tester.pumpAndSettle();
      expect(find.text('Incomplete categories'), findsOneWidget);
      await tester.tap(find.text('Complete Anyway'));
      await tester.pumpAndSettle();
      expect(find.text('Inspection completed locally'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      final completed = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(completed!.completionStatus, InspectionCompletionStatus.completed);
    });

    testWidgets('discard requires confirmation', (tester) async {
      await workspace.equipmentCatalog.replaceCompanyCatalog(
        companyId: 'company-a',
        equipment: [_equipment(id: 'eq-1', companyId: 'company-a')],
      );
      final draft = await workspace.inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-1',
        createdByUserId: 'user-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InspectionWorkspaceScreen(
            companyId: 'company-a',
            userId: 'user-1',
            inspectionId: draft.id,
            inspections: workspace.inspections,
            equipmentCatalog: workspace.equipmentCatalog,
            captureControllerFactory: _manualCaptureController,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Discard draft'));
      await tester.pumpAndSettle();
      expect(find.text('Discard draft?'), findsOneWidget);
      await tester.tap(find.text('Keep Draft'));
      await tester.pumpAndSettle();

      final stillActive = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: draft.id,
      );
      expect(stillActive!.localLifecycle, InspectionLocalLifecycle.active);
    });

    testWidgets('recoverable list error shows retry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InspectionListScreen(
            companyId: 'company-a',
            userId: 'user-1',
            inspections: _ThrowingListInspectionRepository(),
            equipmentCatalog: workspace.equipmentCatalog,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not load local inspections'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

class _ThrowingListInspectionRepository implements LocalInspectionRepository {
  @override
  Future<List<Inspection>> listForCompany(
    String companyId, {
    bool includeDiscarded = false,
  }) async {
    throw Exception('disk read failed');
  }

  @override
  Future<Inspection> complete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Inspection> createDraft({
    required String companyId,
    required String equipmentId,
    required String createdByUserId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Inspection> discardIncomplete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Inspection?> getById({
    required String companyId,
    required String inspectionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Inspection> saveCategoryRating({
    required String companyId,
    required String inspectionId,
    required ScorecardCategory category,
    required ConditionRating rating,
    String? updatedByUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Inspection> saveDetailedCategoryResponse({
    required String companyId,
    required String inspectionId,
    required DetailedCategoryResponse response,
    String? updatedByUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Inspection> updateMetadata({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
    InspectionDepth? depth,
    String? overallNotes,
    bool clearOverallNotes = false,
    String? remoteId,
    bool clearRemoteId = false,
    InspectionSyncStatus? syncStatus,
    InspectionReportStatus? reportStatus,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Inspection> saveConfirmedEquipmentId({
    required String companyId,
    required String inspectionId,
    required ConfirmedEquipmentIdValue confirmedValue,
    String? updatedByUserId,
  }) {
    throw UnimplementedError();
  }
}
