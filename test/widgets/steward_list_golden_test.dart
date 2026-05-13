import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/widgets/steward_list.dart';
import 'dart:async';
import '../helpers/golden_test_helpers.dart';
import '../helpers/vault_detail_golden_fixtures.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;
  final thirdPubkey = 'c' * 64;
  final fourthPubkey = 'd' * 64;

  // Helper to create shard data
  Share createTestShard({
    required int shardIndex,
    required String recipientPubkey,
    required String vaultId,
    String vaultName = 'Test Vault',
    int threshold = 2,
    List<Map<String, String>>? stewards,
  }) {
    return createShare(
      payload: 'test_shard_$shardIndex',
      threshold: threshold,
      shareIndex: shardIndex,
      totalShares: stewards?.length ?? 3,
      primeMod: 'test_prime_mod',
      creatorPubkey: testPubkey,
      vaultId: vaultId,
      vaultName: vaultName,
      stewards: stewards ??
          [
            {'name': 'Peer 1', 'pubkey': otherPubkey},
            {'name': 'Peer 2', 'pubkey': thirdPubkey},
          ],
      recipientPubkey: recipientPubkey,
      isReceived: true,
      receivedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  // Helper to create vault (Phase 2c: no content/shares on Vault)
  Vault createTestVault({
    required String id,
    required String ownerPubkey,
    String? ownerName,
    BackupConfig? backupConfig,
    List<dynamic>? shares, // ignored; use vaultDetailProvider override for share data
  }) {
    return Vault(
      id: id,
      name: 'Test Vault',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: ownerPubkey,
      ownerName: ownerName,
      backupConfig: backupConfig,
    );
  }

  group('StewardList Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith((ref) => Stream.value(null)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value('test-pubkey'),
          ),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<StewardList>(
        tester,
        'steward_list_loading',
      );

      await harness.dispose();
    });

    testGoldens('error state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.error('Failed to load vault')),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value('test-pubkey'),
          ),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_error');

      await harness.dispose();
    });

    testGoldens('empty state', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        shares: [], // No shards
      );

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(vault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 300),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_empty');

      await harness.dispose();
    });

    testGoldens('single steward', (tester) async {
      final steward = createSteward(pubkey: otherPubkey, name: 'Peer 1').copyWith(
        status: StewardStatus.holdingKey,
      );
      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: ['wss://relay.example.com'],
      );
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        backupConfig: backupConfig,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 300),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_single');

      await harness.dispose();
    });

    testGoldens('multiple stewards', (tester) async {
      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        totalKeys: 3,
        stewards: [
          createSteward(pubkey: otherPubkey, name: 'Peer 1').copyWith(
            status: StewardStatus.holdingKey,
          ),
          createSteward(pubkey: thirdPubkey, name: 'Peer 2').copyWith(
            status: StewardStatus.holdingKey,
          ),
          createSteward(pubkey: fourthPubkey, name: 'Peer 3').copyWith(
            status: StewardStatus.holdingKey,
          ),
        ],
        relays: ['wss://relay.example.com'],
      );
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        backupConfig: backupConfig,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 400),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_multiple');

      await harness.dispose();
    });

    testGoldens('steward viewing list with owner in peers', (tester) async {
      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        totalKeys: 2,
        stewards: [
          createOwnerSteward(pubkey: otherPubkey, name: 'Peer 1').copyWith(
            status: StewardStatus.holdingKey,
          ),
          createSteward(pubkey: thirdPubkey, name: 'Peer 2').copyWith(
            status: StewardStatus.holdingKey,
          ),
        ],
        relays: ['wss://relay.example.com'],
      );
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: otherPubkey, // Different owner
        ownerName: 'Peer 1',
        backupConfig: backupConfig,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 350),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_with_owner');

      await harness.dispose();
    });

    testGoldens('steward viewing list without owner in peers', (tester) async {
      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        totalKeys: 2,
        stewards: [
          createSteward(pubkey: otherPubkey, name: 'Peer 1').copyWith(
            status: StewardStatus.holdingKey,
          ),
          createSteward(pubkey: thirdPubkey, name: 'Peer 2').copyWith(
            status: StewardStatus.holdingKey,
          ),
        ],
        relays: ['wss://relay.example.com'],
      );
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: fourthPubkey, // Owner not in peers
        backupConfig: backupConfig,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 350),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_without_owner');

      await harness.dispose();
    });

    testGoldens('current user key loading', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        shares: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            vaultId: 'test-vault',
          ),
        ],
      );

      // Create a completer that never completes to simulate loading
      final completer = Completer<String?>();

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(vault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => completer.future),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<StewardList>(
        tester,
        'steward_list_user_loading',
      );

      await harness.dispose();
    });

    testGoldens('owner as steward appears in list (backupConfig path)', (tester) async {
      final ownerPubkey = testPubkey;
      final stewardPubkeyB = otherPubkey;
      final stewardPubkeyC = thirdPubkey;

      // Create owner steward with holdingKey status (is a steward)
      final ownerSteward = createOwnerSteward(pubkey: ownerPubkey, name: 'Device A').copyWith(
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime.now().subtract(const Duration(hours: 1)),
        acknowledgedDistributionVersion: 1,
      );

      // Create regular stewards
      final stewardB = createSteward(pubkey: stewardPubkeyB, name: 'Device B').copyWith(
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime.now().subtract(const Duration(hours: 1)),
        acknowledgedDistributionVersion: 1,
      );

      final stewardC = createSteward(pubkey: stewardPubkeyC, name: 'Device C').copyWith(
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime.now().subtract(const Duration(hours: 1)),
        acknowledgedDistributionVersion: 1,
      );

      // Create backup config with owner as steward
      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        totalKeys: 3,
        stewards: [ownerSteward, stewardB, stewardC],
        relays: ['wss://relay.example.com'],
      ).copyWith(distributionVersion: 1);

      final vault = Vault(
        id: 'test-vault',
        name: 'Test Vault',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ownerPubkey: ownerPubkey,
        ownerName: 'Device A',
        backupConfig: backupConfig,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(vault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => stewardPubkeyC),
        ],
        surfaceSize: const Size(375, 400),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_owner_as_steward_backup_config');

      await harness.dispose();
    });

    testGoldens('owner not as steward excluded from list', (tester) async {
      final ownerPubkey = testPubkey;
      final stewardPubkeyB = otherPubkey;
      final stewardPubkeyC = thirdPubkey;

      // Create owner steward with awaitingKey status (NOT a steward yet)
      final ownerSteward = createOwnerSteward(pubkey: ownerPubkey, name: 'Device A').copyWith(
        status: StewardStatus.awaitingKey, // Not holding a key
      );

      // Create regular stewards
      final stewardB = createSteward(pubkey: stewardPubkeyB, name: 'Device B').copyWith(
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime.now().subtract(const Duration(hours: 1)),
        acknowledgedDistributionVersion: 1,
      );

      final stewardC = createSteward(pubkey: stewardPubkeyC, name: 'Device C').copyWith(
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime.now().subtract(const Duration(hours: 1)),
        acknowledgedDistributionVersion: 1,
      );

      // Create backup config with owner NOT as steward
      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        totalKeys: 3,
        stewards: [ownerSteward, stewardB, stewardC],
        relays: ['wss://relay.example.com'],
      ).copyWith(distributionVersion: 1);

      final vault = Vault(
        id: 'test-vault',
        name: 'Test Vault',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ownerPubkey: ownerPubkey,
        ownerName: 'Device A',
        backupConfig: backupConfig,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(vault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => stewardPubkeyC),
        ],
        surfaceSize: const Size(375, 350),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_owner_not_steward');

      await harness.dispose();
    });

    testGoldens('owner in normalized stewards appears in list', (tester) async {
      final ownerPubkey = testPubkey;
      final stewardPubkeyB = otherPubkey;
      final stewardPubkeyC = thirdPubkey;
      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        totalKeys: 3,
        stewards: [
          createOwnerSteward(pubkey: ownerPubkey, name: 'Device A').copyWith(
            status: StewardStatus.holdingKey,
          ),
          createSteward(pubkey: stewardPubkeyB, name: 'Device B').copyWith(
            status: StewardStatus.holdingKey,
          ),
          createSteward(pubkey: stewardPubkeyC, name: 'Device C').copyWith(
            status: StewardStatus.holdingKey,
          ),
        ],
        relays: ['wss://relay.example.com'],
      );

      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Device A',
        backupConfig: backupConfig,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(vault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => stewardPubkeyC),
        ],
        surfaceSize: const Size(375, 400),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_owner_as_steward_backup_config');

      await harness.dispose();
    });
  });
}
