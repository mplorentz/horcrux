import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Service responsible for performing logout cleanup across data stores.
///
/// Every dependency is watched so that an [appDatabaseProvider] invalidation
/// rebuilds this service against the new DB-backed services. Otherwise the
/// next logout in the same session would still hold the previous database's
/// repositories and either crash on access or wipe the wrong instance.
final logoutServiceProvider = Provider<LogoutService>((ref) {
  return LogoutService(
    vaultRepository: ref.watch(vaultRepositoryProvider),
    recoveryService: ref.watch(recoveryServiceProvider),
    relayScanService: ref.watch(relayScanServiceProvider),
    loginService: ref.watch(loginServiceProvider),
    processedNostrEventStore: ref.watch(processedNostrEventStoreProvider),
    appDatabase: ref.watch(appDatabaseProvider),
  );
});

class LogoutService {
  final VaultRepository _vaultRepository;
  final RecoveryService _recoveryService;
  final RelayScanService _relayScanService;
  final LoginService _loginService;
  final ProcessedNostrEventStore _processedNostrEventStore;
  final AppDatabase _appDatabase;
  final Future<void> Function() _deleteDatabaseFiles;
  final Future<void> Function() _clearSharedPreferences;
  final Future<void> Function() _clearSecureStorage;

  LogoutService({
    required VaultRepository vaultRepository,
    required RecoveryService recoveryService,
    required RelayScanService relayScanService,
    required LoginService loginService,
    required ProcessedNostrEventStore processedNostrEventStore,
    required AppDatabase appDatabase,
    Future<void> Function()? deleteDatabaseFiles,
    Future<void> Function()? clearSharedPreferences,
    Future<void> Function()? clearSecureStorage,
  })  : _vaultRepository = vaultRepository,
        _recoveryService = recoveryService,
        _relayScanService = relayScanService,
        _loginService = loginService,
        _processedNostrEventStore = processedNostrEventStore,
        _appDatabase = appDatabase,
        _deleteDatabaseFiles = deleteDatabaseFiles ?? deleteSqlCipherDatabaseFiles,
        _clearSharedPreferences = clearSharedPreferences ?? _clearAllSharedPreferences,
        _clearSecureStorage = clearSecureStorage ?? clearSecureStorageForWipe;

  // TODO(horcrux_app-u86): Remove once remaining SharedPreferences users migrate off prefs.
  static Future<void> _clearAllSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

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
    // These touch the database; on an unopenable DB (the "Reset Database"
    // recovery path) they throw. Swallow so the wipe below still runs and the
    // user is not left stuck with a broken database.
    try {
      await _vaultRepository.clearAll();
    } catch (e, st) {
      Log.error('Error clearing vault repository during logout', e, st);
    }
    try {
      await _recoveryService.clearAll();
    } catch (e, st) {
      Log.error('Error clearing recovery service during logout', e, st);
    }
    try {
      await _relayScanService.clearAll();
    } catch (e, st) {
      Log.error('Error clearing relay scan service during logout', e, st);
    }
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
      await _clearSharedPreferences();
      Log.info('LogoutService: cleared SharedPreferences');
    } catch (e, st) {
      Log.error('Error clearing SharedPreferences during logout', e, st);
    }

    try {
      await _clearSecureStorage();
      Log.info('LogoutService: cleared secure storage');
    } catch (e, st) {
      Log.error('Error clearing secure storage during logout', e, st);
    }

    Log.info('LogoutService: logout completed');
  }

  /// Wipes all local data like [logout] but restores the user's Nostr identity
  /// afterwards, so they keep their account and can immediately re-sync.
  ///
  /// This is the recovery path for an unrecoverable database (for example a
  /// pre-SQLCipher-fix unencrypted file that can no longer be opened). The
  /// current key is read *before* the wipe; [logout] then deletes the database
  /// files, salt, prefs, and stored keys; finally the key is re-imported so the
  /// next open derives a fresh, empty, correctly-encrypted database.
  ///
  /// If no key can be read (secure storage is also gone), the wipe still runs
  /// and the app falls through to onboarding.
  Future<void> resetDatabase() async {
    Log.info('LogoutService: resetting database (preserving identity)');

    String? privateKey;
    try {
      final keyPair = await _loginService.getStoredNostrKey();
      privateKey = keyPair?.privateKey;
    } catch (e, st) {
      Log.error('Error reading Nostr key before database reset', e, st);
    }

    await logout();

    if (privateKey != null && privateKey.isNotEmpty) {
      await _loginService.importHexPrivateKey(privateKey);
      Log.info('LogoutService: restored Nostr identity after database reset');
    } else {
      Log.warning(
        'LogoutService: no Nostr key to restore after database reset; '
        'user will land on onboarding',
      );
    }
  }
}
