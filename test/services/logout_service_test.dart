import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/logout_service.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';
import 'package:horcrux/services/recovery_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../helpers/test_database.dart';
import 'logout_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<VaultRepository>(),
  MockSpec<RecoveryService>(),
  MockSpec<RelayScanService>(),
  MockSpec<LoginService>(),
  MockSpec<ProcessedNostrEventStore>(),
])
void main() {
  group('LogoutService', () {
    late MockVaultRepository vaultRepository;
    late MockRecoveryService recoveryService;
    late MockRelayScanService relayScanService;
    late MockLoginService loginService;
    late MockProcessedNostrEventStore processedStore;
    late AppDatabase appDatabase;

    setUp(() {
      vaultRepository = MockVaultRepository();
      recoveryService = MockRecoveryService();
      relayScanService = MockRelayScanService();
      loginService = MockLoginService();
      processedStore = MockProcessedNostrEventStore();
      appDatabase = newTestDatabase();

      when(relayScanService.stopRelayScanning()).thenAnswer((_) async {});
      when(vaultRepository.clearAll()).thenAnswer((_) async {});
      when(recoveryService.clearAll()).thenAnswer((_) async {});
      when(relayScanService.clearAll()).thenAnswer((_) async {});
      when(processedStore.clearAll()).thenAnswer((_) async {});
      when(loginService.clearStoredKeys()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await appDatabase.close();
    });

    test('closes DB, deletes files, and clears secure storage', () async {
      var deletedDbFiles = false;
      var clearedSharedPreferences = false;
      var clearedSecureStorage = false;
      final service = LogoutService(
        vaultRepository: vaultRepository,
        recoveryService: recoveryService,
        relayScanService: relayScanService,
        loginService: loginService,
        processedNostrEventStore: processedStore,
        appDatabase: appDatabase,
        deleteDatabaseFiles: () async {
          deletedDbFiles = true;
        },
        clearSharedPreferences: () async {
          clearedSharedPreferences = true;
        },
        clearSecureStorage: () async {
          clearedSecureStorage = true;
        },
      );

      await service.logout();

      verify(relayScanService.stopRelayScanning()).called(1);
      verify(vaultRepository.clearAll()).called(1);
      verify(recoveryService.clearAll()).called(1);
      verify(relayScanService.clearAll()).called(1);
      verify(processedStore.clearAll()).called(1);
      verify(loginService.clearStoredKeys()).called(1);
      expect(deletedDbFiles, isTrue);
      expect(clearedSharedPreferences, isTrue);
      expect(clearedSecureStorage, isTrue);
    });

    test('continues cleanup when key clearing throws', () async {
      when(loginService.clearStoredKeys()).thenThrow(StateError('key clear failed'));
      var deletedDbFiles = false;
      var clearedSharedPreferences = false;
      var clearedSecureStorage = false;
      final service = LogoutService(
        vaultRepository: vaultRepository,
        recoveryService: recoveryService,
        relayScanService: relayScanService,
        loginService: loginService,
        processedNostrEventStore: processedStore,
        appDatabase: appDatabase,
        deleteDatabaseFiles: () async {
          deletedDbFiles = true;
        },
        clearSharedPreferences: () async {
          clearedSharedPreferences = true;
        },
        clearSecureStorage: () async {
          clearedSecureStorage = true;
        },
      );

      await service.logout();

      expect(deletedDbFiles, isTrue);
      expect(clearedSharedPreferences, isTrue);
      expect(clearedSecureStorage, isTrue);
      verify(loginService.clearStoredKeys()).called(1);
    });

    group('resetDatabase', () {
      const privateKeyHex = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final keyPair = KeyPair(
        privateKeyHex,
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        'nsec-dummy',
        'npub-dummy',
      );

      test('wipes data then re-imports the existing key', () async {
        when(loginService.getStoredNostrKey()).thenAnswer((_) async => keyPair);
        when(loginService.importHexPrivateKey(any)).thenAnswer((_) async => keyPair);
        var deletedDbFiles = false;
        final service = LogoutService(
          vaultRepository: vaultRepository,
          recoveryService: recoveryService,
          relayScanService: relayScanService,
          loginService: loginService,
          processedNostrEventStore: processedStore,
          appDatabase: appDatabase,
          deleteDatabaseFiles: () async {
            deletedDbFiles = true;
          },
          clearSharedPreferences: () async {},
          clearSecureStorage: () async {},
        );

        await service.resetDatabase();

        expect(deletedDbFiles, isTrue);
        verify(loginService.clearStoredKeys()).called(1);
        verify(loginService.importHexPrivateKey(privateKeyHex)).called(1);
      });

      test('completes the wipe even when clearAll throws', () async {
        when(vaultRepository.clearAll()).thenThrow(StateError('db unopenable'));
        when(loginService.getStoredNostrKey()).thenAnswer((_) async => keyPair);
        when(loginService.importHexPrivateKey(any)).thenAnswer((_) async => keyPair);
        var deletedDbFiles = false;
        final service = LogoutService(
          vaultRepository: vaultRepository,
          recoveryService: recoveryService,
          relayScanService: relayScanService,
          loginService: loginService,
          processedNostrEventStore: processedStore,
          appDatabase: appDatabase,
          deleteDatabaseFiles: () async {
            deletedDbFiles = true;
          },
          clearSharedPreferences: () async {},
          clearSecureStorage: () async {},
        );

        await service.resetDatabase();

        expect(deletedDbFiles, isTrue);
        verify(loginService.importHexPrivateKey(privateKeyHex)).called(1);
      });

      test('skips re-import when no key is available', () async {
        when(loginService.getStoredNostrKey()).thenAnswer((_) async => null);
        var deletedDbFiles = false;
        final service = LogoutService(
          vaultRepository: vaultRepository,
          recoveryService: recoveryService,
          relayScanService: relayScanService,
          loginService: loginService,
          processedNostrEventStore: processedStore,
          appDatabase: appDatabase,
          deleteDatabaseFiles: () async {
            deletedDbFiles = true;
          },
          clearSharedPreferences: () async {},
          clearSecureStorage: () async {},
        );

        await service.resetDatabase();

        expect(deletedDbFiles, isTrue);
        verifyNever(loginService.importHexPrivateKey(any));
      });
    });
  });
}
