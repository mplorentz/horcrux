import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    await _vaultRepository.clearAll();
    await _vaultShareService.clearAll();
    await _recoveryService.clearAll();
    await _relayScanService.clearAll();
    await _loginService.clearStoredKeys();

    Log.info('LogoutService: logout completed');
  }
}
