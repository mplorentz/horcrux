import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';

import '../fixtures/test_keys.dart';
import 'steward_test_helpers.dart';
import 'vault_detail_golden_fixtures.dart';

/// Shared Play Store screenshot fixture data and provider overrides.
abstract final class PlayStoreScreenshotFixtures {
  static const ownerPubkey = TestHexPubkeys.alice;
  static const marcusPubkey = TestHexPubkeys.bob;
  static const elenaPubkey = TestHexPubkeys.charlie;
  static const jamesPubkey = TestHexPubkeys.diana;

  static const familyVaultId = 'vault-family-passwords';
  static const estateVaultId = 'vault-estate-documents';
  static const marcusVaultId = 'vault-marcus-will';

  static const recoveryId = 'recovery-family-2025';
  static final recoveryNow = DateTime(2026, 5, 21, 10, 30);

  static Steward readySteward({
    required String pubkey,
    required String name,
    bool isOwner = false,
  }) {
    return createTestSteward(
      pubkey: pubkey,
      name: name,
      isOwner: isOwner,
      status: StewardStatus.holdingKey,
    ).copyWith(
      giftWrapEventId: 'gw-$name',
      acknowledgedDistributionVersion: 1,
    );
  }

  static BackupConfig readyBackupConfig({
    required String vaultId,
    required int threshold,
    required List<Steward> stewards,
    String? instructions,
  }) {
    return createBackupConfig(
      vaultId: vaultId,
      threshold: threshold,
      totalKeys: stewards.length,
      stewards: stewards,
      relays: const ['wss://relay.damus.io', 'wss://nos.lol'],
      instructions: instructions,
    ).copyWith(distributionVersion: 1);
  }

  static Share stewardShare({
    required String vaultId,
    required String vaultName,
    required String ownerPubkey,
    required String recipientPubkey,
    required String ownerName,
  }) {
    return createShare(
      payload: 'shard-payload-$vaultId',
      threshold: 2,
      shareIndex: 1,
      totalShares: 3,
      scheme: null,
      creatorPubkey: ownerPubkey,
      vaultId: vaultId,
      vaultName: vaultName,
      stewards: [
        {'name': ownerName, 'pubkey': ownerPubkey},
        {'name': 'Alex Rivera', 'pubkey': ownerPubkey},
      ],
      recipientPubkey: recipientPubkey,
      isReceived: true,
      receivedAt: DateTime(2025, 3, 12, 14, 30),
    );
  }

  static List<VaultDetail> vaultListDetails() {
    final familyBackup = readyBackupConfig(
      vaultId: familyVaultId,
      threshold: 2,
      stewards: [
        readySteward(pubkey: ownerPubkey, name: 'Alex Rivera', isOwner: true),
        readySteward(pubkey: marcusPubkey, name: 'Marcus Webb'),
        readySteward(pubkey: elenaPubkey, name: 'Elena Rodriguez'),
      ],
    );

    return [
      OwnedVaultDetail(
        id: familyVaultId,
        name: 'Family Passwords',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alex Rivera',
        threshold: familyBackup.threshold,
        totalShares: familyBackup.totalKeys,
        stewards: familyBackup.stewards,
        recoveryRequests: const [],
        pushEnabled: true,
        createdAt: DateTime(2025, 1, 8, 9, 15),
        archivedAt: null,
        archivedReason: null,
        backupConfig: familyBackup,
        content: 'encrypted-content-family',
        selfHeldShare: null,
      ),
      OwnedVaultDetail(
        id: estateVaultId,
        name: 'Estate Documents',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alex Rivera',
        threshold: 2,
        totalShares: 3,
        stewards: familyBackup.stewards,
        recoveryRequests: const [],
        pushEnabled: true,
        createdAt: DateTime(2024, 11, 22, 16, 45),
        archivedAt: null,
        archivedReason: null,
        backupConfig: familyBackup.copyWith(vaultId: estateVaultId),
        content: 'encrypted-content-estate',
        selfHeldShare: null,
      ),
      StewardedVaultDetail(
        id: marcusVaultId,
        name: "Marcus Webb's Digital Will",
        ownerPubkey: marcusPubkey,
        ownerName: 'Marcus Webb',
        threshold: 2,
        totalShares: 3,
        stewards: const [],
        recoveryRequests: const [],
        pushEnabled: false,
        createdAt: DateTime(2025, 2, 3, 11, 0),
        archivedAt: null,
        archivedReason: null,
        backupConfig: null,
        latestShare: stewardShare(
          vaultId: marcusVaultId,
          vaultName: "Marcus Webb's Digital Will",
          ownerPubkey: marcusPubkey,
          recipientPubkey: ownerPubkey,
          ownerName: 'Marcus Webb',
        ),
      ),
    ];
  }

