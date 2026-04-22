import '../models/nostr_kinds.dart';
import '../models/vault.dart';
import 'nostr_display.dart';

/// A `(title, body)` pair ready to hand to the notifier's `notification`
/// payload. Plain record with two strings; no JSON contract of its own.
typedef PushNotificationText = ({String title, String body});

/// Composes personalized push notification text for the gift-wrapped Horcrux
/// event identified by [kind], for the vault [vault], originated by
/// [senderPubkey].
///
/// The sender's display name is resolved against the vault's metadata
/// (`ownerName`, steward list, most-recent shard), falling back to a short
/// `npub` when no friendly name is known -- the same fallback chain used by
/// in-app surfaces so a push and a list row identify the same person the same
/// way.
///
/// For recovery requests and responses the text intentionally mirrors
/// [LocalNotificationService] so a foreground local notification and a
/// background push look identical to the recipient. [recoveryApproved] is
/// only consulted for [NostrKind.recoveryResponse] and is ignored for every
/// other kind; when a response's approval status isn't known, a neutral
/// sentence is used.
///
/// The mapping:
///
/// | Kind                    | Title               | Body                                                                     |
/// | ----------------------- | ------------------- | ------------------------------------------------------------------------ |
/// | 1337 shard data         | "Vault updated"     | "Open Horcrux to save the latest data for {owner}'s vault {vault}"       |
/// | 1338 recovery request   | "Recovery request"  | "{sender} is requesting your key to vault {vault}."                      |
/// | 1339 recovery response  | "Recovery response" | "{sender} {approved|denied} recovery of {vault}." (sent a shard if null) |
/// | 1342 shard confirmation | "Steward confirmed" | "{sender} has confirmed they have the latest data for vault {vault}"     |
///
/// Kinds we don't specifically recognize (invitation acceptance/denial,
/// shard error, etc.) are not pushed -- the helper returns `null` so
/// `tryPushForEvent` can short-circuit instead of emitting a generic,
/// low-signal notification. Pushes exist to interrupt the recipient for
/// an action; silent no-op events don't meet that bar.
///
/// [vault] is nullable to support the foreground local-notification path
/// (where the vault may not have been synced yet). When it's `null` we fall
/// back to `"your vault"` and [shortNpub] for the sender. The push-trigger
/// path always has a vault in hand.
PushNotificationText? composeNotificationText({
  required NostrKind kind,
  required Vault? vault,
  required String senderPubkey,
  bool? recoveryApproved,
}) {
  final sender = displayNameFromPubkey(vault, senderPubkey);
  final resolvedName = vault?.name.trim() ?? '';
  final vaultName = resolvedName.isEmpty ? 'your vault' : resolvedName;

  switch (kind) {
    case NostrKind.shardData:
      // The sender of a 1337 gift wrap is the vault owner; use their
      // display name to personalize the body.
      return (
        title: 'Vault updated',
        body: "Open Horcrux to save the latest data for $sender's vault $vaultName",
      );
    case NostrKind.recoveryRequest:
      return (
        title: 'Recovery request',
        body: '$sender is requesting your key to vault "$vaultName".',
      );
    case NostrKind.recoveryResponse:
      final String body;
      if (recoveryApproved == true) {
        body = '$sender approved recovery of "$vaultName".';
      } else if (recoveryApproved == false) {
        body = '$sender denied recovery of "$vaultName".';
      } else {
        body = '$sender sent a shard for recovery of "$vaultName".';
      }
      return (title: 'Recovery response', body: body);
    case NostrKind.shardConfirmation:
      return (
        title: 'Steward confirmed',
        body: '$sender has confirmed they have the latest data for vault $vaultName',
      );
    case NostrKind.seal:
    case NostrKind.giftWrap:
    case NostrKind.httpAuth:
    case NostrKind.invitationAcceptance:
    case NostrKind.invitationDenial:
    case NostrKind.shardError:
    case NostrKind.invitationInvalid:
    case NostrKind.keyHolderRemoved:
      return null;
  }
}
