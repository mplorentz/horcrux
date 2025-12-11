import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/backup_status.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/screens/practice_recovery_info_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  group('PracticeRecoveryInfoScreen Golden Tests', () {
    const testVaultId = 'test-vault-id';
    final testPubkey = 'a' * 64; // 64-char hex pubkey

    testGoldens('shows practice recovery content for ready vault', (
      tester,
    ) async {
      // Create stewards with confirmed status
      final steward1 = createSteward(pubkey: 'b' * 64, name: 'Steward 1');
      final steward2 = createSteward(pubkey: 'c' * 64, name: 'Steward 2');
      final steward3 = createSteward(pubkey: 'd' * 64, name: 'Steward 3');

      // Update stewards to holdingKey status with acknowledgment
      final confirmedSteward1 = copySteward(
        steward1,
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime(2024, 1, 1),
        acknowledgedDistributionVersion: 1,
      );
      final confirmedSteward2 = copySteward(
        steward2,
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime(2024, 1, 1),
        acknowledgedDistributionVersion: 1,
      );
      final confirmedSteward3 = copySteward(
        steward3,
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime(2024, 1, 1),
        acknowledgedDistributionVersion: 1,
      );

      // Create backup config
      var backupConfig = createBackupConfig(
        vaultId: testVaultId,
        threshold: 2,
        totalKeys: 3,
        stewards: [confirmedSteward1, confirmedSteward2, confirmedSteward3],
        relays: ['wss://relay.example.com'],
      );

      // Update status to active and set lastRedistribution
      backupConfig = copyBackupConfig(
        backupConfig,
        status: BackupStatus.active,
        lastRedistribution: DateTime(2024, 1, 1),
        distributionVersion: 1,
      );

      // Create a vault with a ready recovery plan
      final vault = Vault(
        id: testVaultId,
        name: 'My Important Vault',
        content: 'secret content',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: testPubkey,
        backupConfig: backupConfig,
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(testVaultId).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const PracticeRecoveryInfoScreen(vaultId: testVaultId),
        container: container,
        surfaceSize: const Size(400, 1200),
      );

      await screenMatchesGolden(tester, 'practice_recovery_ready');

      container.dispose();
    });

    testGoldens('shows error when vault has no recovery plan', (tester) async {
      final vault = Vault(
        id: testVaultId,
        name: 'My Vault',
        content: 'secret content',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: testPubkey,
        backupConfig: null, // No recovery plan
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(testVaultId).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const PracticeRecoveryInfoScreen(vaultId: testVaultId),
        container: container,
        surfaceSize: const Size(400, 800),
      );

      await screenMatchesGolden(tester, 'practice_recovery_no_plan');

      container.dispose();
    });

    testGoldens('shows error when recovery plan is not ready', (tester) async {
      // Create stewards with awaiting key status (not confirmed yet)
      final steward1 = createSteward(pubkey: 'b' * 64, name: 'Steward 1');
      final steward2 = createSteward(pubkey: 'c' * 64, name: 'Steward 2');
      final steward3 = createSteward(pubkey: 'd' * 64, name: 'Steward 3');

      // Create backup config with pending status
      final backupConfig = createBackupConfig(
        vaultId: testVaultId,
        threshold: 2,
        totalKeys: 3,
        stewards: [steward1, steward2, steward3],
        relays: ['wss://relay.example.com'],
      );

      final vault = Vault(
        id: testVaultId,
        name: 'My Vault',
        content: 'secret content',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: testPubkey,
        backupConfig: backupConfig,
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(testVaultId).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const PracticeRecoveryInfoScreen(vaultId: testVaultId),
        container: container,
        surfaceSize: const Size(400, 800),
      );

      await screenMatchesGolden(tester, 'practice_recovery_not_ready');

      container.dispose();
    });

    testGoldens('shows error for non-owner', (tester) async {
      // Create stewards
      final steward1 = createSteward(pubkey: 'b' * 64, name: 'Steward 1');
      final steward2 = createSteward(pubkey: 'c' * 64, name: 'Steward 2');
      final steward3 = createSteward(pubkey: 'd' * 64, name: 'Steward 3');

      final backupConfig = createBackupConfig(
        vaultId: testVaultId,
        threshold: 2,
        totalKeys: 3,
        stewards: [steward1, steward2, steward3],
        relays: ['wss://relay.example.com'],
      );

      final vault = Vault(
        id: testVaultId,
        name: 'My Vault',
        content: 'secret content',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: testPubkey,
        backupConfig: backupConfig,
      );

      // User is not the owner
      const nonOwnerPubkey = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

      final container = ProviderContainer(
        overrides: [
          vaultProvider(testVaultId).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(nonOwnerPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const PracticeRecoveryInfoScreen(vaultId: testVaultId),
        container: container,
        surfaceSize: const Size(400, 800),
      );

      await screenMatchesGolden(tester, 'practice_recovery_non_owner');

      container.dispose();
    });

    testGoldens('shows practice recovery with different threshold (3 of 5)', (
      tester,
    ) async {
      // Create 5 stewards with confirmed status
      final steward1 = createSteward(pubkey: 'b' * 64, name: 'Steward 1');
      final steward2 = createSteward(pubkey: 'c' * 64, name: 'Steward 2');
      final steward3 = createSteward(pubkey: 'd' * 64, name: 'Steward 3');
      final steward4 = createSteward(pubkey: 'e' * 64, name: 'Steward 4');
      final steward5 = createSteward(pubkey: 'f' * 64, name: 'Steward 5');

      // Update stewards to holdingKey status with acknowledgment
      final confirmedSteward1 = copySteward(
        steward1,
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime(2024, 1, 1),
        acknowledgedDistributionVersion: 1,
      );
      final confirmedSteward2 = copySteward(
        steward2,
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime(2024, 1, 1),
        acknowledgedDistributionVersion: 1,
      );
      final confirmedSteward3 = copySteward(
        steward3,
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime(2024, 1, 1),
        acknowledgedDistributionVersion: 1,
      );
      final confirmedSteward4 = copySteward(
        steward4,
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime(2024, 1, 1),
        acknowledgedDistributionVersion: 1,
      );
      final confirmedSteward5 = copySteward(
        steward5,
        status: StewardStatus.holdingKey,
        acknowledgedAt: DateTime(2024, 1, 1),
        acknowledgedDistributionVersion: 1,
      );

      // Create backup config with 3 of 5 threshold
      var backupConfig = createBackupConfig(
        vaultId: testVaultId,
        threshold: 3,
        totalKeys: 5,
        stewards: [
          confirmedSteward1,
          confirmedSteward2,
          confirmedSteward3,
          confirmedSteward4,
          confirmedSteward5,
        ],
        relays: ['wss://relay.example.com'],
      );

      // Update status to active and set lastRedistribution
      backupConfig = copyBackupConfig(
        backupConfig,
        status: BackupStatus.active,
        lastRedistribution: DateTime(2024, 1, 1),
        distributionVersion: 1,
      );

      final vault = Vault(
        id: testVaultId,
        name: 'High Security Vault',
        content: 'top secret',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: testPubkey,
        backupConfig: backupConfig,
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(testVaultId).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const PracticeRecoveryInfoScreen(vaultId: testVaultId),
        container: container,
        surfaceSize: const Size(400, 1200),
      );

      await screenMatchesGolden(tester, 'practice_recovery_3_of_5');

      container.dispose();
    });
  });
}
