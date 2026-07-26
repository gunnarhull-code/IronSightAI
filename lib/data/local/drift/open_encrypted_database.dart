import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

const String kLocalInspectionDatabaseFileName = 'ironsight_inspections.sqlite';

/// Opens the on-device encrypted inspections database in the app documents dir.
///
/// The encryption key must come from secure storage / app configuration in a
/// later sprint. This helper only establishes the SQLCipher-compatible open path.
Future<AppDatabase> openEncryptedInspectionDatabase({
  required String encryptionKey,
  String fileName = kLocalInspectionDatabaseFileName,
  bool requireCipher = true,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, fileName));
  return AppDatabase.file(
    file,
    encryptionKey: encryptionKey,
    requireCipher: requireCipher,
  );
}
