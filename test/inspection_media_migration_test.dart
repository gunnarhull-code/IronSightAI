import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('schema v3 to v4 creates inspection_media table safely', () async {
    final file = File(
      '${Directory.systemTemp.path}/ironsight_media_mig_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    // Simulate a pre-v4 database with inspections only (no media table).
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
    ''');
    raw.execute('PRAGMA user_version = 3;');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    // Opening triggers onUpgrade < 4.
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'inspection_media'",
        )
        .get();
    expect(tables, hasLength(1));

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], 4);

    await db.customStatement(
      "INSERT INTO inspection_media ("
      "id, company_id, inspection_id, slot, local_relative_path, mime_type, "
      "byte_size, captured_at, updated_at, local_updated_at"
      ") VALUES ("
      "'m1', 'c1', 'i1', 'front_left_overview', 'inspection_media/x.jpg', "
      "'image/jpeg', 3, 0, 0, 0"
      ")",
    );
    final rows = await db.select(db.inspectionMediaItems).get();
    expect(rows, hasLength(1));
    expect(rows.single.slot, 'front_left_overview');
  });
}
