import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/app_database.dart';
import 'package:ironsight_ai/data/local/drift/local_guided_schema_probe.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/entities/inspection_machine_source.dart';
import 'package:ironsight_ai/domain/exceptions/local_database_schema_exception.dart';
import 'package:ironsight_ai/features/company/presentation/company_gate.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/fake_auth_session_reader.dart';
import 'support/fake_company_repository.dart';
import 'support/fake_equipment_repository.dart';

import 'package:flutter/material.dart';
import 'package:ironsight_ai/domain/entities/company.dart';

/// Samsung S22 merge-blocker: the device ran the guided v5 schema, then older
/// v4-based builds that stamped `user_version` back down to 4. Reopening with
/// this build then reran the v5 migration over an already-migrated file.
void main() {
  const legacyDraftId = 'draft-legacy';
  const guidedDraftId = 'draft-guided-null-equipment';

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDown(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  File newDatabaseFile(String label) {
    final file = File(
      '${Directory.systemTemp.path}/ironsight_${label}_'
      '${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    return file;
  }

  /// Pre-guided (v4) file with one legacy equipment-linked draft.
  File buildV4Database({int stamp = 4}) {
    final file = newDatabaseFile('v4');
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
      CREATE TABLE local_tenant_contexts (
        id TEXT NOT NULL PRIMARY KEY,
        company_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        activated_at INTEGER NOT NULL
      );
    ''');
    raw.execute(
      "INSERT INTO local_equipment_cache (id, company_id, asset_name, "
      "manufacturer, model, created_at, updated_at, cached_at) VALUES "
      "('eq-1','company-a','Legacy Excavator','Caterpillar','320',0,0,0)",
    );
    raw.execute(
      "INSERT INTO inspections (id, company_id, equipment_id, "
      "created_by_user_id, completion_status, local_lifecycle, depth, "
      "sync_status, report_status, overall_notes, "
      "created_at, updated_at, local_updated_at) VALUES "
      "('$legacyDraftId','company-a','eq-1','user-1','in_progress','active',"
      "'quick_appraisal','local_only','not_generated','Legacy notes',0,0,0)",
    );
    raw.execute('PRAGMA user_version = $stamp;');
    raw.close();
    return file;
  }

  /// Fully applied guided (v5) file: nullable equipment_id, guided columns,
  /// `catalog_origin`, one legacy draft and one guided null-equipment draft.
  File buildV5Database({required int stamp}) {
    final file = newDatabaseFile('v5');
    final raw = sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE inspections (
        id TEXT NOT NULL PRIMARY KEY,
        company_id TEXT NOT NULL,
        equipment_id TEXT NULL,
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
        machine_source TEXT NULL,
        pending_asset_name TEXT NULL,
        pending_manufacturer TEXT NULL,
        pending_model TEXT NULL,
        guided_step TEXT NULL,
        pending_equipment_id TEXT NULL,
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
        cached_at INTEGER NOT NULL,
        catalog_origin TEXT NOT NULL DEFAULT 'remote_cache'
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
      CREATE TABLE local_tenant_contexts (
        id TEXT NOT NULL PRIMARY KEY,
        company_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        activated_at INTEGER NOT NULL
      );
    ''');
    raw.execute(
      "INSERT INTO local_equipment_cache (id, company_id, asset_name, "
      "manufacturer, model, created_at, updated_at, cached_at, catalog_origin) "
      "VALUES ('eq-1','company-a','Linked Excavator','Caterpillar','320',"
      "0,0,0,'local_created')",
    );
    raw.execute(
      "INSERT INTO inspections (id, company_id, equipment_id, "
      "created_by_user_id, completion_status, local_lifecycle, depth, "
      "sync_status, report_status, overall_notes, "
      "created_at, updated_at, local_updated_at) VALUES "
      "('$legacyDraftId','company-a','eq-1','user-1','in_progress','active',"
      "'quick_appraisal','local_only','not_generated','Legacy notes',0,0,0)",
    );
    raw.execute(
      "INSERT INTO inspections (id, company_id, equipment_id, "
      "created_by_user_id, completion_status, local_lifecycle, depth, "
      "sync_status, report_status, machine_source, pending_asset_name, "
      "pending_manufacturer, pending_model, guided_step, pending_equipment_id, "
      "created_at, updated_at, local_updated_at) VALUES "
      "('$guidedDraftId','company-a',NULL,'user-1','in_progress','active',"
      "'quick_appraisal','local_only','not_generated','new_machine',"
      "'Pending Loader','Komatsu','WA320','identity','pending-eq-1',1,1,1)",
    );
    raw.execute('PRAGMA user_version = $stamp;');
    raw.close();
    return file;
  }

  Future<int> stampOf(AppDatabase db) async {
    final row = await db.customSelect('PRAGMA user_version').getSingle();
    return row.data['user_version'] as int;
  }

  group('genuine v4 database', () {
    test('applies the guided migration exactly once and keeps rows', () async {
      final file = buildV4Database();

      // Pre-state, read without opening Drift: no guided columns, stamp 4.
      final before = sqlite3.open(file.path);
      expect(
        before
            .select("PRAGMA table_info('inspections')")
            .map((row) => row['name'])
            .toSet(),
        isNot(contains('machine_source')),
      );
      expect(before.select('PRAGMA user_version').first.values.first, 4);
      before.close();

      final first = AppDatabase(NativeDatabase(file));
      final migrated = await first.select(first.inspections).get();
      expect(migrated, hasLength(1));
      expect(migrated.single.id, legacyDraftId);
      expect(migrated.single.equipmentId, 'eq-1');
      expect(migrated.single.overallNotes, 'Legacy notes');
      expect(migrated.single.machineSource, isNull);
      expect(await stampOf(first), 5);
      expect(
        (await first.probeGuidedSchema()).state,
        LocalGuidedSchemaState.applied,
      );
      await first.close();

      // Reopening must not migrate a second time.
      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);
      expect(await second.select(second.inspections).get(), hasLength(1));
      expect(await stampOf(second), 5);

      final cached = await second.select(second.localEquipmentCache).get();
      expect(cached.single.catalogOrigin, 'remote_cache');
    });
  });

  group('guided v5 database', () {
    test('normal reopen leaves schema, stamp, and rows untouched', () async {
      final file = buildV5Database(stamp: 5);

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      expect(
        (await db.probeGuidedSchema()).state,
        LocalGuidedSchemaState.applied,
      );
      final rows = await db.select(db.inspections).get();
      expect(
        rows.map((row) => row.id),
        containsAll([legacyDraftId, guidedDraftId]),
      );
      expect(await stampOf(db), 5);
    });

    test(
      'physical v5 stamped 4 repairs the stamp and preserves every row',
      () async {
        final file = buildV5Database(stamp: 4);

        final db = AppDatabase(NativeDatabase(file));
        addTearDown(db.close);

        final rows = await db.select(db.inspections).get();
        expect(rows, hasLength(2));

        final legacy = rows.firstWhere((row) => row.id == legacyDraftId);
        expect(legacy.equipmentId, 'eq-1');
        expect(legacy.overallNotes, 'Legacy notes');
        expect(legacy.machineSource, isNull);

        final guided = rows.firstWhere((row) => row.id == guidedDraftId);
        expect(guided.equipmentId, isNull);
        expect(
          guided.machineSource,
          InspectionMachineSource.newMachine.storageValue,
        );
        expect(guided.pendingAssetName, 'Pending Loader');
        expect(guided.pendingManufacturer, 'Komatsu');
        expect(guided.pendingModel, 'WA320');
        expect(guided.guidedStep, 'identity');
        expect(guided.pendingEquipmentId, 'pending-eq-1');

        // Locally created catalog rows keep their origin (no rebuild ran).
        final cached = await db.select(db.localEquipmentCache).get();
        expect(cached.single.catalogOrigin, 'local_created');

        expect(await stampOf(db), 5);
      },
    );
  });

  group('unrecognized schema', () {
    test('fails closed instead of rebuilding a partial schema', () async {
      final file = buildV4Database();
      final raw = sqlite3.open(file.path);
      // Half-applied guided shape: one guided column, equipment_id still
      // NOT NULL. Migrating this blindly would rebuild the table.
      raw.execute(
        'ALTER TABLE inspections ADD COLUMN machine_source TEXT NULL',
      );
      raw.close();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      await expectLater(
        db.select(db.inspections).get(),
        throwsA(isA<LocalDatabaseSchemaException>()),
      );

      final after = sqlite3.open(file.path);
      addTearDown(after.close);
      expect(
        after.select('SELECT COUNT(*) AS c FROM inspections').first['c'],
        1,
      );
      expect(after.select('PRAGMA user_version').first.values.first, 4);
    });
  });

  group('schema classification', () {
    test('reports applied, pre-guided, and indeterminate shapes', () {
      final guided = {for (final name in kGuidedInspectionColumns) name: false};

      expect(
        classifyGuidedSchema(
          inspectionColumnsNotNull: {'equipment_id': false, ...guided},
          hasEquipmentCacheTable: true,
          equipmentCacheColumns: {'id', 'catalog_origin'},
        ).state,
        LocalGuidedSchemaState.applied,
      );

      expect(
        classifyGuidedSchema(
          inspectionColumnsNotNull: const {'equipment_id': true},
          hasEquipmentCacheTable: true,
          equipmentCacheColumns: const {'id'},
        ).state,
        LocalGuidedSchemaState.notApplied,
      );

      expect(
        classifyGuidedSchema(
          inspectionColumnsNotNull: const {
            'equipment_id': true,
            'machine_source': false,
          },
          hasEquipmentCacheTable: true,
          equipmentCacheColumns: const {'id'},
        ).state,
        LocalGuidedSchemaState.indeterminate,
      );

      expect(
        classifyGuidedSchema(
          inspectionColumnsNotNull: const {},
          hasEquipmentCacheTable: false,
          equipmentCacheColumns: const {},
        ).state,
        LocalGuidedSchemaState.indeterminate,
      );
    });

    test('probe details carry schema metadata only', () {
      final probe = classifyGuidedSchema(
        inspectionColumnsNotNull: const {'equipment_id': true},
        hasEquipmentCacheTable: true,
        equipmentCacheColumns: const {'id'},
      );
      expect(probe.details, contains('guided columns 0/6'));
      expect(probe.details, contains('equipment_id nullable: false'));
    });
  });

  group('CompanyGate failure surface', () {
    testWidgets(
      'local database failure is not reported as a company lookup failure',
      (tester) async {
        final file = buildV4Database();
        final raw = sqlite3.open(file.path);
        raw.execute(
          'ALTER TABLE inspections ADD COLUMN machine_source TEXT NULL',
        );
        raw.close();

        final workspace = OfflineInspectionWorkspace.fromDatabase(
          database: AppDatabase(NativeDatabase(file)),
          remoteEquipmentRepository: FakeEquipmentRepository(),
          authSession: FakeAuthSessionReader(currentUserId: 'user-1'),
        );
        addTearDown(workspace.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: CompanyGate(
              repository: FakeCompanyRepository(
                company: Company(
                  id: 'company-a',
                  name: 'Hull Equipment',
                  createdAt: DateTime.utc(2026, 1, 1),
                  updatedAt: DateTime.utc(2026, 1, 1),
                ),
              ),
              workspace: workspace,
              authSession: FakeAuthSessionReader(currentUserId: 'user-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('local inspection database could not be opened'),
          findsOneWidget,
        );
        expect(find.textContaining('Nothing was deleted'), findsOneWidget);
        expect(
          find.text('Could not load your company. Please try again.'),
          findsNothing,
        );
        expect(find.text('Retry'), findsOneWidget);
      },
    );
  });
}
