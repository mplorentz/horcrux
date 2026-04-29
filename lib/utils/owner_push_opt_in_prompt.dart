import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/key_provider.dart';
import '../providers/vault_provider.dart';
import '../services/local_notification_service.dart';
import '../services/logger.dart';
import '../services/push_notification_receiver.dart';

/// Best-effort owner-side push opt-in nudge.
///
/// Call this when a vault owner is entering or leaving a screen that
/// implicates push delivery (vault detail, recovery plan). If the vault has
/// push enabled, the platform supports push, and the user hasn't already
/// granted OS-level notification permission, we surface the OS permission
/// dialog and -- on failure -- a short snackbar letting them know they can
/// re-enable via Settings.
///
/// The prompt fires whenever the owner enters or leaves a push-enabled vault
/// detail screen; to silence it they can disable push for that vault on the
/// recovery plan screen (which flips [Vault.pushEnabled] to false), or grant
/// the OS-level permission. The OS itself rate-limits re-prompts after a
/// denial, so callers can fire freely.
///
/// Silent (swallows errors, shows nothing) when:
///  - push isn't supported on the platform,
///  - the vault was deleted or no longer has push enabled,
///  - the user is not the vault owner, or
///  - the user is already opted in globally **and** the OS currently grants
///    notification permission.
///
/// Re-runs the opt-in flow when our persisted flag claims "opted in" but the
/// OS-level permission is missing. This handles the case where an
/// uninstall + reinstall reset the OS permission while Android Auto Backup
/// (or iCloud SharedPreferences sync) restored our opt-in flag.
Future<void> maybePromptOwnerForVaultPush({
  required BuildContext context,
  required WidgetRef ref,
  required String vaultId,
}) async {
  if (!PushNotificationReceiver.isSupported) return;

  try {
    final repository = ref.read(vaultRepositoryProvider);
    final vault = await repository.getVault(vaultId);
    if (vault == null || !vault.pushEnabled) return;

    final currentPubkey = await ref.read(currentPublicKeyProvider.future);
    if (currentPubkey == null || !vault.isOwned(currentPubkey)) return;

    final pushReceiver = ref.read(pushNotificationReceiverProvider);
    if (await pushReceiver.isOptedIn()) {
      final localNotifications = ref.read(localNotificationServiceProvider);
      if (await localNotifications.areOsNotificationsEnabled()) return;
      Log.info(
        'maybePromptOwnerForVaultPush: persisted opt-in is true but OS '
        'notification permission is missing; re-running opt-in to restore '
        'permission and refresh notifier registration',
      );
      // Fall through to optIn() which re-requests OS permission and
      // re-registers the FCM token with horcrux-notifier (force=true).
    }

    final optedIn = await pushReceiver.optIn();
    if (!optedIn && context.mounted) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Push permission was not granted. Stewards will not receive '
            'device alerts until you enable push in Settings.',
            style: TextStyle(color: cs.onError),
          ),
          backgroundColor: cs.error,
        ),
      );
    }
  } catch (e, st) {
    Log.warning('maybePromptOwnerForVaultPush failed', e, st);
  }
}
