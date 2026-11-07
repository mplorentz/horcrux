import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/logout_service.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';
import 'package:horcrux/services/push_notification_receiver.dart';
import 'package:horcrux/services/recovery_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_database.dart';
import 'logout_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<VaultRepository>(),
  MockSpec<RecoveryService>(),
  MockSpec<RelayScanService>(),
  MockSpec<LoginService>(),
  MockSpec<ProcessedNostrEventStore>(),
  MockSpec<PushNotificationReceiver>(),
])
void main() {
  group('LogoutService', () {
    late MockVaultRepository vaultRepository;
    late MockRecoveryService recoveryService;
    late MockRelayScanService relayScanService;
    late MockLoginService loginService;
    late MockProcessedNostrEventStore processedStore;
    late MockPushNotificationReceiver pushNotificationReceiver;
    late AppDatabase appDatabase;

    var deletedDbFiles = false;
    var clearedSharedPreferences = false;
    var clearedSecureStorage = false;
    var deletedDbKeySalt = false;

    LogoutService buildService() {
      return LogoutService(
        vaultRepository: vaultRepository,
        recoveryService: recoveryService,
        relayScanService: relayScanService,
        loginService: loginService,
        processedNostrEventStore: processedStore,
        pushNotificationReceiver: pushNotificationReceiver,
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
        deleteDbKeySalt: () async {
          deletedDbKeySalt = true;
        },
      );
    }

    void verifySharedWipeSteps() {
      verify(relayScanService.stopRelayScanning()).called(1);
      verify(vaultRepository.clearAll()).called(1);
      verify(recoveryService.clearAll()).called(1);
      verify(relayScanService.clearAll()).called(1);
      verify(processedStore.clearAll()).called(1);
      expect(deletedDbFiles, isTrue);
      expect(clearedSharedPreferences, isTrue);
    }

    setUp(() {
      vaultRepository = MockVaultRepository();
      recoveryService = MockRecoveryService();
      relayScanService = MockRelayScanService();
      loginService = MockLoginService();
      processedStore = MockProcessedNostrEventStore();
      pushNotificationReceiver = MockPushNotificationReceiver();
      appDatabase = newTestDatabase();

      deletedDbFiles = false;
      clearedSharedPreferences = false;
      clearedSecureStorage = false;
      deletedDbKeySalt = false;

      when(relayScanService.stopRelayScanning()).thenAnswer((_) async {});
      when(vaultRepository.clearAll()).thenAnswer((_) async {});
      when(recoveryService.clearAll()).thenAnswer((_) async {});
      when(relayScanService.clearAll()).thenAnswer((_) async {});
      when(processedStore.clearAll()).thenAnswer((_) async {});
      when(loginService.clearStoredKeys()).thenAnswer((_) async {});
      when(pushNotificationReceiver.optOut()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await appDatabase.close();
    });

    group('logout (preserveIdentity: false)', () {
      test('clears identity and secure storage, does not delete salt alone', () async {
        await buildService().logout();

        verifySharedWipeSteps();
        verify(loginService.clearStoredKeys()).called(1);
        expect(clearedSecureStorage, isTrue);
        expect(deletedDbKeySalt, isFalse);
      });

      test('continues when clearStoredKeys throws', () async {
        when(loginService.clearStoredKeys()).thenThrow(StateError('key clear failed'));

        await buildService().logout();

        expect(deletedDbFiles, isTrue);
        expect(clearedSharedPreferences, isTrue);
        expect(clearedSecureStorage, isTrue);
        expect(deletedDbKeySalt, isFalse);
        verify(loginService.clearStoredKeys()).called(1);
      });

      test('continues when clearSecureStorage throws', () async {
        final service = LogoutService(
          vaultRepository: vaultRepository,
          recoveryService: recoveryService,
          relayScanService: relayScanService,
          loginService: loginService,
          processedNostrEventStore: processedStore,
          pushNotificationReceiver: pushNotificationReceiver,
          appDatabase: appDatabase,
          deleteDatabaseFiles: () async {
            deletedDbFiles = true;
          },
          clearSharedPreferences: () async {
            clearedSharedPreferences = true;
          },
          clearSecureStorage: () async {
            throw StateError('secure storage wipe failed');
          },
          deleteDbKeySalt: () async {
            deletedDbKeySalt = true;
          },
        );

        await service.logout();

        expect(deletedDbFiles, isTrue);
        expect(clearedSharedPreferences, isTrue);
        expect(deletedDbKeySalt, isFalse);
        verify(loginService.clearStoredKeys()).called(1);
      });

      test('continues when stopRelayScanning throws', () async {
        when(relayScanService.stopRelayScanning()).thenThrow(StateError('scan stop failed'));

        await buildService().logout();

        verifySharedWipeSteps();
        verify(loginService.clearStoredKeys()).called(1);
        expect(clearedSecureStorage, isTrue);
      });

      test('continues when repository clearAll throws', () async {
        when(vaultRepository.clearAll()).thenThrow(StateError('db unopenable'));

        await buildService().logout();

        expect(deletedDbFiles, isTrue);
        expect(clearedSharedPreferences, isTrue);
        expect(clearedSecureStorage, isTrue);
        verify(loginService.clearStoredKeys()).called(1);
        expect(deletedDbKeySalt, isFalse);
      });

      test('calls pushNotificationReceiver.optOut() before clearing keys', () async {
        // Track call ordering
        final callOrder = <String>[];
        when(pushNotificationReceiver.optOut()).thenAnswer((_) async {
          callOrder.add('optOut');
        });
        when(loginService.clearStoredKeys()).thenAnswer((_) async {
          callOrder.add('clearStoredKeys');
        });

        await buildService().logout();

        verify(pushNotificationReceiver.optOut()).called(1);
        verify(loginService.clearStoredKeys()).called(1);
        expect(callOrder, ['optOut', 'clearStoredKeys']);
      });

      test('continues logout when pushNotificationReceiver.optOut() throws', () async {
        when(pushNotificationReceiver.optOut()).thenThrow(Exception('notifier down'));

        await buildService().logout();

        // Logout should still complete all wipe steps
        verifySharedWipeSteps();
        verify(loginService.clearStoredKeys()).called(1);
        expect(clearedSecureStorage, isTrue);
        expect(deletedDbKeySalt, isFalse);
      });
    });

    group('resetDatabase (preserveIdentity: true)', () {
      test('wipes data without clearing identity', () async {
        await buildService().resetDatabase();

        verifySharedWipeSteps();
        expect(deletedDbKeySalt, isTrue);
        expect(clearedSecureStorage, isFalse);
        verifyNever(loginService.clearStoredKeys());
        verifyNever(loginService.importHexPrivateKey(any));
        verifyNever(loginService.getStoredNostrKey());
      });

      test('completes the wipe even when clearAll throws', () async {
        when(vaultRepository.clearAll()).thenThrow(StateError('db unopenable'));

        await buildService().resetDatabase();

        expect(deletedDbFiles, isTrue);
        expect(clearedSharedPreferences, isTrue);
        expect(deletedDbKeySalt, isTrue);
        expect(clearedSecureStorage, isFalse);
        verifyNever(loginService.clearStoredKeys());
        verifyNever(loginService.importHexPrivateKey(any));
      });

      test('continues when deleteDbKeySalt throws', () async {
        final service = LogoutService(
          vaultRepository: vaultRepository,
          recoveryService: recoveryService,
          relayScanService: relayScanService,
          loginService: loginService,
          processedNostrEventStore: processedStore,
          pushNotificationReceiver: pushNotificationReceiver,
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
          deleteDbKeySalt: () async {
            throw StateError('salt delete failed');
          },
        );

        await service.resetDatabase();

        expect(deletedDbFiles, isTrue);
        expect(clearedSharedPreferences, isTrue);
        expect(clearedSecureStorage, isFalse);
        verifyNever(loginService.clearStoredKeys());
      });

      test('calls pushNotificationReceiver.optOut() on resetDatabase', () async {
        await buildService().resetDatabase();

        verify(pushNotificationReceiver.optOut()).called(1);
      });

      test('continues resetDatabase when pushNotificationReceiver.optOut() throws', () async {
        when(pushNotificationReceiver.optOut()).thenThrow(Exception('notifier down'));

        await buildService().resetDatabase();

        // Reset should still complete all wipe steps
        verifySharedWipeSteps();
        expect(deletedDbKeySalt, isTrue);
        expect(clearedSecureStorage, isFalse);
        verifyNever(loginService.clearStoredKeys());
      });
    });
  });
}
