import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/widgets/steward_list.dart';
import 'dart:async';
import '../helpers/golden_test_helpers.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;
  final thirdPubkey = 'c' * 64;
  final fourthPubkey = 'd' * 64;

  // Helper to create shard data
  ShardData createTestShard({
    required int shardIndex,
    required String recipientPubkey,
    required String vaultId,
    String vaultName = 'Test Vault',
    int threshold = 2,
    List<Map<String, String>>? peers,
  }) {
    return createShardData(
      shard: 'test_shard_$shardIndex',
      threshold: threshold,
      shardIndex: shardIndex,
      totalShards: peers?.length ?? 3,
      primeMod: 'test_prime_mod',
      creatorPubkey: testPubkey,
      vaultId: vaultId,
      vaultName: vaultName,
      peers: peers ??
          [
            {'name': 'Peer 1', 'pubkey': otherPubkey},
            {'name': 'Peer 2', 'pubkey': thirdPubkey},
          ],
      recipientPubkey: recipientPubkey,
      isReceived: true,
      receivedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  // Helper to create vault
  Vault createTestVault({
    required String id,
    required String ownerPubkey,
    List<ShardData>? shards,
  }) {
    return Vault(
      id: id,
      name: 'Test Vault',
      content: null, // No decrypted content for steward state
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: ownerPubkey,
      shards: shards ?? [],
    );
  }

  group('StewardList Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(null)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value('test-pubkey'),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<StewardList>(
        tester,
        'steward_list_loading',
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.error('Failed to load vault')),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value('test-pubkey'),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_error');

      container.dispose();
    });

    testGoldens('empty state', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        shards: [], // No shards
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 300),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_empty');

      container.dispose();
    });

    testGoldens('single steward', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            vaultId: 'test-vault',
            peers: [
              {'name': 'Peer 1', 'pubkey': otherPubkey},
            ], // Only one peer
            threshold: 1, // Fix: threshold must be <= totalShards
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 300),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_single');

      container.dispose();
    });

    testGoldens('multiple stewards', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            vaultId: 'test-vault',
            peers: [
              {'name': 'Peer 1', 'pubkey': otherPubkey},
              {'name': 'Peer 2', 'pubkey': thirdPubkey},
              {'name': 'Peer 3', 'pubkey': fourthPubkey},
            ], // Multiple peers
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 400),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_multiple');

      container.dispose();
    });

    testGoldens('steward viewing list with owner in peers', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: otherPubkey, // Different owner
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: testPubkey, // Current user is recipient
            vaultId: 'test-vault',
            peers: [
              {'name': 'Peer 1', 'pubkey': otherPubkey},
              {'name': 'Peer 2', 'pubkey': thirdPubkey},
            ], // Owner is in peers
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 350),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_with_owner');

      container.dispose();
    });

    testGoldens('steward viewing list without owner in peers', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: fourthPubkey, // Owner not in peers
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: testPubkey, // Current user is recipient
            vaultId: 'test-vault',
            peers: [
              {'name': 'Peer 1', 'pubkey': otherPubkey},
              {'name': 'Peer 2', 'pubkey': thirdPubkey},
            ], // Owner not in peers
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 350),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'steward_list_without_owner');

      container.dispose();
    });

    testGoldens('current user key loading', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            vaultId: 'test-vault',
          ),
        ],
      );

      // Create a completer that never completes to simulate loading
      final completer = Completer<String?>();

      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) => completer.future),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const StewardList(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<StewardList>(
        tester,
        'steward_list_user_loading',
      );

      container.dispose();
    });
  });
}
