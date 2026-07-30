import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/key_holder_removal_reason.dart';
import '../models/steward_status.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';
import 'horcrux_notification_service.dart';
import 'invitation_sending_service.dart';
import 'logger.dart';
import 'logout_service.dart';
import 'ndk_service.dart';
import 'publish_service.dart';
import 'relay_scan_service.dart';

/// Provider for [AccountDeletionService].
final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    ndkService: ref.watch(ndkServiceProvider),
    relayScanService: ref.watch(relayScanServiceProvider),
    notificationService: ref.watch(horcruxNotificationServiceProvider),
    logoutService: ref.watch(logoutServiceProvider),
    vaultRepository: ref.watch(vaultRepositoryProvider),
    invitationSendingService: ref.watch(invitationSendingServiceProvider),
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

/// Orchestrates in-app account deletion (bead horcrux_app-tn3y + r6ng):
///
/// 1. Before broadcasting the vanish request, sends a kind-721
///    (`reason: vault_deleted`) to every active steward of every vault the
///    user owns, so stewards destroy their held shares. Failures are logged
///    and swallowed — the deletion proceeds regardless.
/// 2. Signs and broadcasts a NIP-62 "Request to Vanish" (kind 62) to every
///    enabled configured relay, asking relays to delete all of this user's
///    events.
/// 3. Best-effort deregisters this device from `horcrux-notifier` (the only
///    server-side state this client manages) -- failures are logged and
///    swallowed, since the relay broadcast is the authoritative deletion
///    signal.
/// 4. Only if at least one relay acknowledged the request: wipes all local
///    app data and the Nostr private key via [LogoutService.logout]. If no
///    relay acknowledged, local state (including the key needed to retry)
///    is left untouched.
///
/// Held-shares (vaults where the user is a STEWARD for someone else):
/// no protocol event is sent, because `logout()` already wipes the local
/// `held_shares` row. The owner is not notified and silently loses one
/// steward; this is accepted for v1 (a future steward_resigned event will
/// address this).
class AccountDeletionService {
  final NdkService _ndkService;
  final RelayScanService _relayScanService;
  final HorcruxNotificationService _notificationService;
  final LogoutService _logoutService;
  final VaultRepository _vaultRepository;
  final InvitationSendingService _invitationSendingService;

  AccountDeletionService({
    required NdkService ndkService,
    required RelayScanService relayScanService,
    required HorcruxNotificationService notificationService,
    required LogoutService logoutService,
    required VaultRepository vaultRepository,
    required InvitationSendingService invitationSendingService,
  })  : _ndkService = ndkService,
        _relayScanService = relayScanService,
        _notificationService = notificationService,
        _logoutService = logoutService,
        _vaultRepository = vaultRepository,
        _invitationSendingService = invitationSendingService;

  /// Requests account deletion. See class doc for the full sequence.
  ///
  /// [onRelayStatusUpdate], if given, is invoked with the live per-relay
  /// broadcast status every time any relay responds -- intended to drive a
  /// UI (e.g. [DeleteAccountScreen]) while the broadcast is in flight. It may
  /// fire zero or more times before this method resolves and has no bearing
  /// on the local-wipe decision, which is always based on [PublishBroadcastHandle.done].
  ///
  /// Throws a [StateError] if no relays are configured -- there is nowhere
  /// to send the vanish request.
  Future<AccountDeletionResult> deleteAccount({
    String? reason,
    void Function(List<RelayPublishStatus> statuses)? onRelayStatusUpdate,
  }) async {
    final relayConfigurations = await _relayScanService.getRelayConfigurations(
      enabledOnly: true,
    );
    final relayUrls = relayConfigurations.map((r) => r.url).toList();

    // Step 0: Validate relays before doing anything else.
    if (relayUrls.isEmpty) {
      throw StateError('No relays configured; cannot request account deletion.');
    }

    // Step 1: Before the vanish broadcast, notify all active stewards of
    // owned vaults to destroy their held shares (kind 721, vaultDeleted).
    // This is best-effort — failures don't abort the deletion.
    await _notifyStewardsOfOwnedVaults(relayUrls);

    final broadcast = await _ndkService.publishService.requestAccountVanish(
      relayUrls: relayUrls,
      reason: reason,
    );

    final subscription =
        onRelayStatusUpdate == null ? null : broadcast.statusUpdates.listen(onRelayStatusUpdate);
    final Set<String> acknowledged;
    try {
      acknowledged = await broadcast.done;
    } finally {
      await subscription?.cancel();
    }

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

  /// Best-effort: for each vault the user owns, sends a kind-721
  /// (`reason: vaultDeleted`) to each active steward. Failures are logged
  /// and swallowed so the overall deletion is never blocked by a flaky relay
  /// or a bad steward pubkey.
  Future<void> _notifyStewardsOfOwnedVaults(List<String> relayUrls) async {
    try {
      final allVaults = await _vaultRepository.getAllVaults();
      // Filter to vaults owned by the current user
      final ownedVaults = <Vault>[];
      for (final vault in allVaults) {
        if (await _vaultRepository.isOwnedVault(vault.id)) {
          ownedVaults.add(vault);
        }
      }

      if (ownedVaults.isEmpty) {
        Log.info('AccountDeletionService: no owned vaults to notify stewards for');
        return;
      }

      Log.info(
        'AccountDeletionService: notifying stewards of ${ownedVaults.length} owned vault(s)',
      );

      for (final vault in ownedVaults) {
        final config = vault.backupConfig;
        if (config == null) {
          Log.debug('AccountDeletionService: vault ${vault.id} has no backup config, skipping');
          continue;
        }

        // Include both holdingKey (confirmed share) and awaitingNewKey
        // (has old share, needs updated one) — both hold a share that
        // must be destroyed on account deletion.
        final activeStewards = config.stewards
            .where(
              (s) =>
                  (s.status == StewardStatus.holdingKey ||
                      s.status == StewardStatus.awaitingNewKey) &&
                  s.pubkey != null,
            )
            .toList();

        if (activeStewards.isEmpty) {
          Log.debug(
            'AccountDeletionService: vault ${vault.id} has no active stewards with pubkeys, skipping',
          );
          continue;
        }

        Log.info(
          'AccountDeletionService: sending vaultDeleted to '
          '${activeStewards.length} steward(s) of vault ${vault.id}',
        );

        // Use the vault's configured relays, falling back to the
        // account-vanish relay set. The union ensures stewards receive
        // the 721 even if the vault's relay list differs from the
        // account-vanish relay set.
        final vaultRelayUrls = config.relays.isNotEmpty
            ? {...config.relays, ...relayUrls}.toList()
            : relayUrls;

        for (final steward in activeStewards) {
          try {
            await _invitationSendingService.sendKeyHolderRemovalEvent(
              vaultId: vault.id,
              removedStewardPubkey: steward.pubkey!,
              relayUrls: vaultRelayUrls,
              reason: KeyHolderRemovalReason.vaultDeleted,
            );
          } catch (e, st) {
            Log.warning(
              'AccountDeletionService: failed to send vaultDeleted 721 to '
              'steward ${steward.id} for vault ${vault.id}',
              e,
              st,
            );
            // Best-effort — don't abort the deletion.
          }
        }
      }
    } catch (e, st) {
      Log.warning(
        'AccountDeletionService: error notifying stewards during account deletion',
        e,
        st,
      );
      // Best-effort — don't abort the deletion.
    }
  }
}
