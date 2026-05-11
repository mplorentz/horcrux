import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/widgets/vault_metadata_section.dart';
import '../helpers/golden_test_helpers.dart';
import '../helpers/vault_detail_golden_fixtures.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;

  // Helper to create vault
  Vault createTestVault({required String id, required String ownerPubkey}) {
    return Vault(
      id: id,
      name: 'Test Vault',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: ownerPubkey,
    );
  }

  group('VaultMetadataSection Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultMetadataSection(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(null)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value('test-pubkey'),
          ),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<VaultMetadataSection>(
        tester,
        'vault_metadata_section_loading',
      );

      await harness.dispose();
    });

    testGoldens('error state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultMetadataSection(vaultId: 'test-vault'),
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

      await screenMatchesGolden(tester, 'vault_metadata_section_error');

      await harness.dispose();
    });

    testGoldens('owner state', (tester) async {
      final vault = createTestVault(id: 'test-vault', ownerPubkey: testPubkey);

      final harness = await pumpGoldenWidget(
        tester,
        const VaultMetadataSection(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(vault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'vault_metadata_section_owner');

      await harness.dispose();
    });

    testGoldens('steward state', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: otherPubkey, // Different owner
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultMetadataSection(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(
              stewardedVaultDetailFromVault(
                vault,
                latestShare: createShare(
                  payload: 'shard',
                  threshold: 3,
                  shareIndex: 0,
                  totalShares: 3,
                  primeMod: 'pm',
                  creatorPubkey: otherPubkey,
                  vaultId: 'test-vault',
                  vaultName: 'Test Vault',
                  recipientPubkey: testPubkey,
                  isReceived: true,
                  receivedAt: DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
            ),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'vault_metadata_section_key_holder');

      await harness.dispose();
    });

    testGoldens('steward state with no shards', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        ownerPubkey: otherPubkey, // Different owner // No shards
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultMetadataSection(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(
              stewardedVaultDetailFromVault(vault, latestShare: null),
            ),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(
        tester,
        'vault_metadata_section_key_holder_no_shards',
      );

      await harness.dispose();
    });

    testGoldens('current user key loading', (tester) async {
      final vault = createTestVault(id: 'test-vault', ownerPubkey: otherPubkey);

      final harness = await pumpGoldenWidget(
        tester,
        const VaultMetadataSection(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(
              stewardedVaultDetailFromVault(
                vault,
                latestShare: createShare(
                  payload: 'shard',
                  threshold: 2,
                  shareIndex: 0,
                  totalShares: 3,
                  primeMod: 'pm',
                  creatorPubkey: otherPubkey,
                  vaultId: 'test-vault',
                  vaultName: 'Test Vault',
                  recipientPubkey: testPubkey,
                  isReceived: true,
                  receivedAt: DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
            ),
          ),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future<String?>.delayed(
              const Duration(seconds: 10),
              () => testPubkey,
            ),
          ),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGolden(tester, 'vault_metadata_section_user_loading');

      await harness.dispose();
    });
  });
}
