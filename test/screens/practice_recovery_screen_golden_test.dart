import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/backup_status.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/practice_recovery_info_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey (current user - owner)
  final steward1Pubkey = 'b' * 64;
  final steward2Pubkey = 'c' * 64;
  final steward3Pubkey = 'd' * 64;

  // Helper to create steward (manually because createSteward doesn't accept status)
  Steward createTestSteward({
    required String pubkey,
    String? name,
    StewardStatus status = StewardStatus.holdingKey,
    DateTime? acknowledgedAt,
  }) {
    return (
      id: pubkey.substring(0, 16),
      pubkey: pubkey,
      name: name,
      inviteCode: null,
      status: status,
      lastSeen: null,
      keyShare: null,
      giftWrapEventId: null,
      acknowledgedAt:
          acknowledgedAt ?? DateTime.now().subtract(const Duration(hours: 1)),
      acknowledgmentEventId: null,
      acknowledgedDistributionVersion: 1,
      isOwner: false,
    );
  }

  // Helper to create backup config (manually for full control)
  BackupConfig createTestBackupConfig({
    required String vaultId,
    required int threshold,
    required int totalKeys,
    required List<Steward> stewards,
    List<String>? relays,
    String? instructions,
  }) {
    return (
      vaultId: vaultId,
      specVersion: '1.0.0',
      threshold: threshold,
      totalKeys: totalKeys,
      stewards: stewards,
      relays: relays ?? ['wss://relay.example.com'],
      instructions: instructions,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      lastContentChange: null,
      lastRedistribution: null,
      contentHash: null,
      status: BackupStatus.active,
      distributionVersion: 1,
    );
  }

  // Helper to create vault
  Vault createTestVault({
    required String id,
    required String name,
    required String ownerPubkey,
    BackupConfig? backupConfig,
  }) {
    return Vault(
      id: id,
      name: name,
      content: 'Test vault content',
      createdAt: DateTime(2024, 10, 1, 10, 30),
      ownerPubkey: ownerPubkey,
      backupConfig: backupConfig,
    );
  }

  group('PracticeRecoveryInfoScreen Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultProvider('test-vault').overrideWith(
            (ref) => Stream.value(null).asyncMap((_) async {
              await Future.delayed(const Duration(seconds: 10));
              return null;
            }),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 2000),
        waitForSettle: false,
      );

      await screenMatchesGolden(tester, 'practice_recovery_loading');

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.error('Failed to load vault')),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'practice_recovery_error');

      container.dispose();
    });

    testGoldens('vault not found', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(null)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'practice_recovery_vault_not_found');

      container.dispose();
    });

    testGoldens('not owner - permission denied', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: 'x' * 64, // Different owner
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Bob'),
            createTestSteward(pubkey: steward3Pubkey, name: 'Charlie'),
          ],
        ),
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
        const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'practice_recovery_not_owner');

      container.dispose();
    });

    testGoldens('no recovery plan', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: testPubkey,
        backupConfig: null, // No backup config
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
        const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 2000),
      );

      await screenMatchesGolden(tester, 'practice_recovery_no_plan_detail');

      container.dispose();
    });

    testGoldens('ready with 3 of 5 threshold', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: testPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 3,
          totalKeys: 5,
          stewards: [
            createTestSteward(pubkey: testPubkey, name: 'Owner (You)'),
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Bob'),
            createTestSteward(pubkey: steward3Pubkey, name: 'Charlie'),
            createTestSteward(pubkey: 'e' * 64, name: 'Dave'),
          ],
        ),
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
        const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 2500),
      );

      await screenMatchesGolden(tester, 'practice_recovery_3_of_5_full');

      container.dispose();
    });

    testGoldens('ready with 2 of 3 threshold and instructions', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: testPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(pubkey: testPubkey, name: 'Owner (You)'),
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Bob'),
          ],
          instructions:
              'Please verify the requester\'s identity before approving. Contact me at owner@example.com if you have any questions.',
        ),
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
        const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 2500),
      );

      await screenMatchesGolden(tester, 'practice_recovery_with_instructions');

      container.dispose();
    });

    testGoldens('stewards not ready - waiting for confirmations', (
      tester,
    ) async {
      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: testPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(
              pubkey: testPubkey,
              name: 'Owner (You)',
              status: StewardStatus.awaitingKey,
              acknowledgedAt: null,
            ),
            createTestSteward(
              pubkey: steward1Pubkey,
              name: 'Alice',
              status: StewardStatus.awaitingKey,
              acknowledgedAt: null,
            ),
            createTestSteward(
              pubkey: steward2Pubkey,
              name: 'Bob',
              status: StewardStatus.holdingKey,
            ),
          ],
        ),
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
        const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 2000),
      );

      await screenMatchesGolden(tester, 'practice_recovery_not_ready_detail');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: testPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(pubkey: testPubkey, name: 'Owner (You)'),
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Bob'),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const PracticeRecoveryInfoScreen(vaultId: 'test-vault'),
          name: 'ready_state',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(tester, 'practice_recovery_multiple_devices');

      container.dispose();
    });
  });
}
