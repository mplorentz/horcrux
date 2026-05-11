import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/connection.dart';
import 'package:horcrux/database/db_key.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';
import 'package:horcrux/services/secure_storage_corruption.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/secure_storage_mock.dart';

class _FakeProcessedNostrEventStore extends ProcessedNostrEventStore {
  int clearAllCalls = 0;

  @override
  Future<void> clearAll() async {
    clearAllCalls += 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();

  setUpAll(() {
    secureStorageMock.setUpAll();
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
  });

  setUp(() {
    secureStorageMock.clear();
    SharedPreferences.setMockInitialValues({});
  });

  group('isPermanentSecureStorageReadFailure', () {
    test('false for non-PlatformException errors', () {
      expect(isPermanentSecureStorageReadFailure(Exception('boom')), isFalse);
      expect(isPermanentSecureStorageReadFailure(StateError('nope')), isFalse);
      expect(isPermanentSecureStorageReadFailure('plain string'), isFalse);
    });

    test('true for BadPaddingException-wrapped PlatformException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, javax.crypto.BadPaddingException: '
            'error:1e000065:Cipher functions:OPENSSL_internal:BAD_DECRYPT',
      );
      expect(isPermanentSecureStorageReadFailure(err), isTrue);
    });

    test('true for InvalidKeyException-wrapped PlatformException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, java.security.InvalidKeyException: Failed',
      );
      expect(isPermanentSecureStorageReadFailure(err), isTrue);
    });

    test('true for UnrecoverableKeyException-wrapped PlatformException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, '
            'java.security.UnrecoverableKeyException: Failed to obtain information about private key',
      );
      expect(isPermanentSecureStorageReadFailure(err), isTrue);
    });

    test('false for transient KeyStoreException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, java.security.KeyStoreException: '
            'AndroidKeyStore not found',
      );
      expect(isPermanentSecureStorageReadFailure(err), isFalse);
    });

    test('false for transient NullPointerException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, java.lang.NullPointerException',
      );
      expect(isPermanentSecureStorageReadFailure(err), isFalse);
    });

    test('false for transient ServiceSpecificException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, android.os.ServiceSpecificException: code 7',
      );
      expect(isPermanentSecureStorageReadFailure(err), isFalse);
    });

    test('checks details as well as message', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'something generic',
        details: 'wrapped: javax.crypto.BadPaddingException',
      );
      expect(isPermanentSecureStorageReadFailure(err), isTrue);
    });

    test('false for PlatformException with no useful payload', () {
      final err = PlatformException(code: 'Unknown');
      expect(isPermanentSecureStorageReadFailure(err), isFalse);
    });
  });

  group('wipeLocalDataForCorruptedSecureStorage', () {
    test('deletes DB files and clears secure storage keys', () async {
      final tempDir = await Directory.systemTemp.createTemp('horcrux-corruption-wipe');
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(resetOnError: true),
      );
      final fakeStore = _FakeProcessedNostrEventStore();
      final dbPath = p.join(tempDir.path, dbFileName);

      try {
        await File(dbPath).writeAsString('db');
        await File('$dbPath-wal').writeAsString('wal');
        await File('$dbPath-shm').writeAsString('shm');
        await storage.write(key: 'nostr_private_key', value: 'deadbeef');
        await storage.write(key: DbKeyDerivation.saltStorageKey, value: 'salt');

        await wipeLocalDataForCorruptedSecureStorage(
          processedNostrEventStore: fakeStore,
          deleteDatabaseFiles: () async {
            await deleteSqlCipherDatabaseFiles(supportDirectory: tempDir);
          },
          clearSecureStorage: () async {
            await clearSecureStorageForWipe(storage: storage);
          },
        );

        expect(fakeStore.clearAllCalls, 1);
        expect(await File(dbPath).exists(), isFalse);
        expect(await File('$dbPath-wal').exists(), isFalse);
        expect(await File('$dbPath-shm').exists(), isFalse);
        expect(await storage.read(key: 'nostr_private_key'), isNull);
        expect(await storage.read(key: DbKeyDerivation.saltStorageKey), isNull);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
