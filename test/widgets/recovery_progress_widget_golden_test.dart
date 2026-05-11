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
    required List<(String pubkey, String? name, String? contactInfo)> stewards,
  }) {
    return Vault(
      id: id,
      name: 'Test Vault',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: testPubkey1,
      backupConfig: createBackupConfig(
        vaultId: id,
        threshold: 2,
        totalKeys: stewards.length,
        stewards: stewards.map((steward) {
          return createSteward(
            pubkey: steward.$1,
            name: steward.$2,
            contactInfo: steward.$3,
          );
        }).toList(),
        relays: ['wss://relay.example.com'],
      ),
    );
  }

  group('RecoveryProgressWidget Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => const AsyncValue.loading()),
        ],
        surfaceSize: const Size(375, 300),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<RecoveryProgressWidget>(
        tester,
        'recovery_progress_widget_loading',
      );

      await harness.dispose();
    });

    testGoldens('error state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => const AsyncValue.error(
              'Failed to load recovery request',
              StackTrace.empty,
            ),
          ),
        ],
        surfaceSize: const Size(375, 300),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_progress_widget_error');

      await harness.dispose();
    });

    testGoldens('low progress without button', (tester) async {
      final request = RecoveryRequest.makeFromParticipants(
        id: 'test-request',
        vaultId: 'test-vault',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: [testPubkey2],
        responses: [
          RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      );

      final vault = createTestVault(
        id: 'test-vault',
        stewards: [
          (testPubkey2, 'Alice', 'alice@example.com'),
          (testPubkey3, 'Bob', 'bob@example.com'),
          (testPubkey1, 'Charlie', 'charlie@example.com'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
        ],
        surfaceSize: const Size(375, 400),
        useScaffold: true,
      );

      await screenMatchesGolden(
        tester,
        'recovery_progress_widget_low_progress',
      );

      await harness.dispose();
    });

    testGoldens('threshold met with button', (tester) async {
      final request = RecoveryRequest.makeFromParticipants(
        id: 'test-request',
        vaultId: 'test-vault',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: [testPubkey2, testPubkey3],
        responses: [
          RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          RecoveryResponse(
            pubkey: testPubkey3,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
        ],
      );

      final vault = createTestVault(
        id: 'test-vault',
        stewards: [
          (testPubkey2, 'Alice', 'alice@example.com'),
          (testPubkey3, 'Bob', 'bob@example.com'),
          (testPubkey1, 'Charlie', 'charlie@example.com'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
        ],
        surfaceSize: const Size(375, 500),
        useScaffold: true,
      );

      await screenMatchesGolden(
        tester,
        'recovery_progress_widget_threshold_met',
      );

      await harness.dispose();
    });

    testGoldens('completed state', (tester) async {
      final request = RecoveryRequest.makeFromParticipants(
        id: 'test-request',
        vaultId: 'test-vault',
        initiatorPubkey: testPubkey1,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: [testPubkey2, testPubkey3],
        responses: [
          RecoveryResponse(
            pubkey: testPubkey2,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          RecoveryResponse(
            pubkey: testPubkey3,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      );

      final vault = createTestVault(
        id: 'test-vault',
        stewards: [
          (testPubkey2, 'Alice', 'alice@example.com'),
          (testPubkey3, 'Bob', 'bob@example.com'),
          (testPubkey1, 'Charlie', 'charlie@example.com'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryProgressWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
          vaultProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(vault)),
        ],
        surfaceSize: const Size(375, 500),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_progress_widget_completed');

      await harness.dispose();
    });
  });
}
