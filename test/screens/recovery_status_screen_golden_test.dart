import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/backup_status.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/screens/recovery_status_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey (current user)
  final initiatorPubkey = 'b' * 64;
  final steward1Pubkey = 'c' * 64;
  final steward2Pubkey = 'd' * 64;

  // Helper to create steward (manually because createSteward doesn't accept status)
  Steward createTestSteward({
    required String pubkey,
    String? name,
    StewardStatus status = StewardStatus.holdingKey,
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
      acknowledgedAt: DateTime.now().subtract(const Duration(hours: 1)),
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
    String? instructions,
  }) {
    return (
      vaultId: vaultId,
      specVersion: '1.0.0',
      threshold: threshold,
      totalKeys: totalKeys,
      stewards: stewards,
      relays: ['wss://relay.example.com'],
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
      content: null,
      createdAt: DateTime(2024, 10, 1, 10, 30),
      ownerPubkey: ownerPubkey,
      backupConfig: backupConfig,
    );
  }

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String id,
    required String vaultId,
    required String initiatorPubkey,
    required int threshold,
    RecoveryRequestStatus status = RecoveryRequestStatus.inProgress,
    Map<String, RecoveryResponse>? responses,
    bool isPractice = false,
  }) {
    return RecoveryRequest(
      id: id,
      vaultId: vaultId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: status,
      threshold: threshold,
      stewardResponses: responses ?? {},
      isPractice: isPractice,
    );
  }

  // Helper to create recovery response
  RecoveryResponse createTestRecoveryResponse({
    required String pubkey,
    required bool approved,
    DateTime? respondedAt,
  }) {
    return RecoveryResponse(
      pubkey: pubkey,
      approved: approved,
      respondedAt: respondedAt ?? DateTime.now().subtract(const Duration(minutes: 30)),
    );
  }

  group('RecoveryStatusScreen Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('recovery-123').overrideWith(
            (ref) => const AsyncValue.loading(),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryStatusScreen(recoveryRequestId: 'recovery-123'),
        container: container,
        surfaceSize: const Size(375, 1200),
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<RecoveryStatusScreen>(
        tester,
        'recovery_status_loading',
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('recovery-123').overrideWith(
            (ref) => const AsyncValue.error(
              'Failed to load recovery request',
              StackTrace.empty,
            ),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryStatusScreen(recoveryRequestId: 'recovery-123'),
        container: container,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'recovery_status_error');

      container.dispose();
    });

    testGoldens('recovery request not found', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('recovery-123')
              .overrideWith((ref) => const AsyncValue.data(null)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryStatusScreen(recoveryRequestId: 'recovery-123'),
        container: container,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'recovery_status_not_found');

      container.dispose();
    });

    testGoldens('practice recovery - pending with no responses', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        id: 'recovery-123',
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        threshold: 2,
        status: RecoveryRequestStatus.pending,
        responses: {
          testPubkey: RecoveryResponse(pubkey: testPubkey, approved: false),
          steward1Pubkey: RecoveryResponse(pubkey: steward1Pubkey, approved: false),
          steward2Pubkey: RecoveryResponse(pubkey: steward2Pubkey, approved: false),
        },
        isPractice: true,
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: initiatorPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(pubkey: testPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Charlie'),
          ],
          instructions: 'Please verify identity before approving.',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('recovery-123')
              .overrideWith((ref) => AsyncValue.data(recoveryRequest)),
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryStatusScreen(recoveryRequestId: 'recovery-123'),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(tester, 'recovery_status_practice_pending');

      container.dispose();
    });

    testGoldens('practice recovery - in progress with partial responses', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        id: 'recovery-123',
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        threshold: 2,
        status: RecoveryRequestStatus.inProgress,
        responses: {
          testPubkey: createTestRecoveryResponse(pubkey: testPubkey, approved: true),
          steward1Pubkey: RecoveryResponse(pubkey: steward1Pubkey, approved: false),
          steward2Pubkey: RecoveryResponse(pubkey: steward2Pubkey, approved: false),
        },
        isPractice: true,
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: initiatorPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(pubkey: testPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Charlie'),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('recovery-123')
              .overrideWith((ref) => AsyncValue.data(recoveryRequest)),
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryStatusScreen(recoveryRequestId: 'recovery-123'),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(tester, 'recovery_status_practice_in_progress');

      container.dispose();
    });

    testGoldens('practice recovery - completed', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        id: 'recovery-123',
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        threshold: 2,
        status: RecoveryRequestStatus.completed,
        responses: {
          testPubkey: createTestRecoveryResponse(pubkey: testPubkey, approved: true),
          steward1Pubkey: createTestRecoveryResponse(pubkey: steward1Pubkey, approved: true),
          steward2Pubkey: RecoveryResponse(pubkey: steward2Pubkey, approved: false),
        },
        isPractice: true,
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: initiatorPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createTestSteward(pubkey: testPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
            createTestSteward(pubkey: steward2Pubkey, name: 'Charlie'),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('recovery-123')
              .overrideWith((ref) => AsyncValue.data(recoveryRequest)),
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryStatusScreen(recoveryRequestId: 'recovery-123'),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(tester, 'recovery_status_practice_completed');

      container.dispose();
    });

    testGoldens('real recovery - in progress', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        id: 'recovery-123',
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        threshold: 2,
        status: RecoveryRequestStatus.inProgress,
        responses: {
          testPubkey: createTestRecoveryResponse(pubkey: testPubkey, approved: true),
          steward1Pubkey: RecoveryResponse(pubkey: steward1Pubkey, approved: false),
        },
        isPractice: false, // Real recovery
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: initiatorPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 2,
          stewards: [
            createTestSteward(pubkey: testPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('recovery-123')
              .overrideWith((ref) => AsyncValue.data(recoveryRequest)),
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryStatusScreen(recoveryRequestId: 'recovery-123'),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(tester, 'recovery_status_real_in_progress');

      container.dispose();
    });

    testGoldens('multiple device sizes - practice', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        id: 'recovery-123',
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        threshold: 2,
        status: RecoveryRequestStatus.inProgress,
        responses: {
          testPubkey: createTestRecoveryResponse(pubkey: testPubkey, approved: true),
          steward1Pubkey: RecoveryResponse(pubkey: steward1Pubkey, approved: false),
        },
        isPractice: true,
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: initiatorPubkey,
        backupConfig: createTestBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 2,
          stewards: [
            createTestSteward(pubkey: testPubkey, name: 'Bob'),
            createTestSteward(pubkey: steward1Pubkey, name: 'Alice'),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('recovery-123')
              .overrideWith((ref) => AsyncValue.data(recoveryRequest)),
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const RecoveryStatusScreen(recoveryRequestId: 'recovery-123'),
          name: 'practice_in_progress',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(tester, 'recovery_status_multiple_devices');

      container.dispose();
    });
  });
}
