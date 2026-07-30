import 'package:ironsight_ai/data/local/drift/local_inspection_encryption_key_store.dart';

/// In-memory key store for unit tests.
class FakeLocalInspectionEncryptionKeyStore
    implements LocalInspectionEncryptionKeyStore {
  FakeLocalInspectionEncryptionKeyStore({
    this.initialKey,
    this.readError,
    this.writeError,
  });

  String? initialKey;
  Object? readError;
  Object? writeError;
  int readCount = 0;
  int writeCount = 0;
  final List<String> writtenKeys = <String>[];

  @override
  Future<String?> readKey() async {
    readCount += 1;
    final error = readError;
    if (error != null) {
      // Match production store: surface secure-storage failures as StateError.
      throw StateError(
        'Failed to read the local inspection encryption key from OS secure '
        'storage. Offline encrypted database access cannot continue. ($error)',
      );
    }
    final value = initialKey?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  @override
  Future<void> writeKey(String key) async {
    writeCount += 1;
    final error = writeError;
    if (error != null) {
      throw StateError(
        'Failed to persist the local inspection encryption key in OS secure '
        'storage. The key was not written to disk beside the database. '
        '($error)',
      );
    }
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        key,
        'key',
        'Local inspection encryption key must be non-empty.',
      );
    }
    writtenKeys.add(trimmed);
    initialKey = trimmed;
  }
}
