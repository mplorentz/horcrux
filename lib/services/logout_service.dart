import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../database/connection.dart';
import '../database/db_key.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import 'invitation_service.dart';
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
    invitationService: ref.watch(invitationServiceProvider),
  );
});

class LogoutService {
  final VaultRepository _vaultRepository;
  final RecoveryService _recoveryService;
  final RelayScanService _relayScanService;
  final LoginService _loginService;
  final ProcessedNostrEventStore _processedNostrEventStore;
  final AppDatabase _appDatabase;
  final InvitationService _invitationService;
  final Future<void> Function() _deleteDatabaseFiles;
  final Future<void> Function() _clearSharedPreferences;
  final Future<void> Function() _clearSecureStorage;
  final Future<void> Function() _deleteDbKeySalt;

  LogoutService({
    required VaultRepository vaultRepository,
    required RecoveryService recoveryService,
    required RelayScanService relayScanService,
    required LoginService loginService,
    required ProcessedNostrEventStore processedNostrEventStore,
    required AppDatabase appDatabase,
    required InvitationService invitationService,
    Future<void> Function()? deleteDatabaseFiles,
    Future<void> Function()? clearSharedPreferences,
    Future<void> Function()? clearSecureStorage,
    Future<void> Function()? deleteDbKeySalt,
  })  : _vaultRepository = vaultRepository,
        _recoveryService = recoveryService,
        _relayScanService = relayScanService,
        _loginService = loginService,
        _processedNostrEventStore = processedNostrEventStore,
        _appDatabase = appDatabase,
        _invitationService = invitationService,
        _deleteDatabaseFiles = deleteDatabaseFiles ?? deleteSqlCipherDatabaseFiles,
        _clearSharedPreferences = clearSharedPreferences ?? _clearAllSharedPreferences,
        _clearSecureStorage = clearSecureStorage ?? clearSecureStorageForWipe,
        _deleteDbKeySalt = deleteDbKeySalt ?? (() => DbKeyDerivation().deleteSalt());

  // TODO(horcrux_app-u86): Remove once remaining SharedPreferences users migrate off prefs.
  static Future<void> _clearAllSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> logout() async {
    Log.info('LogoutService: clearing all vault data and keys');
    await _wipeLocalState(preserveIdentity: false);
    Log.info('LogoutService: logout completed');
  }

  /// Wipes local data while keeping the Nostr private key in secure storage.
  ///
  /// Recovery path for an unrecoverable database (for example a
  /// pre-SQLCipher-fix unencrypted file that can no longer be opened). Deletes
  /// database files, prefs, and the DB key salt so the next open derives a
  /// fresh empty encrypted database — without ever removing
  /// `nostr_private_key`, so a failed reset cannot strand the user without an
  /// identity.
  ///
  /// If secure storage has no key, the wipe still runs and the app falls
  /// through to onboarding.
  Future<void> resetDatabase() async {
    Log.info('LogoutService: resetting database (preserving identity)');
    await _wipeLocalState(preserveIdentity: true);
    Log.info('LogoutService: database reset completed (identity preserved)');
  }

  /// Shared cleanup for [logout] and [resetDatabase].
  ///
  /// When [preserveIdentity] is true, skips [LoginService.clearStoredKeys] and
  /// full secure-storage wipe; deletes only the SQLCipher salt so the next open
  /// gets a new derivation while the Nostr key remains.
  Future<void> _wipeLocalState({required bool preserveIdentity}) async {
    // Stop relay scanning first to stop NDK subscriptions
    // This must be done before invalidating the NDK provider
    try {
      await _relayScanService.stopRelayScanning();
      Log.info('LogoutService: stopped relay scanning');
    } catch (e) {
      Log.error('Error stopping relay scanning during wipe', e);
      // Continue even if this fails
    }

    // Clear all service data (clear the on-disk processed Nostr event store
    // after relay scanning has stopped so nothing is racing to write the WAL).
    // These touch the database; on an unopenable DB (the "Reset Database"
    // recovery path) they throw. Swallow so the wipe below still runs and the
    // user is not left stuck with a broken database.
    try {
      await _vaultRepository.clearAll();
    } catch (e, st) {
      Log.error('Error clearing vault repository during wipe', e, st);
    }
    try {
      await _recoveryService.clearAll();
    } catch (e, st) {
      Log.error('Error clearing recovery service during wipe', e, st);
    }
    try {
      await _relayScanService.clearAll();
    } catch (e, st) {
      Log.error('Error clearing relay scan service during wipe', e, st);
    }
    try {
      await _processedNostrEventStore.clearAll();
    } catch (e, st) {
      Log.error('Error clearing processed Nostr event store during wipe', e, st);
    }

    // Clear staged invitation so it does not re-surface after the next login.
    _invitationService.clearStagedInvitation();

    if (!preserveIdentity) {
      // Clear primary key material so LoginService's in-memory cache is reset.
      try {
        await _loginService.clearStoredKeys();
      } catch (e, st) {
        Log.error('Error clearing login keys during wipe', e, st);
      }
    }

    // Close drift before deleting SQLite files to avoid locked-file races.
    try {
      await _appDatabase.close();
    } catch (e, st) {
      Log.error('Error closing app database during wipe', e, st);
    }

    try {
      await _deleteDatabaseFiles();
      Log.info('LogoutService: deleted SQLCipher database files');
    } catch (e, st) {
      Log.error('Error deleting SQLCipher files during wipe', e, st);
    }

    try {
      await _clearSharedPreferences();
      Log.info('LogoutService: cleared SharedPreferences');
    } catch (e, st) {
      Log.error('Error clearing SharedPreferences during wipe', e, st);
    }

    if (preserveIdentity) {
      try {
        await _deleteDbKeySalt();
        Log.info('LogoutService: deleted DB key salt (identity preserved)');
      } catch (e, st) {
        Log.error('Error deleting DB key salt during wipe', e, st);
      }
    } else {
      try {
        await _clearSecureStorage();
        Log.info('LogoutService: cleared secure storage');
      } catch (e, st) {
        Log.error('Error clearing secure storage during wipe', e, st);
      }
    }
  }
}
