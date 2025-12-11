import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/widgets/recovery_progress_widget.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  // Sample test data
  final testPubkey1 = 'a' * 64;
  final testPubkey2 = 'b' * 64;
  final testPubkey3 = 'c' * 64;

  // Helper to create vault
  Vault createTestVault({
    required String id,
    required List<String> stewardPubkeys,
  }) {
    return Vault(
      id: id,
      name: 'Test Vault',
      content: 'test content',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: testPubkey1,
      backupConfig: createBackupConfig(
        vaultId: id,
        threshold: 2,
        totalKeys: stewardPubkeys.length,
        stewards: stewardPubkeys.map((pubkey) => createSteward(pubkey: pubkey)).toList(),
        relays: ['wss://relay.example.com'],
      ),
    );
  }

  group('RecoveryProgressWidget Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => const AsyncValue.loading()),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 300),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<RecoveryProgressWidget>(
        tester,
        'recovery_progress_widget_loading',
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => const AsyncValue.error(
              'Failed to load recovery request',
              StackTrace.empty,
            ),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 300),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_progress_widget_error');

      container.dispose();
    });

    testGoldens('low progress without button', (tester) async {
      final request = RecoveryRequest(
        id: 'test-request',
        vaultId: 'test-vault',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardResponses: {
          testPubkey2: RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        },
      );

      final vault = createTestVault(
        id: 'test-vault',
        stewardPubkeys: [testPubkey2, testPubkey3, testPubkey1],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 400),
        useScaffold: true,
      );

      await screenMatchesGolden(
        tester,
        'recovery_progress_widget_low_progress',
      );

      container.dispose();
    });

    testGoldens('threshold met with button', (tester) async {
      final request = RecoveryRequest(
        id: 'test-request',
        vaultId: 'test-vault',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardResponses: {
          testPubkey2: RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          testPubkey3: RecoveryResponse(
            pubkey: testPubkey3,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
        },
      );

      final vault = createTestVault(
        id: 'test-vault',
        stewardPubkeys: [testPubkey2, testPubkey3, testPubkey1],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 500),
        useScaffold: true,
      );

      await screenMatchesGolden(
        tester,
        'recovery_progress_widget_threshold_met',
      );

      container.dispose();
    });

    testGoldens('completed state', (tester) async {
      final request = RecoveryRequest(
        id: 'test-request',
        vaultId: 'test-vault',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardResponses: {
          testPubkey2: RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          testPubkey3: RecoveryResponse(
            pubkey: testPubkey3,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        },
      );

      final vault = createTestVault(
        id: 'test-vault',
        stewardPubkeys: [testPubkey2, testPubkey3, testPubkey1],
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 500),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_progress_widget_completed');

      container.dispose();
    });
  });
}
