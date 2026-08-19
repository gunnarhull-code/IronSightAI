import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/app/router.dart';
import 'package:ironsight_ai/data/local/drift/app_database.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/condition_rating.dart';
import 'package:ironsight_ai/domain/entities/inspection_machine_source.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/entities/scorecard_category.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/guided_quick_appraisal_completeness.dart';
import 'package:ironsight_ai/domain/repositories/local_inspection_repository.dart';
import 'package:ironsight_ai/features/inspection/presentation/guided_quick_appraisal_entry_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_draft_routing.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_list_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_review_screen.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_workspace_screen.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_equipment_id_capture.dart';
import 'support/fake_equipment_repository.dart';
import 'support/in_memory_inspection_media_file_store.dart';

void main() {
  File buildV4LegacyDatabase() {
    final file = File(
      '${Directory.systemTemp.path}/legacy_compat_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final raw = sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE inspections (
        id TEXT NOT NULL PRIMARY KEY,
        company_id TEXT NOT NULL,
        equipment_id TEXT NOT NULL,
        created_by_user_id TEXT NOT NULL,
        updated_by_user_id TEXT NULL,
        completion_status TEXT NOT NULL,
        local_lifecycle TEXT NOT NULL,
        depth TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        report_status TEXT NOT NULL,
        remote_id TEXT NULL,
        overall_notes TEXT NULL,
        serial_number TEXT NULL,
        serial_capture_method TEXT NULL,
        hour_meter_reading REAL NULL,
        hour_meter_capture_method TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        local_updated_at INTEGER NOT NULL,
        completed_at INTEGER NULL,
        discarded_at INTEGER NULL
      );
      CREATE TABLE inspection_category_ratings (
        id TEXT NOT NULL PRIMARY KEY,
        inspection_id TEXT NOT NULL,
        company_id TEXT NOT NULL,
        category TEXT NOT NULL,
        rating TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      );
      CREATE TABLE inspection_detailed_responses (
        id TEXT NOT NULL PRIMARY KEY,
        inspection_id TEXT NOT NULL,
        company_id TEXT NOT NULL,
        category TEXT NOT NULL,
        item_key TEXT NOT NULL,
        label_snapshot TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        rating TEXT NOT NULL,
        notes TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
      CREATE TABLE local_equipment_cache (
        id TEXT NOT NULL PRIMARY KEY,
        company_id TEXT NOT NULL,
        asset_name TEXT NOT NULL,
        manufacturer TEXT NOT NULL,
        model TEXT NOT NULL,
        serial_number TEXT NULL,
        year INTEGER NULL,
        hours REAL NULL,
        location TEXT NULL,
        notes TEXT NULL,
        created_by TEXT NULL,
        created_by_name TEXT NULL,
        updated_by TEXT NULL,
        updated_by_name TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        cached_at INTEGER NOT NULL
      );
      CREATE TABLE inspection_media (
        id TEXT NOT NULL PRIMARY KEY,
        company_id TEXT NOT NULL,
        inspection_id TEXT NOT NULL,
        slot TEXT NOT NULL,
        local_relative_path TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        byte_size INTEGER NOT NULL,
        captured_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        local_updated_at INTEGER NOT NULL
      );
    ''');
    raw.execute(
      "INSERT INTO local_equipment_cache ("
      "id, company_id, asset_name, manufacturer, model, serial_number, "
      "created_at, updated_at, cached_at"
      ") VALUES ("
      "'eq-1', 'company-a', 'Legacy Excavator', 'Caterpillar', '320', 'LEG-SN', "
      "0, 0, 0"
      ")",
    );
    raw.execute(
      "INSERT INTO inspections ("
      "id, company_id, equipment_id, created_by_user_id, updated_by_user_id, "
      "completion_status, local_lifecycle, depth, sync_status, report_status, "
      "overall_notes, serial_number, serial_capture_method, hour_meter_reading, "
      "hour_meter_capture_method, created_at, updated_at, local_updated_at"
      ") VALUES ("
      "'legacy-1', 'company-a', 'eq-1', 'user-1', 'user-1', "
      "'in_progress', 'active', 'quick_appraisal', 'local_only', 'not_generated', "
      "'legacy notes', 'LEG-SN', 'manual', 1200.0, 'manual', 0, 0, 0"
      ")",
    );
    for (final entry in [
      ('engine', 'good'),
      ('hydraulics', 'fair'),
      ('undercarriage', 'not_assessed'),
      ('cab', 'good'),
      ('structure', 'fair'),
      ('attachments', 'poor'),
      ('cosmetic', 'not_assessed'),
    ]) {
      raw.execute(
        "INSERT INTO inspection_category_ratings ("
        "id, inspection_id, company_id, category, rating, updated_at"
        ") VALUES ("
        "'r-${entry.$1}', 'legacy-1', 'company-a', '${entry.$1}', '${entry.$2}', 0"
        ")",
      );
    }
    raw.execute(
      "INSERT INTO inspection_media ("
      "id, company_id, inspection_id, slot, local_relative_path, mime_type, "
      "byte_size, captured_at, updated_at, local_updated_at"
      ") VALUES ("
      "'m1', 'company-a', 'legacy-1', 'front_left_overview', "
      "'inspection_media/legacy.jpg', 'image/jpeg', 12, 0, 0, 0"
      ")",
    );
    raw.execute('PRAGMA user_version = 4;');
    raw.close();
    return file;
  }

  test('v4 legacy draft survives v5 and completes under prior rules', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });

    final file = buildV4LegacyDatabase();
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final workspace = OfflineInspectionWorkspace.fromDatabase(
      database: db,
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );

    final legacy = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: 'legacy-1',
    );
    expect(legacy, isNotNull);
    expect(legacy!.isLegacyDraft, isTrue);
    expect(legacy.machineSource, isNull);
    expect(legacy.equipmentId, 'eq-1');
    expect(legacy.overallNotes, 'legacy notes');
    expect(legacy.serialNumber, 'LEG-SN');
    expect(legacy.hourMeterReading, 1200);
    expect(legacy.ratingFor(ScorecardCategory.engine), ConditionRating.good);

    final media = await workspace.inspectionMedia.listForInspection(
      companyId: 'company-a',
      inspectionId: 'legacy-1',
    );
    expect(media, isNotEmpty);

    final completeness = evaluateGuidedQuickAppraisalCompleteness(
      inspection: legacy,
      media: const [],
    );
    expect(completeness.isComplete, isTrue);

    expect(
      incompleteInspectionRoute(legacy),
      AppRoutes.inspectionWorkspace(legacy.id),
    );

    final completed = await workspace.inspections.complete(
      companyId: 'company-a',
      inspectionId: legacy.id,
      updatedByUserId: 'user-1',
    );
    expect(completed.completionStatus, InspectionCompletionStatus.completed);
    expect(completed.equipmentId, 'eq-1');
    expect(completed.machineSource, isNull);
    expect(completed.overallNotes, 'legacy notes');
    expect(completed.serialNumber, 'LEG-SN');
  });

  test('new guided draft still cannot complete while incomplete', () async {
    final workspace = OfflineInspectionWorkspace.fromDatabase(
      database: openMemoryAppDatabase(),
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );
    addTearDown(workspace.dispose);

    final draft = await workspace.inspections.createGuidedDraft(
      companyId: 'company-a',
      createdByUserId: 'user-1',
      machineSource: InspectionMachineSource.newMachine,
    );
    expect(draft.isGuidedDraft, isTrue);
    expect(
      incompleteInspectionRoute(draft),
      AppRoutes.guidedQuickAppraisal(draft.id),
    );
    expect(
      () => workspace.inspections.completeGuidedNewMachine(
        companyId: 'company-a',
        inspectionId: draft.id,
      ),
      throwsA(isA<GuidedQuickAppraisalIncompleteException>()),
    );
  });

  testWidgets('list opens legacy drafts in the workspace route', (
    tester,
  ) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });

    final file = buildV4LegacyDatabase();
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final workspace = OfflineInspectionWorkspace.fromDatabase(
      database: db,
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );

    String? pushedRoute;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          pushedRoute = settings.name;
          if (settings.name == AppRoutes.inspectionWorkspace('legacy-1')) {
            return MaterialPageRoute<bool?>(
              settings: settings,
              builder: (_) => InspectionWorkspaceScreen(
                companyId: 'company-a',
                userId: 'user-1',
                inspectionId: 'legacy-1',
                inspections: workspace.inspections,
                equipmentCatalog: workspace.equipmentCatalog,
                inspectionMedia: workspace.inspectionMedia,
                captureControllerFactory: ({required kind, initialConfirmed}) {
                  return EquipmentIdCaptureController(
                    kind: kind,
                    imageCapture: FakeImageCapture(isSupported: false),
                    textRecognition: FakeTextRecognition(isSupported: false),
                    cameraPermission: FakeCameraPermission(),
                    initialConfirmed: initialConfirmed,
                  );
                },
              ),
            );
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
        home: InspectionListScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspections: workspace.inspections,
          equipmentCatalog: workspace.equipmentCatalog,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Legacy Excavator'));
    await tester.pumpAndSettle();
    expect(pushedRoute, AppRoutes.inspectionWorkspace('legacy-1'));
    expect(find.byType(InspectionWorkspaceScreen), findsOneWidget);
  });

  testWidgets('entry resume opens legacy drafts in the workspace route', (
    tester,
  ) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });

    final file = buildV4LegacyDatabase();
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final workspace = OfflineInspectionWorkspace.fromDatabase(
      database: db,
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );

    String? pushedRoute;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          pushedRoute = settings.name;
          if (settings.name == AppRoutes.inspectionWorkspace('legacy-1')) {
            return MaterialPageRoute<bool?>(
              settings: settings,
              builder: (_) =>
                  const Scaffold(body: Text('legacy workspace opened')),
            );
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
        home: GuidedQuickAppraisalEntryScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspections: workspace.inspections,
          equipmentCatalog: workspace.equipmentCatalog,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Legacy draft'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Legacy Excavator').last);
    await tester.pumpAndSettle();
    expect(pushedRoute, AppRoutes.inspectionWorkspace('legacy-1'));
    expect(find.text('legacy workspace opened'), findsOneWidget);
  });

  testWidgets('legacy review can Complete Anyway without guided photo gate', (
    tester,
  ) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });

    final file = buildV4LegacyDatabase();
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final workspace = OfflineInspectionWorkspace.fromDatabase(
      database: db,
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );

    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: InspectionReviewScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspectionId: 'legacy-1',
          inspections: workspace.inspections,
          equipmentCatalog: workspace.equipmentCatalog,
          inspectionMedia: workspace.inspectionMedia,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete locally'));
    await tester.pumpAndSettle();
    expect(find.text('Complete Anyway'), findsOneWidget);
    await tester.tap(find.text('Complete Anyway'));
    await tester.pumpAndSettle();
    expect(find.text('Inspection completed locally'), findsOneWidget);

    final completed = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: 'legacy-1',
    );
    expect(completed!.completionStatus, InspectionCompletionStatus.completed);
    expect(completed.machineSource, isNull);
  });
}
