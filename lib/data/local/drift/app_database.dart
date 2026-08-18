import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import '../../../domain/exceptions/local_database_schema_exception.dart';
import 'local_guided_schema_probe.dart';
import 'tables/inspection_category_ratings_table.dart';
import 'tables/inspection_detailed_responses_table.dart';
import 'tables/inspection_media_table.dart';
import 'tables/inspections_table.dart';
import 'tables/local_equipment_cache_table.dart';
import 'tables/local_tenant_contexts_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Inspections,
    InspectionCategoryRatings,
    InspectionDetailedResponses,
    InspectionMediaItems,
    LocalTenantContexts,
    LocalEquipmentCache,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await migrator.createAll();
        await _createIndexes();
      },
      onUpgrade: (Migrator migrator, int from, int to) async {
        if (from < 2) {
          await migrator.createTable(localTenantContexts);
          await migrator.createTable(localEquipmentCache);
          await _createIndexes();
        }
        if (from < 3) {
          await migrator.addColumn(inspections, inspections.serialNumber);
          await migrator.addColumn(
            inspections,
            inspections.serialCaptureMethod,
          );
          await migrator.addColumn(inspections, inspections.hourMeterReading);
          await migrator.addColumn(
            inspections,
            inspections.hourMeterCaptureMethod,
          );
        }
        if (from < 4) {
          await migrator.createTable(inspectionMediaItems);
          await _createMediaIndexes();
        }
        if (from < 5) {
          // A device that already ran a guided build carries the v5 shape even
          // when its version stamp regressed to 4. Inspect the physical schema
          // before touching it: rerunning the rebuild would drop guided values
          // and re-adding catalog_origin fails outright.
          final probe = await probeGuidedSchema();
          switch (probe.state) {
            case LocalGuidedSchemaState.applied:
              // Every row stays as it is; Drift repairs the stamp on its own.
              break;
            case LocalGuidedSchemaState.notApplied:
              await _applyGuidedSchema(migrator);
            case LocalGuidedSchemaState.indeterminate:
              throw LocalDatabaseSchemaException(
                'Local inspection schema is neither the expected pre-guided '
                'shape nor a fully applied guided shape, so it was left '
                'untouched instead of being rebuilt.',
                details: probe.details,
              );
          }
        }
      },
    );
  }

  /// Reads the physical schema shape of this file without modifying it.
  Future<LocalGuidedSchemaProbe> probeGuidedSchema() async {
    final inspectionColumns = await _columnsOf('inspections');
    final equipmentColumns = await _columnsOf('local_equipment_cache');
    return classifyGuidedSchema(
      inspectionColumnsNotNull: inspectionColumns,
      hasEquipmentCacheTable: await _hasTable('local_equipment_cache'),
      equipmentCacheColumns: equipmentColumns.keys.toSet(),
    );
  }

  /// Maps each column of [table] to its NOT NULL flag; empty when absent.
  Future<Map<String, bool>> _columnsOf(String table) async {
    final rows = await customSelect("PRAGMA table_info('$table')").get();
    return {
      for (final row in rows)
        row.data['name'] as String: (row.data['notnull'] as int? ?? 0) != 0,
    };
  }

  Future<bool> _hasTable(String table) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(table)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Applies the guided (v5) shape to a clean pre-guided database.
  Future<void> _applyGuidedSchema(Migrator migrator) async {
    // SQLite cannot ALTER a NOT NULL column to nullable; rebuild.
    await migrator.alterTable(
      TableMigration(
        inspections,
        newColumns: [
          inspections.machineSource,
          inspections.pendingAssetName,
          inspections.pendingManufacturer,
          inspections.pendingModel,
          inspections.guidedStep,
          inspections.pendingEquipmentId,
        ],
      ),
    );
    if (await _hasTable('local_equipment_cache')) {
      await migrator.addColumn(
        localEquipmentCache,
        localEquipmentCache.catalogOrigin,
      );
    } else {
      await migrator.createTable(localEquipmentCache);
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_local_equipment_company '
        'ON local_equipment_cache (company_id)',
      );
    }
  }

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inspections_company '
      'ON inspections (company_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inspections_company_lifecycle '
      'ON inspections (company_id, local_lifecycle)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_ratings_inspection '
      'ON inspection_category_ratings (inspection_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_detailed_responses_inspection '
      'ON inspection_detailed_responses (inspection_id, category)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_equipment_company '
      'ON local_equipment_cache (company_id)',
    );
    await _createMediaIndexes();
  }

  Future<void> _createMediaIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inspection_media_company_inspection '
      'ON inspection_media (company_id, inspection_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_inspection_media_company_inspection_slot '
      'ON inspection_media (company_id, inspection_id, slot)',
    );
  }
}

/// Configures SQLite3MultipleCiphers / SQLCipher-compatible encryption.
///
/// Production mobile/desktop openers must pass [encryptionKey]. When
/// [requireCipher] is true, opening fails if the linked SQLite build does not
/// expose cipher support. Web founder-QA openers may skip cipher entirely.
void configureLocalDatabaseEncryption(
  CommonDatabase database, {
  String? encryptionKey,
  bool requireCipher = false,
}) {
  if (encryptionKey == null) {
    if (requireCipher) {
      throw StateError(
        'Encrypted local database open requires an encryption key.',
      );
    }
    return;
  }

  final hasCipher = _hasCipher(database);
  if (requireCipher && !hasCipher) {
    throw StateError(
      'SQLCipher-compatible encryption is required but the linked SQLite '
      'build does not expose PRAGMA cipher. Ensure sqlite3 hooks use '
      'source: sqlite3mc.',
    );
  }

  if (hasCipher) {
    database.execute("PRAGMA cipher = 'sqlcipher'");
    database.execute('PRAGMA legacy = 4');
  }

  database.execute("PRAGMA key = '${_escapeSqlString(encryptionKey)}'");
}

bool _hasCipher(CommonDatabase database) {
  try {
    return database.select('PRAGMA cipher;').isNotEmpty;
  } on Object {
    return false;
  }
}

String _escapeSqlString(String value) => value.replaceAll("'", "''");