  static List<Override> vaultListOverrides() {
    return [
      vaultDetailListProvider.overrideWith(
        (ref) => Stream.value(vaultListDetails()),
      ),
      currentPublicKeyProvider.overrideWith((ref) => ownerPubkey),
    ];
  }

  static List<Override> vaultDetailStewardOverrides() {
    final stewards = [
      readySteward(pubkey: ownerPubkey, name: 'Alex Rivera', isOwner: true),
      readySteward(pubkey: marcusPubkey, name: 'Marcus Webb'),
      readySteward(pubkey: elenaPubkey, name: 'Elena Rodriguez'),
    ];

    final marcusShare = createShare(
      payload: 'shard-payload-family',
      threshold: 2,
      shareIndex: 1,
      totalShares: 3,
      scheme: null,
      creatorPubkey: ownerPubkey,
      vaultId: familyVaultId,
      vaultName: 'Family Passwords',
      stewards: [
        {'name': 'Alex Rivera', 'pubkey': ownerPubkey},
        {'name': 'Marcus Webb', 'pubkey': marcusPubkey},
        {'name': 'Elena Rodriguez', 'pubkey': elenaPubkey},
      ],
      recipientPubkey: marcusPubkey,
      isReceived: true,
      receivedAt: DateTime(2025, 3, 12, 14, 30),
    );

    final stewardVault = Vault(
      id: familyVaultId,
      name: 'Family Passwords',
      createdAt: DateTime(2025, 1, 8, 9, 15),
      ownerPubkey: ownerPubkey,
      ownerName: 'Alex Rivera',
      recoveryRequests: const [],
      backupConfig: readyBackupConfig(
        vaultId: familyVaultId,
        threshold: 2,
        stewards: stewards,
      ),
    );

    return [
      vaultDetailProvider(familyVaultId).overrideWith(
        (ref) => Stream.value(
          stewardedVaultDetailFromVault(
            stewardVault,
            latestShare: marcusShare,
          ),
        ),
      ),
      currentPublicKeyProvider.overrideWith((ref) => marcusPubkey),
      recoveryStatusProvider.overrideWith(
        (ref, vaultId) => const AsyncValue.data(
          RecoveryStatus(
            hasActiveRecovery: false,
            canRecover: false,
            activeRecoveryRequest: null,
            isInitiator: false,
          ),
        ),
      ),
    ];
  }

  static List<Override> manageRecoveryOverrides() {
    final recoveryRequest = RecoveryRequest.makeFromParticipants(
      id: recoveryId,
      vaultId: familyVaultId,
      initiatorPubkey: ownerPubkey,
      requestedAt: recoveryNow.subtract(const Duration(hours: 2)),
      status: RecoveryRequestStatus.inProgress,
      threshold: 2,
      stewardPubkeys: [marcusPubkey, elenaPubkey, jamesPubkey],
      responses: [
        RecoveryResponse(
          pubkey: marcusPubkey,
          approved: true,
          respondedAt: recoveryNow.subtract(const Duration(minutes: 35)),
        ),
        const RecoveryResponse(
          pubkey: elenaPubkey,
          approved: false,
          respondedAt: null,
        ),
        const RecoveryResponse(
          pubkey: jamesPubkey,
          approved: false,
          respondedAt: null,
        ),
      ],
      isPractice: false,
    );

    final backupConfig = readyBackupConfig(
      vaultId: familyVaultId,
      threshold: 2,
      stewards: [
        readySteward(pubkey: ownerPubkey, name: 'Alex Rivera', isOwner: true),
        readySteward(pubkey: marcusPubkey, name: 'Marcus Webb'),
        readySteward(pubkey: elenaPubkey, name: 'Elena Rodriguez'),
        readySteward(pubkey: jamesPubkey, name: 'James Okonkwo'),
      ],
      instructions: 'Call me before approving any recovery. Ask for our shared passphrase.',
    );

    final vault = Vault(
      id: familyVaultId,
      name: 'Family Passwords',
      createdAt: DateTime(2025, 1, 8, 9, 15),
      ownerPubkey: ownerPubkey,
      ownerName: 'Alex Rivera',
      recoveryRequests: [recoveryRequest],
      backupConfig: backupConfig,
    );

    return [
      recoveryRequestByIdProvider(recoveryId).overrideWith(
        (ref) => AsyncValue.data(recoveryRequest),
      ),
      vaultDetailProvider(familyVaultId).overrideWith(
        (ref) => Stream.value(ownedVaultDetailFromVault(vault)),
      ),
      vaultProvider(familyVaultId).overrideWith(
        (ref) => Stream.value(vault),
      ),
      currentPublicKeyProvider.overrideWith(
        (ref) => Future.value(ownerPubkey),
      ),
    ];
  }
}
