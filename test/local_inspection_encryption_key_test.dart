import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/local_inspection_encryption_key_store.dart';
import 'package:ironsight_ai/data/local/drift/resolve_local_inspection_encryption_key.dart';

import 'support/fake_local_inspection_encryption_key_store.dart';

void main() {
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'ironsight_key_',
    );
  });

  tearDown(() async {
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  File legacyKeyFile() => File(
        '${documentsDirectory.path}/$kLegacyLocalInspectionEncryptionKeyFileName',
      );

  group('SecureStorageLocalInspectionEncryptionKeyStore', () {
    late Map<String, String> backend;
    late FlutterSecureStoragePlatform previousPlatform;

    setUp(() {
      backend = <String, String>{};
      previousPlatform = FlutterSecureStoragePlatform.instance;
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(backend);
    });

    tearDown(() {
      FlutterSecureStoragePlatform.instance = previousPlatform;
    });

    test('creates, reuses, and rejects empty writes', () async {
      final store = SecureStorageLocalInspectionEncryptionKeyStore(
        storage: const FlutterSecureStorage(),
      );

      expect(await store.readKey(), isNull);
      await store.writeKey('secure-key');
      expect(await store.readKey(), 'secure-key');
      expect(
        backend[kLocalInspectionEncryptionKeyStorageKey],
        'secure-key',
      );
      await expectLater(
        store.writeKey('  '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('resolveLocalInspectionEncryptionKey', () {
    test('creates and reuses a key from secure storage', () async {
      final store = FakeLocalInspectionEncryptionKeyStore();

      final first = await resolveLocalInspectionEncryptionKey(
        keyStore: store,
        documentsDirectory: documentsDirectory,
        generateKey: () => 'generated-key-one',
      );
      final second = await resolveLocalInspectionEncryptionKey(
        keyStore: store,
        documentsDirectory: documentsDirectory,
        generateKey: () => 'generated-key-two',
      );

      expect(first, 'generated-key-one');
      expect(second, 'generated-key-one');
      expect(store.writeCount, 1);
      expect(store.writtenKeys, ['generated-key-one']);
      expect(await legacyKeyFile().exists(), isFalse);
    });

    test('migrates legacy plaintext companion file into secure storage',
        () async {
      final store = FakeLocalInspectionEncryptionKeyStore();
      await legacyKeyFile().writeAsString('legacy-plaintext-key', flush: true);

      final resolved = await resolveLocalInspectionEncryptionKey(
        keyStore: store,
        documentsDirectory: documentsDirectory,
        generateKey: () => 'should-not-be-used',
      );

      expect(resolved, 'legacy-plaintext-key');
      expect(store.writtenKeys, ['legacy-plaintext-key']);
      expect(await legacyKeyFile().exists(), isFalse);

      final reused = await resolveLocalInspectionEncryptionKey(
        keyStore: store,
        documentsDirectory: documentsDirectory,
        generateKey: () => 'should-not-be-used',
      );
      expect(reused, 'legacy-plaintext-key');
      expect(store.writeCount, 1);
    });

    test('keeps legacy plaintext file when secure write fails', () async {
      final store = FakeLocalInspectionEncryptionKeyStore(
        writeError: Exception('keystore unavailable'),
      );
      await legacyKeyFile().writeAsString('legacy-plaintext-key', flush: true);

      await expectLater(
        resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Failed to persist the local inspection encryption key'),
          ),
        ),
      );
      expect(await legacyKeyFile().exists(), isTrue);
      expect(
        (await legacyKeyFile().readAsString()).trim(),
        'legacy-plaintext-key',
      );
    });

    test('fails closed when secure storage read fails', () async {
      final store = FakeLocalInspectionEncryptionKeyStore(
        readError: Exception('keychain locked'),
      );

      await expectLater(
        resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Failed to read the local inspection encryption key'),
          ),
        ),
      );
      expect(await legacyKeyFile().exists(), isFalse);
    });

    test('fails closed when secure storage write fails for new key', () async {
      final store = FakeLocalInspectionEncryptionKeyStore(
        writeError: Exception('secret service missing'),
      );

      await expectLater(
        resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
          generateKey: () => 'new-key',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Failed to persist the local inspection encryption key'),
          ),
        ),
      );
      expect(await legacyKeyFile().exists(), isFalse);
      expect(store.writtenKeys, isEmpty);
    });

    test('rejects empty generated keys', () async {
      final store = FakeLocalInspectionEncryptionKeyStore();

      await expectLater(
        resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
          generateKey: () => '   ',
        ),
        throwsA(isA<StateError>()),
      );
      expect(store.writeCount, 0);
    });
  });
}
