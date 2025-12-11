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
      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => const AsyncValue.loading()),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
        waitForSettle: false,
      );

      await screenMatchesGoldenWithoutSettle<RecoveryMetadataWidget>(
        tester,
        'recovery_metadata_widget_loading',
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
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 200),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_error');

      container.dispose();
    });

    testGoldens('pending status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.pending,
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_pending');

      container.dispose();
    });

    testGoldens('in-progress status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.inProgress,
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_in_progress');

      container.dispose();
    });

    testGoldens('completed status', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.completed,
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_completed');

      container.dispose();
    });

    testGoldens('expired warning', (tester) async {
      final request = createTestRecoveryRequest(
        id: 'test-request',
        status: RecoveryRequestStatus.inProgress,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)), // Expired
      );

      final container = ProviderContainer(
        overrides: [
          recoveryRequestByIdProvider(
            'test-request',
          ).overrideWith((ref) => AsyncValue.data(request)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RecoveryMetadataWidget(recoveryRequestId: 'test-request'),
        container: container,
        surfaceSize: const Size(375, 250),
        useScaffold: true,
      );

      await screenMatchesGolden(tester, 'recovery_metadata_widget_expired');

      container.dispose();
    });
  });
}
