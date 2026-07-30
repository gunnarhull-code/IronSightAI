import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'local_inspection_encryption_key_store.dart';
import 'resolve_local_inspection_encryption_key.dart';

const String kLocalInspectionDatabaseFileName = 'ironsight_inspections.sqlite';

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
/// resolved from OS-backed secure storage (never a plaintext companion file).
Future<AppDatabase> openEncryptedInspectionDatabase({
  String fileName = kLocalInspectionDatabaseFileName,
  bool requireCipher = true,
  LocalInspectionEncryptionKeyStore? keyStore,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, fileName));
  final encryptionKey = await resolveLocalInspectionEncryptionKey(
    keyStore: keyStore ?? SecureStorageLocalInspectionEncryptionKeyStore(),
    documentsDirectory: directory,
  );
  return openFileAppDatabase(
    file,
    encryptionKey: encryptionKey,
    requireCipher: requireCipher,
  );
}
