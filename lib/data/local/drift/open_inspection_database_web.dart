import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

import 'app_database.dart';

/// Opens a browser-local inspections database for Brave / Flutter web founder QA.
///
/// SQLCipher is intentionally not applied here so mobile encryption remains
/// undiluted. Persistence uses IndexedDB via sqlite3's virtual filesystem.
Future<AppDatabase> openEncryptedInspectionDatabase({
  String fileName = 'ironsight_inspections.sqlite',
  bool requireCipher = true,
}) async {
  // requireCipher is ignored on web — cipher is mobile/desktop-only.
  final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final fileSystem = await IndexedDbFileSystem.open(
    dbName: 'ironsight_inspections',
  );
  sqlite3.registerVirtualFileSystem(fileSystem, makeDefault: true);

  return AppDatabase(
    WasmDatabase(
      sqlite3: sqlite3,
      path: '/$fileName',
      // ignore: avoid_redundant_argument_values
      setup: null,
    ),
  );
}
