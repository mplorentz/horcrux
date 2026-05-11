import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/widgets/recovery_metadata_widget.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String id,
    RecoveryRequestStatus status = RecoveryRequestStatus.pending,
    DateTime? requestedAt,
    DateTime? expiresAt,
    int threshold = 2,
  }) {
    return RecoveryRequest(
      id: id,
      vaultId: 'test-vault',
      initiatorPubkey: testPubkey,
      requestedAt: requestedAt ?? DateTime.now().subtract(const Duration(hours: 1)),
      status: status,
      threshold: threshold,
      expiresAt: expiresAt,
    );
  }

  group('RecoveryMetadataWidget Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => const AsyncValue.loading()),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<RecoveryMetadataWidget>(
        tester,
        'recovery_metadata_widget_loading',
      );

      await harness.dispose();
    });

    testGoldens('error state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider('test-request').overrideWith(
            (ref) => const AsyncValue.error(
              'Failed to load recovery request',
              StackTrace.empty,
            ),
          ),
        ],
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_error');

      await harness.dispose();
    });

    testGoldens('pending status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.pending,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
        ],
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_pending');

      await harness.dispose();
    });

    testGoldens('in-progress status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.inProgress,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
        ],
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_in_progress');

      await harness.dispose();
    });

    testGoldens('completed status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.completed,
      );

      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
        ],
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_completed');

      await harness.dispose();
    });

    testGoldens('expired warning', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.inProgress,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)), // Expired
      );

      final harness = await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
        ],
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_expired');

      await harness.dispose();
    });
  });
}
