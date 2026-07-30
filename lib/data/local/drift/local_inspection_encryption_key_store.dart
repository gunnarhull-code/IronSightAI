import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// OS-backed (or test) storage for the local SQLCipher encryption key.
///
/// Production IO platforms must use [SecureStorageLocalInspectionEncryptionKeyStore].
/// Never persist the key beside the database file.
abstract class LocalInspectionEncryptionKeyStore {
  Future<String?> readKey();

  Future<void> writeKey(String key);
}

/// Stable storage entry for the local inspections database encryption key.
const String kLocalInspectionEncryptionKeyStorageKey =
    'ironsight_local_inspection_db_encryption_key';

/// [flutter_secure_storage] implementation (Keychain / Keystore / Credential
/// Manager / libsecret).
class SecureStorageLocalInspectionEncryptionKeyStore
    implements LocalInspectionEncryptionKeyStore {
  SecureStorageLocalInspectionEncryptionKeyStore({
    FlutterSecureStorage? storage,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
             mOptions: MacOsOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readKey() async {
    try {
      final value = await _storage.read(
        key: kLocalInspectionEncryptionKeyStorageKey,
      );
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } on Object catch (error) {
      throw StateError(
        'Failed to read the local inspection encryption key from OS secure '
        'storage. Offline encrypted database access cannot continue. ($error)',
      );
    }
  }

  @override
  Future<void> writeKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        key,
        'key',
        'Local inspection encryption key must be non-empty.',
      );
    }
    try {
      await _storage.write(
        key: kLocalInspectionEncryptionKeyStorageKey,
        value: trimmed,
      );
    } on Object catch (error) {
      throw StateError(
        'Failed to persist the local inspection encryption key in OS secure '
        'storage. The key was not written to disk beside the database. '
        '($error)',
      );
    }
  }
}
