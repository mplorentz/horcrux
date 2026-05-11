import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../database/connection.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import 'login_service.dart';
import 'logger.dart';
import 'processed_nostr_event_store.dart';
import 'recovery_service.dart';
import 'relay_scan_service.dart';
import 'secure_storage_corruption.dart';
import 'vault_share_service.dart';

/// Service responsible for performing logout cleanup across data stores.
final logoutServiceProvider = Provider<LogoutService>((ref) {
  return LogoutService(
    vaultRepository: ref.read(vaultRepositoryProvider),
    vaultShareService: ref.read(vaultShareServiceProvider),
    recoveryService: ref.read(recoveryServiceProvider),
    relayScanService: ref.read(relayScanServiceProvider),
    loginService: ref.read(loginServiceProvider),
    processedNostrEventStore: ref.read(processedNostrEventStoreProvider),
    appDatabase: ref.read(appDatabaseProvider),
  );
});

class LogoutService {
  final VaultRepository _vaultRepository;
  final VaultShareService _vaultShareService;
  final RecoveryService _recoveryService;
  final RelayScanService _relayScanService;
  final LoginService _loginService;
  final ProcessedNostrEventStore _processedNostrEventStore;
  final AppDatabase _appDatabase;
  final Future<void> Function() _deleteDatabaseFiles;
  final Future<void> Function() _clearSecureStorage;

  LogoutService({
    required VaultRepository vaultRepository,
    required VaultShareService vaultShareService,
    required RecoveryService recoveryService,
    required RelayScanService relayScanService,
    required LoginService loginService,
    required ProcessedNostrEventStore processedNostrEventStore,
    required AppDatabase appDatabase,
    Future<void> Function()? deleteDatabaseFiles,
    Future<void> Function()? clearSecureStorage,
  })  : _vaultRepository = vaultRepository,
        _vaultShareService = vaultShareService,
        _recoveryService = recoveryService,
        _relayScanService = relayScanService,
        _loginService = loginService,
        _processedNostrEventStore = processedNostrEventStore,
        _appDatabase = appDatabase,
        _deleteDatabaseFiles = deleteDatabaseFiles ?? deleteSqlCipherDatabaseFiles,
        _clearSecureStorage = clearSecureStorage ?? clearSecureStorageForWipe;

  Future<void> logout() async {
    Log.info('LogoutService: clearing all vault data and keys');

    // Stop relay scanning first to stop NDK subscriptions
    // This must be done before invalidating the NDK provider
    try {
      await _relayScanService.stopRelayScanning();
      Log.info('LogoutService: stopped relay scanning');
    } catch (e) {
      Log.error('Error stopping relay scanning during logout', e);
      // Continue with logout even if this fails
    }

    // Clear all service data (clear the on-disk processed Nostr event store
    // after relay scanning has stopped so nothing is racing to write the WAL).
    await _vaultRepository.clearAll();
    await _vaultShareService.clearAll();
    await _recoveryService.clearAll();
    await _relayScanService.clearAll();
    try {
      await _processedNostrEventStore.clearAll();
    } catch (e, st) {
      Log.error('Error clearing processed Nostr event store during logout', e, st);
      // Don't throw - keep going so the rest of logout can complete
    }
    // Clear primary key material first so LoginService's in-memory cache is also reset.
    try {
      await _loginService.clearStoredKeys();
    } catch (e, st) {
      Log.error('Error clearing login keys during logout', e, st);
    }

    // Close drift before deleting SQLite files to avoid locked-file races.
    try {
      await _appDatabase.close();
    } catch (e, st) {
      Log.error('Error closing app database during logout', e, st);
    }

    try {
      await _deleteDatabaseFiles();
      Log.info('LogoutService: deleted SQLCipher database files');
    } catch (e, st) {
      Log.error('Error deleting SQLCipher files during logout', e, st);
    }

    try {
      await _clearSecureStorage();
      Log.info('LogoutService: cleared secure storage');
    } catch (e, st) {
      Log.error('Error clearing secure storage during logout', e, st);
    }

    Log.info('LogoutService: logout completed');
  }
}
