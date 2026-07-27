import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

const String kLocalInspectionDatabaseFileName = 'ironsight_inspections.sqlite';
const String kLocalInspectionEncryptionKeyFileName =
    'ironsight_inspections.key';

/// In-memory database for deterministic automated tests (VM / mobile IO).
AppDatabase openMemoryAppDatabase({String? encryptionKey}) {
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
AppDatabase openFileAppDatabase(
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

/// Opens the on-device encrypted inspections database in the app documents dir.
///
/// SQLCipher-compatible encryption is required on IO platforms. The key is
/// stored beside the database in a companion file until a dedicated secure
/// storage sprint lands.
Future<AppDatabase> openEncryptedInspectionDatabase({
  String fileName = kLocalInspectionDatabaseFileName,
  bool requireCipher = true,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, fileName));
  final encryptionKey = await _resolveEncryptionKey(directory);
  return openFileAppDatabase(
    file,
    encryptionKey: encryptionKey,
    requireCipher: requireCipher,
  );
}

Future<String> _resolveEncryptionKey(Directory directory) async {
  final keyFile = File(
    p.join(directory.path, kLocalInspectionEncryptionKeyFileName),
  );
  if (await keyFile.exists()) {
    final existing = (await keyFile.readAsString()).trim();
    if (existing.isNotEmpty) return existing;
  }
  final generated = const Uuid().v4();
  await keyFile.writeAsString(generated, flush: true);
  return generated;
}
