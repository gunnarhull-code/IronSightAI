import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'local_inspection_encryption_key_store.dart';

/// Legacy plaintext companion filename (pre-secure-storage). Migrated once.
const String kLegacyLocalInspectionEncryptionKeyFileName =
    'ironsight_inspections.key';

/// Resolves the SQLCipher key from secure storage, migrating a legacy
/// plaintext companion file when present, otherwise generating a new key.
///
/// Never writes the key beside the database. Secure-storage failures surface
/// as [StateError] and do not fall back to plaintext persistence.
///
/// [deleteLegacyFile] is injectable for tests that simulate deletion failures.
Future<String> resolveLocalInspectionEncryptionKey({
  required LocalInspectionEncryptionKeyStore keyStore,
  required Directory documentsDirectory,
  String Function()? generateKey,
  Future<void> Function(File file)? deleteLegacyFile,
}) async {
  final legacyFile = File(
    p.join(
      documentsDirectory.path,
      kLegacyLocalInspectionEncryptionKeyFileName,
    ),
  );
  Future<void> deleteFile(File file) async {
    if (deleteLegacyFile != null) {
      await deleteLegacyFile(file);
    } else {
      await file.delete();
    }
  }

  final existing = await keyStore.readKey();
  if (existing != null && existing.isNotEmpty) {
    await _reconcileLegacyKeyFile(
      legacyFile: legacyFile,
      secureKey: existing,
      deleteFile: deleteFile,
    );
    return existing;
  }

  if (await legacyFile.exists()) {
    final legacy = (await legacyFile.readAsString()).trim();
    if (legacy.isNotEmpty) {
      // Persist to secure storage first; only then attempt plaintext deletion.
      await keyStore.writeKey(legacy);
      await _deleteLegacyBestEffort(legacyFile, deleteFile);
      return legacy;
    }
    await _deleteLegacyBestEffort(legacyFile, deleteFile);
  }

  final generated = (generateKey ?? generateLocalInspectionEncryptionKey)()
      .trim();
  if (generated.isEmpty) {
    throw StateError(
      'Generated local inspection encryption key must be non-empty.',
    );
  }
  await keyStore.writeKey(generated);
  return generated;
}

/// 32 cryptographically random bytes, hex-encoded (64 chars).
///
/// Hex avoids SQL-string escaping edge cases when applied via PRAGMA key.
String generateLocalInspectionEncryptionKey({Random? random}) {
  final source = random ?? Random.secure();
  final bytes = Uint8List(32);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = source.nextInt(256);
  }
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

Future<void> _reconcileLegacyKeyFile({
  required File legacyFile,
  required String secureKey,
  required Future<void> Function(File file) deleteFile,
}) async {
  if (!await legacyFile.exists()) return;

  final legacy = (await legacyFile.readAsString()).trim();
  if (legacy.isEmpty) {
    await _deleteLegacyBestEffort(legacyFile, deleteFile);
    return;
  }

  if (legacy == secureKey) {
    // Matching leftover from a prior interrupted cleanup — retry deletion.
    await _deleteLegacyBestEffort(legacyFile, deleteFile);
    return;
  }

  throw StateError(
    'Legacy plaintext inspection encryption key conflicts with the key in OS '
    'secure storage. The legacy file was preserved for recovery; the encrypted '
    'database will not open until this conflict is resolved manually.',
  );
}

/// Deletes the legacy file when possible. Deletion failures are swallowed so
/// the secure key remains usable and cleanup can retry on the next open.
Future<void> _deleteLegacyBestEffort(
  File legacyFile,
  Future<void> Function(File file) deleteFile,
) async {
  try {
    if (await legacyFile.exists()) {
      await deleteFile(legacyFile);
    }
  } on Object {
    // Leave the file in place for the next invocation.
  }
}
