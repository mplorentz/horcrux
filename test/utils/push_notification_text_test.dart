import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/utils/push_notification_text.dart';

import '../fixtures/test_keys.dart';

void main() {
  // A stable "owned by Alice, stewarded by Bob + Charlie" vault that every
  // test below mutates lightly. Putting the shared construction here keeps
  // the table-driven assertions below focused on the text output.
  Vault buildVault({
    String name = 'Family Vault',
    String? ownerName = 'Alice',
    String? bobName = 'Bob',
  }) {
    return Vault(
      id: 'v',
      name: name,
      content: 'decrypted',
      createdAt: DateTime.utc(2024, 1, 1),
      ownerPubkey: TestHexPubkeys.alice,
      ownerName: ownerName,
      backupConfig: createBackupConfig(
        vaultId: 'v',
        threshold: 1,
        totalKeys: 2,
        stewards: [
          createSteward(pubkey: TestHexPubkeys.bob, name: bobName),
          createSteward(pubkey: TestHexPubkeys.charlie, name: 'Charlie'),
        ],
        relays: const ['wss://relay.example'],
      ),
    );
  }

  group('composeNotificationText', () {
    test('shard data -- owner sends, body names the owner', () {
      final result = composeNotificationText(
        kind: NostrKind.shardData,
        vault: buildVault(),
        senderPubkey: TestHexPubkeys.alice,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Vault updated');
      expect(
        result.body,
        'Open Horcrux to save the latest data for Alice\'s vault "Family Vault"',
      );
    });

    test('recovery request -- wording mirrors LocalNotificationService', () {
      // Any steward (not just the owner) can initiate recovery. Bob triggers
      // one and Charlie receives the push; the text must read exactly like
      // the foreground local notification so switching from background to
      // foreground never changes what the recipient sees.
      final result = composeNotificationText(
        kind: NostrKind.recoveryRequest,
        vault: buildVault(),
        senderPubkey: TestHexPubkeys.bob,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Recovery request');
      expect(result.body, 'Bob is requesting your key to vault "Family Vault".');
    });

    test('recovery response (approved) -- mirrors LocalNotificationService', () {
      final result = composeNotificationText(
        kind: NostrKind.recoveryResponse,
        vault: buildVault(),
        senderPubkey: TestHexPubkeys.bob,
        recoveryApproved: true,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Recovery response');
      expect(result.body, 'Bob approved your recovery request for "Family Vault".');
    });

    test('recovery response (denied) -- mirrors LocalNotificationService', () {
      final result = composeNotificationText(
        kind: NostrKind.recoveryResponse,
        vault: buildVault(),
        senderPubkey: TestHexPubkeys.bob,
        recoveryApproved: false,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Recovery response');
      expect(result.body, 'Bob denied your recovery request for "Family Vault".');
    });

    test('recovery response (unknown approval) -- uses a neutral fallback', () {
      // When the caller doesn't know whether the response was an approval
      // or a denial, we still produce a sensible sentence rather than
      // leaking a null into the body. This path is defensive -- the
      // sender who triggers `/push` normally does know.
      final result = composeNotificationText(
        kind: NostrKind.recoveryResponse,
        vault: buildVault(),
        senderPubkey: TestHexPubkeys.bob,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Recovery response');
      expect(result.body, 'Bob sent a shard for recovery of "Family Vault".');
    });

    test('shard confirmation -- steward tells owner their shard is stored', () {
      final result = composeNotificationText(
        kind: NostrKind.shardConfirmation,
        vault: buildVault(),
        senderPubkey: TestHexPubkeys.bob,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Steward confirmed');
      expect(
        result.body,
        'Bob has confirmed they have the latest data for vault "Family Vault"',
      );
    });

    test('falls back to a short npub when the sender has no known display name', () {
      // Diana is a real Nostr pubkey that is not in this vault's metadata,
      // so the helper must not invent a name -- it should drop to the
      // `npub1...` shortening the rest of the app uses.
      final result = composeNotificationText(
        kind: NostrKind.recoveryRequest,
        vault: buildVault(),
        senderPubkey: TestHexPubkeys.diana,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Recovery request');
      // The exact suffix is derived from the pubkey bytes; assert on the
      // structural invariants instead of hardcoding it so bech32 library
      // changes don't break the test unexpectedly.
      expect(result.body, startsWith('npub1'));
      expect(result.body, contains('Family Vault'));
    });

    test('uses "your vault" when the vault name is blank', () {
      // A vault with an empty name can happen mid-migration or in tests;
      // the notification should still read as a sentence rather than
      // leaking an empty string into `"".`
      final result = composeNotificationText(
        kind: NostrKind.recoveryRequest,
        vault: buildVault(name: '   '),
        senderPubkey: TestHexPubkeys.alice,
      );
      expect(result, isNotNull);
      expect(result!.body, 'Alice is requesting your key to vault "your vault".');
    });

    test('handles a null vault (LocalNotificationService can hit this)', () {
      // LocalNotificationService loads a vault by id and may get `null` if
      // the vault repo hasn't synced yet. The helper must still produce a
      // sensible string rather than throwing.
      final result = composeNotificationText(
        kind: NostrKind.recoveryRequest,
        vault: null,
        senderPubkey: TestHexPubkeys.alice,
      );
      expect(result, isNotNull);
      // With no vault metadata, the sender falls through to the short npub.
      expect(result!.title, 'Recovery request');
      expect(result.body, startsWith('npub1'));
      expect(result.body, contains('"your vault"'));
    });

    test('unsupported kinds return null so callers can skip the push', () {
      // Pushes exist to trigger user action. For ack-style events we'd
      // otherwise have to invent filler text, which the UX doesn't want.
      // Encode that policy here: the helper refuses to compose, the caller
      // decides what "refuse" means (usually: don't call /push).
      for (final kind in [
        NostrKind.seal,
        NostrKind.giftWrap,
        NostrKind.httpAuth,
        NostrKind.invitationAcceptance,
        NostrKind.invitationDenial,
        NostrKind.shardError,
        NostrKind.invitationInvalid,
        NostrKind.keyHolderRemoved,
      ]) {
        expect(
          composeNotificationText(
            kind: kind,
            vault: buildVault(),
            senderPubkey: TestHexPubkeys.alice,
          ),
          isNull,
          reason: 'kind $kind should be unsupported',
        );
      }
    });

    test('blank sender names fall through to npub display', () {
      // Stewards can be invited without a friendly name filled in; the
      // helper must not render `" is requesting your key"` with a
      // leading space.
      final result = composeNotificationText(
        kind: NostrKind.recoveryRequest,
        vault: buildVault(bobName: ''),
        senderPubkey: TestHexPubkeys.bob,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Recovery request');
      expect(result.body, startsWith('npub1'));
      expect(result.body, contains('is requesting your key to vault "Family Vault"'));
    });
  });
}
