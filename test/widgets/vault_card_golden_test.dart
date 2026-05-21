import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/widgets/vault_card.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultCard Golden Tests', () {
    testGoldens('archived vault - deleted by owner', (tester) async {
      final vault = StewardedVaultDetail(
        id: 'test-vault',
        name: 'My Private Keys',
        ownerPubkey: 'a' * 64,
        ownerName: null,
        threshold: 2,
        totalShares: 2,
        stewards: const [],
        recoveryRequests: const [],
        pushEnabled: false,
        createdAt: DateTime(2024, 10, 1),
        archivedAt: DateTime(2024, 11, 1),
        archivedReason: 'Vault deleted',
        backupConfig: null,
        latestShare: null,
      );

      final harness = await pumpGoldenWidget(
        tester,
        VaultCard(vault: vault),
        surfaceSize: const Size(375, 100),
      );

      await screenMatchesGolden(tester, 'vault_card_archived_deleted');

      await harness.dispose();
    });

    testGoldens('archived vault - steward removed', (tester) async {
      final vault = StewardedVaultDetail(
        id: 'test-vault',
        name: 'My Private Keys',
        ownerPubkey: 'a' * 64,
        ownerName: null,
        threshold: 2,
        totalShares: 2,
        stewards: const [],
        recoveryRequests: const [],
        pushEnabled: false,
        createdAt: DateTime(2024, 10, 1),
        archivedAt: DateTime(2024, 11, 1),
        archivedReason: 'steward_removed',
        backupConfig: null,
        latestShare: null,
      );

      final harness = await pumpGoldenWidget(
        tester,
        VaultCard(vault: vault),
        surfaceSize: const Size(375, 100),
      );

      await screenMatchesGolden(tester, 'vault_card_archived_removed');

      await harness.dispose();
    });

    testGoldens('archived vault - null reason', (tester) async {
      final vault = StewardedVaultDetail(
        id: 'test-vault',
        name: 'My Private Keys',
        ownerPubkey: 'a' * 64,
        ownerName: null,
        threshold: 2,
        totalShares: 2,
        stewards: const [],
        recoveryRequests: const [],
        pushEnabled: false,
        createdAt: DateTime(2024, 10, 1),
        archivedAt: DateTime(2024, 11, 1),
        archivedReason: null,
        backupConfig: null,
        latestShare: null,
      );

      final harness = await pumpGoldenWidget(
        tester,
        VaultCard(vault: vault),
        surfaceSize: const Size(375, 100),
      );

      await screenMatchesGolden(tester, 'vault_card_archived_null_reason');

      await harness.dispose();
    });
  });
}