import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/widgets/vault_metadata_section.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;
  final thirdPubkey = 'c' * 64;

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
      totalShards: 3,
      primeMod: 'test_prime_mod',
      creatorPubkey: testPubkey,
      vaultId: vaultId,
      vaultName: vaultName,
      peers:
          peers ??
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

  group('VaultMetadataSection Golden Tests', () {
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
        const VaultMetadataSection(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<VaultMetadataSection>(
        tester,
        'vault_metadata_section_loading',
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
        const VaultMetadataSection(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'vault_metadata_section_error');

      container.dispose();
    });

    testGoldens('owner state', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: testPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: otherPubkey,
            vaultId: 'test-vault',
            threshold: 2,
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
        const VaultMetadataSection(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'vault_metadata_section_owner');

      container.dispose();
    });

    testGoldens('steward state', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: otherPubkey, // Different owner
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: testPubkey, // Current user is recipient
            vaultId: 'test-vault',
            threshold: 3,
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
        const VaultMetadataSection(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'vault_metadata_section_key_holder');

      container.dispose();
    });

    testGoldens('steward state with no shards', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: otherPubkey, // Different owner
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
        const VaultMetadataSection(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(
        tester,
        'vault_metadata_section_key_holder_no_shards',
      );

      container.dispose();
    });

    testGoldens('current user key loading', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: otherPubkey,
        shards: [
          createTestShard(
            shardIndex: 0,
            recipientPubkey: testPubkey,
            vaultId: 'test-vault',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future<String?>.delayed(
              const Duration(seconds: 10),
              () => testPubkey,
            ),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const VaultMetadataSection(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGolden(tester, 'vault_metadata_section_user_loading');

      container.dispose();
    });
  });
}
