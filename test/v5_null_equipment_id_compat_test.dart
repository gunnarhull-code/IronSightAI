import 'dart:io';

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/app_database.dart';
import 'package:ironsight_ai/data/repositories/drift_local_equipment_catalog_repository.dart';
import 'package:ironsight_ai/data/repositories/drift_local_inspection_repository.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/use_cases/find_active_drafts_for_equipment.dart';
import 'package:sqlite3/sqlite3.dart';

/// Samsung S22 / interim guided-build compatibility: a physical v5-style DB may
/// contain guided drafts with `equipment_id IS NULL`. Legacy Quick Appraisal
/// must not map those rows through the non-null Drift mapper.
void main() {
  test(
    'v5-style DB with null equipment_id guided row still lists linked drafts',
    () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(() {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      });

      final file = File(
        '${Directory.systemTemp.path}/ironsight_v5_compat_'
        '${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final raw = sqlite3.open(file.path);
      // Physical schema shaped like interim guided PR #26 (nullable
      // equipment_id + guided columns). user_version=5 matches that build.
      raw.execute('''
        CREATE TABLE inspections (
          id TEXT NOT NULL PRIMARY KEY,
          company_id TEXT NOT NULL,
          equipment_id TEXT,
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
      ''');
      raw.execute('''
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
      ''');
      raw.execute('''
        CREATE TABLE inspection_category_ratings (
          id TEXT NOT NULL PRIMARY KEY,
          inspection_id TEXT NOT NULL,
          company_id TEXT NOT NULL,
          category TEXT NOT NULL,
          rating TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      raw.execute('''
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
      ''');
      raw.execute('''
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
      raw.execute('''
        CREATE TABLE local_tenant_contexts (
          id TEXT NOT NULL PRIMARY KEY,
          company_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          activated_at INTEGER NOT NULL
        );
      ''');

      const ts = 1700000000000;
      raw.execute(
        '''
        INSERT INTO local_equipment_cache (
          id, company_id, asset_name, manufacturer, model,
          created_at, updated_at, cached_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          'eq-linked',
          'company-a',
          'Linked Excavator',
          'Caterpillar',
          '320',
          ts,
          ts,
          ts,
        ],
      );
      raw.execute(
        '''
        INSERT INTO inspections (
          id, company_id, equipment_id, created_by_user_id,
          completion_status, local_lifecycle, depth, sync_status, report_status,
          machine_source, pending_asset_name, guided_step,
          created_at, updated_at, local_updated_at
        ) VALUES (
          'draft-guided', 'company-a', NULL, 'user-1',
          'in_progress', 'active', 'quick_appraisal', 'local_only', 'not_generated',
          'new_machine', 'Pending Machine', 'identity',
          ?, ?, ?
        );
        ''',
        [ts, ts, ts],
      );
      raw.execute(
        '''
        INSERT INTO inspections (
          id, company_id, equipment_id, created_by_user_id,
          completion_status, local_lifecycle, depth, sync_status, report_status,
          created_at, updated_at, local_updated_at
        ) VALUES (
          'draft-linked', 'company-a', 'eq-linked', 'user-1',
          'in_progress', 'active', 'quick_appraisal', 'local_only', 'not_generated',
          ?, ?, ?
        );
        ''',
        [ts + 1, ts + 1, ts + 1],
      );
      raw.execute('PRAGMA user_version = 5;');
      raw.close();

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final inspections = DriftLocalInspectionRepository(db);
      final catalog = DriftLocalEquipmentCatalogRepository(db);

      final listed = await inspections.listForCompany('company-a');
      expect(listed, hasLength(1));
      expect(listed.single.id, 'draft-linked');
      expect(listed.single.equipmentId, 'eq-linked');

      final drafts = await FindActiveDraftsForEquipment(inspections)(
        companyId: 'company-a',
        equipmentId: 'eq-linked',
      );
      expect(drafts, hasLength(1));
      expect(drafts.single.id, 'draft-linked');

      final cached = await catalog.getById(
        companyId: 'company-a',
        equipmentId: 'eq-linked',
      );
      expect(cached, isNotNull);

      // Guided row remains intact for a future guided build — never deleted.
      final rawCounts = await db
          .customSelect(
            'SELECT '
            'SUM(CASE WHEN equipment_id IS NULL THEN 1 ELSE 0 END) AS guided_nulls, '
            'SUM(CASE WHEN equipment_id IS NOT NULL THEN 1 ELSE 0 END) AS linked, '
            'COUNT(*) AS total '
            'FROM inspections WHERE company_id = ?',
            variables: [Variable.withString('company-a')],
          )
          .getSingle();
      expect(rawCounts.data['guided_nulls'], 1);
      expect(rawCounts.data['linked'], 1);
      expect(rawCounts.data['total'], 2);

      // Opening the guided id via legacy getById must not map/crash — null.
      expect(
        await inspections.getById(
          companyId: 'company-a',
          inspectionId: 'draft-guided',
        ),
        isNull,
      );

      // Starting another linked draft still works beside the preserved guided row.
      final created = await inspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'eq-linked',
        createdByUserId: 'user-1',
      );
      expect(created.equipmentId, 'eq-linked');
      expect(created.completionStatus, InspectionCompletionStatus.inProgress);

      final stillGuided = await db
          .customSelect(
            'SELECT id FROM inspections '
            'WHERE id = ? AND equipment_id IS NULL',
            variables: [Variable.withString('draft-guided')],
          )
          .get();
      expect(stillGuided, hasLength(1));
    },
  );
}
