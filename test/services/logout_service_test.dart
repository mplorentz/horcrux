import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/logout_service.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';
import 'package:horcrux/services/recovery_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:horcrux/services/vault_share_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_database.dart';
import 'logout_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<VaultRepository>(),
  MockSpec<VaultShareService>(),
  MockSpec<RecoveryService>(),
  MockSpec<RelayScanService>(),
  MockSpec<LoginService>(),
  MockSpec<ProcessedNostrEventStore>(),
])
void main() {
  group('LogoutService', () {
    late MockVaultRepository vaultRepository;
    late MockVaultShareService vaultShareService;
    late MockRecoveryService recoveryService;
    late MockRelayScanService relayScanService;
    late MockLoginService loginService;
    late MockProcessedNostrEventStore processedStore;
    late AppDatabase appDatabase;

    setUp(() {
      vaultRepository = MockVaultRepository();
      vaultShareService = MockVaultShareService();
      recoveryService = MockRecoveryService();
      relayScanService = MockRelayScanService();
      loginService = MockLoginService();
      processedStore = MockProcessedNostrEventStore();
      appDatabase = newTestDatabase();

      when(relayScanService.stopRelayScanning()).thenAnswer((_) async {});
      when(vaultRepository.clearAll()).thenAnswer((_) async {});
      when(vaultShareService.clearAll()).thenAnswer((_) async {});
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
      var clearedSecureStorage = false;
      final service = LogoutService(
        vaultRepository: vaultRepository,
        vaultShareService: vaultShareService,
        recoveryService: recoveryService,
        relayScanService: relayScanService,
        loginService: loginService,
        processedNostrEventStore: processedStore,
        appDatabase: appDatabase,
        deleteDatabaseFiles: () async {
          deletedDbFiles = true;
        },
        clearSecureStorage: () async {
          clearedSecureStorage = true;
        },
      );

      await service.logout();

      verify(relayScanService.stopRelayScanning()).called(1);
      verify(vaultRepository.clearAll()).called(1);
      verify(vaultShareService.clearAll()).called(1);
      verify(recoveryService.clearAll()).called(1);
      verify(relayScanService.clearAll()).called(1);
      verify(processedStore.clearAll()).called(1);
      verify(loginService.clearStoredKeys()).called(1);
      expect(deletedDbFiles, isTrue);
      expect(clearedSecureStorage, isTrue);
    });

    test('continues cleanup when key clearing throws', () async {
      when(loginService.clearStoredKeys()).thenThrow(StateError('key clear failed'));
      var deletedDbFiles = false;
      var clearedSecureStorage = false;
      final service = LogoutService(
        vaultRepository: vaultRepository,
        vaultShareService: vaultShareService,
        recoveryService: recoveryService,
        relayScanService: relayScanService,
        loginService: loginService,
        processedNostrEventStore: processedStore,
        appDatabase: appDatabase,
        deleteDatabaseFiles: () async {
          deletedDbFiles = true;
        },
        clearSecureStorage: () async {
          clearedSecureStorage = true;
        },
      );

      await service.logout();

      expect(deletedDbFiles, isTrue);
      expect(clearedSecureStorage, isTrue);
      verify(loginService.clearStoredKeys()).called(1);
    });
  });
}
