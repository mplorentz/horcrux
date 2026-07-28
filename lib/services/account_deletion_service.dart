import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'horcrux_notification_service.dart';
import 'logger.dart';
import 'logout_service.dart';
import 'ndk_service.dart';
import 'relay_scan_service.dart';

/// Provider for [AccountDeletionService].
final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    ndkService: ref.watch(ndkServiceProvider),
    relayScanService: ref.watch(relayScanServiceProvider),
    notificationService: ref.watch(horcruxNotificationServiceProvider),
    logoutService: ref.watch(logoutServiceProvider),
  );
});

/// Result of an account deletion attempt.
class AccountDeletionResult {
  /// Whether at least one relay acknowledged the vanish request.
  final bool relayRequestAcknowledged;

  /// How many of [relaysTotal] configured relays acknowledged the request.
  final int relaysAcknowledged;

  /// How many relays the request was sent to.
  final int relaysTotal;

  const AccountDeletionResult({
    required this.relayRequestAcknowledged,
    required this.relaysAcknowledged,
    required this.relaysTotal,
  });
}

/// Orchestrates in-app account deletion (bead horcrux_app-tn3y):
///
/// 1. Signs and broadcasts a NIP-62 "Request to Vanish" (kind 62) to every
///    enabled configured relay, asking relays to delete all of this user's
///    events.
/// 2. Best-effort deregisters this device from `horcrux-notifier` (the only
///    server-side state this client manages) -- failures are logged and
///    swallowed, since the relay broadcast is the authoritative deletion
///    signal.
/// 3. Only if at least one relay acknowledged the request: wipes all local
///    app data and the Nostr private key via [LogoutService.logout]. If no
///    relay acknowledged, local state (including the key needed to retry)
///    is left untouched.
class AccountDeletionService {
  final NdkService _ndkService;
  final RelayScanService _relayScanService;
  final HorcruxNotificationService _notificationService;
  final LogoutService _logoutService;

  AccountDeletionService({
    required NdkService ndkService,
    required RelayScanService relayScanService,
    required HorcruxNotificationService notificationService,
    required LogoutService logoutService,
  })  : _ndkService = ndkService,
        _relayScanService = relayScanService,
        _notificationService = notificationService,
        _logoutService = logoutService;

  /// Requests account deletion. See class doc for the full sequence.
  ///
  /// [onRelayStatusUpdate], if given, is invoked with the live per-relay
  /// broadcast status every time any relay responds -- intended to drive a
  /// UI (e.g. [DeleteAccountScreen]) while the broadcast is in flight. It may
  /// fire zero or more times before this method resolves and has no bearing
  /// on the local-wipe decision, which is always based on [VanishBroadcastHandle.done].
  ///
  /// Throws a [StateError] if no relays are configured -- there is nowhere
  /// to send the vanish request.
  Future<AccountDeletionResult> deleteAccount({
    String? reason,
    void Function(List<RelayVanishStatus> statuses)? onRelayStatusUpdate,
  }) async {
    final relayConfigurations = await _relayScanService.getRelayConfigurations(
      enabledOnly: true,
    );
    final relayUrls = relayConfigurations.map((r) => r.url).toList();
    if (relayUrls.isEmpty) {
      throw StateError('No relays configured; cannot request account deletion.');
    }

    final broadcast = await _ndkService.requestAccountVanish(
      relayUrls: relayUrls,
      reason: reason,
    );

    final subscription =
        onRelayStatusUpdate == null ? null : broadcast.statusUpdates.listen(onRelayStatusUpdate);
    final acknowledged = await broadcast.done;
    await subscription?.cancel();

    if (acknowledged.isEmpty) {
      Log.warning(
        'AccountDeletionService: vanish request acknowledged by 0/'
        '${relayUrls.length} relay(s); not wiping local state',
      );
      return AccountDeletionResult(
        relayRequestAcknowledged: false,
        relaysAcknowledged: 0,
        relaysTotal: relayUrls.length,
      );
    }

    try {
      await _notificationService.deregister();
    } catch (e, st) {
      Log.warning('AccountDeletionService: best-effort notifier deregister failed', e, st);
    }

    await _logoutService.logout();

    return AccountDeletionResult(
      relayRequestAcknowledged: true,
      relaysAcknowledged: acknowledged.length,
      relaysTotal: relayUrls.length,
    );
  }
}
