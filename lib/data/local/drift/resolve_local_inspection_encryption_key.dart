import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'local_inspection_encryption_key_store.dart';

/// Legacy plaintext companion filename (pre-secure-storage). Migrated once.
const String kLegacyLocalInspectionEncryptionKeyFileName =
    'ironsight_inspections.key';

/// Resolves the SQLCipher key from secure storage, migrating a legacy
/// plaintext companion file when present, otherwise generating a new key.
///
/// Never writes the key beside the database. Secure-storage failures surface
/// as [StateError] and do not fall back to plaintext persistence.
Future<String> resolveLocalInspectionEncryptionKey({
  required LocalInspectionEncryptionKeyStore keyStore,
  required Directory documentsDirectory,
  String Function()? generateKey,
}) async {
  final existing = await keyStore.readKey();
  if (existing != null && existing.isNotEmpty) {
    return existing;
  }

  final legacyFile = File(
    p.join(
      documentsDirectory.path,
      kLegacyLocalInspectionEncryptionKeyFileName,
    ),
  );
  if (await legacyFile.exists()) {
    final legacy = (await legacyFile.readAsString()).trim();
    if (legacy.isNotEmpty) {
      // Persist to secure storage first; only then delete the plaintext file.
      await keyStore.writeKey(legacy);
      await legacyFile.delete();
      return legacy;
    }
    await legacyFile.delete();
  }

  final generated = (generateKey ?? _defaultGenerateKey)().trim();
  if (generated.isEmpty) {
    throw StateError(
      'Generated local inspection encryption key must be non-empty.',
    );
  }
  await keyStore.writeKey(generated);
  return generated;
}

String _defaultGenerateKey() => const Uuid().v4();
