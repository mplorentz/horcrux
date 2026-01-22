import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import 'vault_share_service.dart';
import 'recovery_service.dart';
import 'relay_scan_service.dart';
import 'login_service.dart';
import 'logger.dart';

/// Service responsible for performing logout cleanup across data stores.
final logoutServiceProvider = Provider<LogoutService>((ref) {
  return LogoutService(
    vaultRepository: ref.read(vaultRepositoryProvider),
    vaultShareService: ref.read(vaultShareServiceProvider),
    recoveryService: ref.read(recoveryServiceProvider),
    relayScanService: ref.read(relayScanServiceProvider),
    loginService: ref.read(loginServiceProvider),
  );
});

class LogoutService {
  final VaultRepository _vaultRepository;
  final VaultShareService _vaultShareService;
  final RecoveryService _recoveryService;
  final RelayScanService _relayScanService;
  final LoginService _loginService;

  const LogoutService({
    required VaultRepository vaultRepository,
    required VaultShareService vaultShareService,
    required RecoveryService recoveryService,
    required RelayScanService relayScanService,
    required LoginService loginService,
  })  : _vaultRepository = vaultRepository,
        _vaultShareService = vaultShareService,
        _recoveryService = recoveryService,
        _relayScanService = relayScanService,
        _loginService = loginService;

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

    // Clear all service data
    await _vaultRepository.clearAll();
    await _vaultShareService.clearAll();
    await _recoveryService.clearAll();
    await _relayScanService.clearAll();
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
