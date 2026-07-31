import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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

  group('generateLocalInspectionEncryptionKey', () {
    test('returns 32 cryptographically random bytes as 64 hex chars', () {
      final key = generateLocalInspectionEncryptionKey(random: Random(1));
      expect(key, hasLength(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key), isTrue);

      final other = generateLocalInspectionEncryptionKey(random: Random(2));
      expect(other, isNot(equals(key)));
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

    test(
      'migrates legacy plaintext companion file into secure storage',
      () async {
        final store = FakeLocalInspectionEncryptionKeyStore();
        await legacyKeyFile().writeAsString(
          'legacy-plaintext-key',
          flush: true,
        );

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
      },
    );

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

    test(
      'existing secure key with matching legacy file cleans up the file',
      () async {
        final store = FakeLocalInspectionEncryptionKeyStore(
          initialKey: 'secure-key',
        );
        await legacyKeyFile().writeAsString('secure-key', flush: true);

        final resolved = await resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
        );

        expect(resolved, 'secure-key');
        expect(store.writeCount, 0);
        expect(await legacyKeyFile().exists(), isFalse);
      },
    );

    test('existing secure key with conflicting legacy file fails closed and '
        'preserves it', () async {
      final store = FakeLocalInspectionEncryptionKeyStore(
        initialKey: 'secure-key',
      );
      await legacyKeyFile().writeAsString('other-key', flush: true);

      await expectLater(
        resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('conflicts with the key in OS secure storage'),
          ),
        ),
      );
      expect(await legacyKeyFile().exists(), isTrue);
      expect((await legacyKeyFile().readAsString()).trim(), 'other-key');
      expect(store.writeCount, 0);
    });

    test('migration write failure preserves the legacy file', () async {
      final store = FakeLocalInspectionEncryptionKeyStore(
        writeError: Exception('keystore unavailable'),
      );
      await legacyKeyFile().writeAsString('legacy-plaintext-key', flush: true);

      await expectLater(
        resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await legacyKeyFile().exists(), isTrue);
      expect(
        (await legacyKeyFile().readAsString()).trim(),
        'legacy-plaintext-key',
      );
    });

    test(
      'successful secure write followed by a retry can complete cleanup',
      () async {
        final store = FakeLocalInspectionEncryptionKeyStore();
        await legacyKeyFile().writeAsString(
          'legacy-plaintext-key',
          flush: true,
        );
        var deleteAttempts = 0;

        final first = await resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
          deleteLegacyFile: (file) async {
            deleteAttempts += 1;
            if (deleteAttempts == 1) {
              throw const FileSystemException('simulated delete failure');
            }
            await file.delete();
          },
        );

        expect(first, 'legacy-plaintext-key');
        expect(store.writeCount, 1);
        expect(await legacyKeyFile().exists(), isTrue);

        final second = await resolveLocalInspectionEncryptionKey(
          keyStore: store,
          documentsDirectory: documentsDirectory,
          deleteLegacyFile: (file) async {
            deleteAttempts += 1;
            await file.delete();
          },
        );

        expect(second, 'legacy-plaintext-key');
        expect(store.writeCount, 1);
        expect(await legacyKeyFile().exists(), isFalse);
        expect(deleteAttempts, 2);
      },
    );

    test('empty legacy file cleanup', () async {
      final store = FakeLocalInspectionEncryptionKeyStore(
        initialKey: 'secure-key',
      );
      await legacyKeyFile().writeAsString('   \n', flush: true);

      final resolved = await resolveLocalInspectionEncryptionKey(
        keyStore: store,
        documentsDirectory: documentsDirectory,
      );

      expect(resolved, 'secure-key');
      expect(await legacyKeyFile().exists(), isFalse);
      expect(store.writeCount, 0);
    });

    test('empty legacy file is removed before generating a new key', () async {
      final store = FakeLocalInspectionEncryptionKeyStore();
      await legacyKeyFile().writeAsString('', flush: true);

      final resolved = await resolveLocalInspectionEncryptionKey(
        keyStore: store,
        documentsDirectory: documentsDirectory,
        generateKey: () => 'new-generated-key',
      );

      expect(resolved, 'new-generated-key');
      expect(await legacyKeyFile().exists(), isFalse);
      expect(store.writtenKeys, ['new-generated-key']);
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

    test('rejects empty secure-storage writes', () async {
      final store = FakeLocalInspectionEncryptionKeyStore();

      await expectLater(store.writeKey('  '), throwsA(isA<ArgumentError>()));
      expect(store.writtenKeys, isEmpty);
    });
  });
}
