import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import 'login_service.dart';
import 'logger.dart';
import 'processed_nostr_event_store.dart';
import 'recovery_service.dart';
import 'relay_scan_service.dart';
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
  );
});

class LogoutService {
  final VaultRepository _vaultRepository;
  final VaultShareService _vaultShareService;
  final RecoveryService _recoveryService;
  final RelayScanService _relayScanService;
  final LoginService _loginService;
  final ProcessedNostrEventStore _processedNostrEventStore;

  const LogoutService({
    required VaultRepository vaultRepository,
    required VaultShareService vaultShareService,
    required RecoveryService recoveryService,
    required RelayScanService relayScanService,
    required LoginService loginService,
    required ProcessedNostrEventStore processedNostrEventStore,
  })  : _vaultRepository = vaultRepository,
        _vaultShareService = vaultShareService,
        _recoveryService = recoveryService,
        _relayScanService = relayScanService,
        _loginService = loginService,
        _processedNostrEventStore = processedNostrEventStore;

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
    await _loginService.clearStoredKeys();

    // Clear all SharedPreferences to ensure complete cleanup
    // This removes any leftover vault files or other data from the previous account
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Log.info('LogoutService: cleared all SharedPreferences');
    } catch (e) {
      Log.error('Error clearing SharedPreferences during logout', e);
      // Don't throw - we've already cleared the main data stores
    }

    Log.info('LogoutService: logout completed');
  }
}

/// Wipes durable on-disk caches that reference the active Nostr identity.
///
/// Call when secure-storage decryption fails (e.g. installing the debug build
/// over the release build, or Android Auto Backup restoring SharedPreferences /
/// application support files into a process whose keystore key is gone). The
/// previous private key is unrecoverable, so any caches keyed off it -- the
/// processed Nostr event log/WAL/cursors, vault metadata in SharedPreferences,
/// and any half-written ciphertext in secure storage -- must be discarded
/// before generating a fresh identity.
///
/// Unlike [LogoutService.logout], this does not stop relay scanning or tear
/// down service caches: it is intended for the cold-start corruption path
/// where no services have been initialised yet.
Future<void> wipeLocalDataForCorruptedSecureStorage({
  required ProcessedNostrEventStore processedNostrEventStore,
}) async {
  Log.warning('Wiping local caches due to corrupted secure storage');

  try {
    await processedNostrEventStore.clearAll();
  } catch (e, st) {
    Log.error('Failed to clear processed Nostr event store during corruption wipe', e, st);
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (e, st) {
    Log.error('Failed to clear SharedPreferences during corruption wipe', e, st);
  }

  try {
    // Match the LoginService secure-storage configuration so resetOnError lines
    // up with the storage instance that holds the corrupted ciphertext.
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: true),
    );
    await storage.deleteAll();
  } catch (e, st) {
    Log.error('Failed to deleteAll secure storage during corruption wipe', e, st);
  }
}
