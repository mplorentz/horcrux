import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/backup_status.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/widgets/vault_status_banner.dart';
import '../fixtures/test_keys.dart';
import '../helpers/golden_test_helpers.dart';
import '../helpers/steward_test_helpers.dart';

void main() {
  // Use test fixtures for pubkeys
  const ownerPubkey = TestHexPubkeys.alice; // Owner
  const stewardPubkey = TestHexPubkeys.bob; // Steward
  const steward2Pubkey = TestHexPubkeys.charlie; // Another steward
  const steward3Pubkey = TestHexPubkeys.diana; // Another steward

  // Helper to create vault detail (defaults to OwnedVaultDetail).
  VaultDetail createTestVault({
    required String id,
    required String ownerPubkey,
    String? content,
    Share? latestShare,
    List<Share>? shares,
    BackupConfig? backupConfig,
    List<RecoveryRequest>? recoveryRequests,
  }) {
    final theContent = content ?? '';
    final stewardLatestShare =
        latestShare ?? (shares != null && shares.isNotEmpty ? shares.first : null);

    // Explicitly construct steward fixtures when `shares` or `latestShare`
    // are provided so awaiting/ready scenarios stay role-correct.
    if (latestShare != null || shares != null) {
      return StewardedVaultDetail(
        id: id,
        name: 'Test Vault',
        ownerPubkey: ownerPubkey,
        ownerName: null,
        threshold: backupConfig?.threshold ?? stewardLatestShare?.threshold ?? 0,
        totalShares: backupConfig?.totalKeys ?? stewardLatestShare?.totalShares ?? 0,
        stewards: const [],
        recoveryRequests: recoveryRequests ?? const [],
        pushEnabled: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        archivedAt: null,
        archivedReason: null,
        backupConfig: backupConfig,
        latestShare: stewardLatestShare,
      );
    }

    // OwnedVaultDetail when content is non-empty.
    if (latestShare == null && content != null && content.isNotEmpty) {
      return OwnedVaultDetail(
        id: id,
        name: 'Test Vault',
        ownerPubkey: ownerPubkey,
        ownerName: null,
        threshold: backupConfig?.threshold ?? 0,
        totalShares: backupConfig?.totalKeys ?? 0,
        stewards: const [],
        recoveryRequests: recoveryRequests ?? const [],
        pushEnabled: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        archivedAt: null,
        archivedReason: null,
        backupConfig: backupConfig,
        content: theContent,
        selfHeldShare: null,
      );
    }

    // Default: OwnedVaultDetail with empty content.
    return OwnedVaultDetail(
      id: id,
      name: 'Test Vault',
      ownerPubkey: ownerPubkey,
      ownerName: null,
      threshold: backupConfig?.threshold ?? 0,
      totalShares: backupConfig?.totalKeys ?? 0,
      stewards: const [],
      recoveryRequests: recoveryRequests ?? const [],
      pushEnabled: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      archivedAt: null,
      archivedReason: null,
      backupConfig: backupConfig,
      content: '',
      selfHeldShare: null,
    );
  }

  // Helper to create backup config
  BackupConfig createTestBackupConfig({
    required String vaultId,
    required int threshold,
    required int totalKeys,
    required List<Steward> stewards,
    List<String>? relays,

    /// Retained for fixture readability only; there is no persisted field.
    ///
    /// [BackupStatus.active] implies `distributionVersion >= 1` when the caller
    /// leaves [distributionVersion] at 0 (matches Phase 1 `hasBeenDistributed`).
    BackupStatus status = BackupStatus.pending,
    DateTime? lastRedistribution,
    int distributionVersion = 0,
  }) {
    var dv = distributionVersion;
    if (lastRedistribution != null && dv == 0) {
      dv = 1;
    }
    if (status == BackupStatus.active && dv == 0) {
      dv = 1;
    }
    return BackupConfig(
      vaultId: vaultId,
      threshold: threshold,
      stewards: stewards,
      relays: relays ?? const ['wss://relay.example.com'],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      distributionVersion: dv,
    );
  }

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String vaultId,
    required String initiatorPubkey,
    RecoveryRequestStatus status = RecoveryRequestStatus.inProgress,
    int threshold = 2,
  }) {
    return RecoveryRequest.makeFromParticipants(
      id: 'recovery-$vaultId',
      vaultId: vaultId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: status,
      threshold: threshold,
      stewardPubkeys: const [],
    );
  }

  group('VaultStatusBanner Golden Tests', () {
    group('Owner States', () {
      testGoldens('no recovery plan', (tester) async {
        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          backupConfig: null, // No backup config
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(ownerPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(tester, 'vault_status_banner_owner_no_plan');

        await harness.dispose();
      });

      testGoldens('plan needs attention - invalid', (tester) async {
        // Invalid config: threshold > totalKeys
        final invalidConfig = createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 3,
          totalKeys: 2, // Invalid!
          stewards: [
            createTestSteward(pubkey: stewardPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Charlie'),
          ],
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          backupConfig: invalidConfig,
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(ownerPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_plan_needs_attention',
        );

        await harness.dispose();
      });

      testGoldens('plan needs attention - inactive', (tester) async {
        // Legacy `BackupStatus.inactive` is gone from [BackupConfig]. The banner used
        // to treat inactive like an invalid plan (same red "needs attention" tile).
        // Model that here with a relay list that fails validation.
        final inactiveConfig = createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(pubkey: stewardPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Charlie'),
            createTestSteward(pubkey: steward3Pubkey, name: 'Diana'),
          ],
          relays: const ['https://wrong-scheme.example'],
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          backupConfig: inactiveConfig,
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(ownerPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_plan_needs_attention_inactive',
        );

        await harness.dispose();
      });

      testGoldens('waiting for stewards to join - pending invitations', (
        tester,
      ) async {
        final config = createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(
              pubkey: stewardPubkey,
              name: 'Bob',
              status: StewardStatus.holdingKey,
            ),
            createTestInvitedSteward(
              name: 'Charlie',
              inviteCode: 'invite-123',
            ), // Invited but not accepted
            createTestInvitedSteward(
              name: 'Diana',
              inviteCode: 'invite-456',
            ), // Invited but not accepted
          ],
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          backupConfig: config,
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(ownerPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_waiting_stewards_join',
        );

        await harness.dispose();
      });

      testGoldens('keys not distributed', (tester) async {
        final config = createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          status: BackupStatus.pending,
          stewards: [
            createTestSteward(pubkey: stewardPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Charlie'),
            createTestSteward(pubkey: steward3Pubkey, name: 'Diana'),
          ],
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          backupConfig: config,
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(ownerPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_keys_not_distributed',
        );

        await harness.dispose();
      });

      testGoldens('almost ready - waiting for confirmations', (tester) async {
        final config = createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 3,
          totalKeys: 3,
          status: BackupStatus.active,
          stewards: [
            createTestSteward(
              pubkey: stewardPubkey,
              name: 'Bob',
              status: StewardStatus.holdingKey,
            ), // Acknowledged
            createTestSteward(
              pubkey: steward2Pubkey,
              name: 'Charlie',
              status: StewardStatus.holdingKey,
            ), // Acknowledged
            createTestSteward(
              pubkey: steward3Pubkey,
              name: 'Diana',
              status: StewardStatus.awaitingKey,
            ).copyWith(
              giftWrapEventId: 'fixture-gw-event',
            ), // Shard sent; awaiting acknowledgment
          ],
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          backupConfig: config,
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(ownerPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_almost_ready',
        );

        await harness.dispose();
      });

      testGoldens('ready for recovery', (tester) async {
        final config = createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          status: BackupStatus.active,
          stewards: [
            createTestSteward(
              pubkey: stewardPubkey,
              name: 'Bob',
              status: StewardStatus.holdingKey,
            ),
            createTestSteward(
              pubkey: steward2Pubkey,
              name: 'Charlie',
              status: StewardStatus.holdingKey,
            ),
            createTestSteward(
              pubkey: steward3Pubkey,
              name: 'Diana',
              status: StewardStatus.holdingKey,
            ),
          ],
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          backupConfig: config,
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(ownerPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(tester, 'vault_status_banner_owner_ready');

        await harness.dispose();
      });

      testGoldens('recovery in progress', (tester) async {
        final recoveryRequest = createTestRecoveryRequest(
          vaultId: 'test-vault',
          initiatorPubkey: ownerPubkey,
          status: RecoveryRequestStatus.inProgress,
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          recoveryRequests: [recoveryRequest],
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(ownerPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: true,
                  canRecover: false,
                  activeRecoveryRequest: recoveryRequest,
                  isInitiator: true, // Owner is initiator
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_recovery_in_progress',
        );

        await harness.dispose();
      });
    });

    group('Steward States', () {
      testGoldens('steward awaiting key state', (tester) async {
        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          shares: [], // No shards - this triggers awaitingKey state
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(stewardPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_steward_awaiting_key',
        );

        await harness.dispose();
      });

      testGoldens('steward ready to help', (tester) async {
        final shard = createShare(
          payload: 'test-shard-data',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          primeMod: 'test-prime-mod',
          creatorPubkey: ownerPubkey,
          vaultId: 'test-vault',
          vaultName: 'Test Vault',
          stewards: [
            {'name': 'Bob', 'pubkey': stewardPubkey},
            {'name': 'Charlie', 'pubkey': steward2Pubkey},
          ],
          recipientPubkey: stewardPubkey,
          isReceived: true,
          receivedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          shares: [shard], // Has shard - steward ready
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value(stewardPubkey),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(tester, 'vault_status_banner_steward_ready');

        await harness.dispose();
      });
    });

    group('Unknown State', () {
      testGoldens('unknown status - neither owner nor steward', (tester) async {
        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          // Keep this legacy golden slot mapped to the "steward awaiting key"
          // visual until macOS golden refresh can split it into a dedicated
          // unknown-state snapshot.
          shares: const [],
        );

        final harness = await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          overrides: [
            // Current user is neither owner nor steward (different pubkey)
            currentPublicKeyProvider.overrideWith(
              (ref) => Future.value('x' * 64),
            ),
            recoveryStatusProvider('test-vault').overrideWith(
              (ref) => const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
                  isInitiator: false,
                ),
              ),
            ),
          ],
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(tester, 'vault_status_banner_unknown');

        await harness.dispose();
      });
    });
  });
}
