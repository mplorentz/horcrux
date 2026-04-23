import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/key_provider.dart';
import '../providers/vault_provider.dart';
import '../services/logger.dart';
import '../services/push_notification_receiver.dart';

/// Best-effort owner-side push opt-in nudge.
///
/// Call this when a vault owner is navigating away from a screen that
/// implicates push delivery (vault detail, recovery plan). If the vault has
/// push enabled, the platform supports push, and the user hasn't already
/// opted in, we surface the OS permission dialog and -- on failure -- a
/// short snackbar letting them know they can re-enable via Settings.
///
/// The prompt fires every time the owner navigates away from a push-enabled
/// vault; to silence it they can disable push for that vault on the
/// recovery plan screen (which flips [Vault.pushEnabled] to false).
///
/// Silent (swallows errors, shows nothing) when:
///  - push isn't supported on the platform,
///  - the vault was deleted or no longer has push enabled,
///  - the user is not the vault owner, or
///  - the user already opted in globally.
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
    if (await pushReceiver.isOptedIn()) return;

    final optedIn = await pushReceiver.optIn();
    if (!optedIn && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Push permission was not granted. Stewards will not receive '
            'device alerts until you enable push in Settings.',
          ),
        ),
      );
    }
  } catch (e, st) {
    Log.warning('maybePromptOwnerForVaultPush failed', e, st);
  }
}
