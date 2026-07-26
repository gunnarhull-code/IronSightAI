import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database;

import 'tables/inspection_category_ratings_table.dart';
import 'tables/inspection_detailed_responses_table.dart';
import 'tables/inspections_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Inspections, InspectionCategoryRatings, InspectionDetailedResponses],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// In-memory database for deterministic automated tests.
  factory AppDatabase.memory({String? encryptionKey}) {
    return AppDatabase(
      NativeDatabase.memory(
        setup: (database) => configureLocalDatabaseEncryption(
          database,
          encryptionKey: encryptionKey,
        ),
      ),
    );
  }

  /// File-backed database with encryption key applied at open time.
  factory AppDatabase.file(
    File file, {
    required String encryptionKey,
    bool requireCipher = true,
  }) {
    return AppDatabase(
      NativeDatabase(
        file,
        setup: (database) => configureLocalDatabaseEncryption(
          database,
          encryptionKey: encryptionKey,
          requireCipher: requireCipher,
        ),
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await migrator.createAll();
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
      },
    );
  }
}

/// Configures SQLite3MultipleCiphers / SQLCipher-compatible encryption.
///
/// Production openers must pass [encryptionKey]. When [requireCipher] is true,
/// opening fails if the linked SQLite build does not expose cipher support.
void configureLocalDatabaseEncryption(
  Database database, {
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

bool _hasCipher(Database database) {
  try {
    return database.select('PRAGMA cipher;').isNotEmpty;
  } on Object {
    return false;
  }
}

String _escapeSqlString(String value) => value.replaceAll("'", "''");
