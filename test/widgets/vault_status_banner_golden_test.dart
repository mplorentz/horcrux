import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/backup_status.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/shard_data.dart';
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

  // Helper to create vault
  Vault createTestVault({
    required String id,
    required String ownerPubkey,
    String? content,
    List<ShardData>? shards,
    BackupConfig? backupConfig,
    List<RecoveryRequest>? recoveryRequests,
  }) {
    return Vault(
      id: id,
      name: 'Test Vault',
      content: content,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: ownerPubkey,
      shards: shards ?? [],
      backupConfig: backupConfig,
      recoveryRequests: recoveryRequests ?? [],
    );
  }

  // Helper to create backup config
  BackupConfig createTestBackupConfig({
    required String vaultId,
    required int threshold,
    required int totalKeys,
    required List<Steward> stewards,
    List<String>? relays,
    BackupStatus status = BackupStatus.pending,
    DateTime? lastRedistribution,
    int distributionVersion = 0,
  }) {
    return (
      vaultId: vaultId,
      specVersion: '1.0.0',
      threshold: threshold,
      totalKeys: totalKeys,
      stewards: stewards,
      relays: relays ?? ['wss://relay.example.com'],
      instructions: null,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      lastContentChange: null,
      lastRedistribution: lastRedistribution,
      contentHash: null,
      status: status,
      distributionVersion: distributionVersion,
    );
  }

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String vaultId,
    required String initiatorPubkey,
    RecoveryRequestStatus status = RecoveryRequestStatus.inProgress,
    int threshold = 2,
  }) {
    return RecoveryRequest(
      id: 'recovery-$vaultId',
      vaultId: vaultId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: status,
      threshold: threshold,
      stewardResponses: {},
    );
  }

  group('VaultStatusBanner Golden Tests', () {
    group('Owner States', () {
      testGoldens('no recovery plan', (tester) async {
        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          content: 'Decrypted content',
          backupConfig: null, // No backup config
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(ownerPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_no_plan',
        );

        container.dispose();
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
          content: 'Decrypted content',
          backupConfig: invalidConfig,
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(ownerPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_plan_needs_attention',
        );

        container.dispose();
      });

      testGoldens('plan needs attention - inactive', (tester) async {
        final inactiveConfig = createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          status: BackupStatus.inactive,
          stewards: [
            createTestSteward(pubkey: stewardPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Charlie'),
            createTestSteward(pubkey: steward3Pubkey, name: 'Diana'),
          ],
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          content: 'Decrypted content',
          backupConfig: inactiveConfig,
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(ownerPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_plan_needs_attention_inactive',
        );

        container.dispose();
      });

      testGoldens('waiting for stewards to join - pending invitations', (tester) async {
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
          content: 'Decrypted content',
          backupConfig: config,
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(ownerPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_waiting_stewards_join',
        );

        container.dispose();
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
          content: 'Decrypted content',
          backupConfig: config,
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(ownerPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_keys_not_distributed',
        );

        container.dispose();
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
            ), // Not yet acknowledged
          ],
        );

        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          content: 'Decrypted content',
          backupConfig: config,
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(ownerPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_almost_ready',
        );

        container.dispose();
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
          content: 'Decrypted content',
          backupConfig: config,
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(ownerPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_owner_ready',
        );

        container.dispose();
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
          content: 'Decrypted content',
          recoveryRequests: [recoveryRequest],
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(ownerPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_recovery_in_progress',
        );

        container.dispose();
      });
    });

    group('Steward States', () {
      testGoldens('steward awaiting key state', (tester) async {
        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          content: null, // No decrypted content
          shards: [], // No shards - this triggers awaitingKey state
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(stewardPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_steward_awaiting_key',
        );

        container.dispose();
      });

      testGoldens('steward ready to help', (tester) async {
        final shard = createShardData(
          shard: 'test-shard-data',
          threshold: 2,
          shardIndex: 0,
          totalShards: 3,
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
          content: null, // No decrypted content
          shards: [shard], // Has shard - steward ready
        );

        final container = ProviderContainer(
          overrides: [
            currentPublicKeyProvider.overrideWith((ref) => Future.value(stewardPubkey)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_steward_ready',
        );

        container.dispose();
      });
    });

    group('Unknown State', () {
      testGoldens('unknown status - neither owner nor steward', (tester) async {
        final vault = createTestVault(
          id: 'test-vault',
          ownerPubkey: ownerPubkey,
          content: null,
          shards: [],
        );

        final container = ProviderContainer(
          overrides: [
            // Current user is neither owner nor steward (different pubkey)
            currentPublicKeyProvider.overrideWith((ref) => Future.value('x' * 64)),
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
        );

        await pumpGoldenWidget(
          tester,
          VaultStatusBanner(vault: vault),
          container: container,
          surfaceSize: const Size(375, 150),
          useScaffold: true,
        );

        await screenMatchesGolden(
          tester,
          'vault_status_banner_unknown',
        );

        container.dispose();
      });
    });
  });
}
