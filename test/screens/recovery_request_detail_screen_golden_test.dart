import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/recovery_request_detail_screen.dart';
import 'package:horcrux/services/login_service.dart';
import '../helpers/golden_test_helpers.dart';
import '../helpers/vault_detail_golden_fixtures.dart';

void main() {
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey (current user - steward)
  final initiatorPubkey = 'b' * 64; // Initiator of recovery
  final ownerPubkey = 'c' * 64; // Owner of the vault
  final otherStewardPubkey = 'd' * 64; // Another steward

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String vaultId,
    required String initiatorPubkey,
    RecoveryRequestStatus status = RecoveryRequestStatus.inProgress,
    Map<String, RecoveryResponse>? responses,
  }) {
    final responseMap = responses ?? <String, RecoveryResponse>{};
    return RecoveryRequest.makeFromParticipants(
      id: 'recovery-$vaultId',
      vaultId: vaultId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: status,
      threshold: 2,
      stewardPubkeys: responseMap.keys,
      responses: responseMap.values,
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

  // Helper to create vault with backup config
  Vault createTestVault({
    required String id,
    required String name,
    required String ownerPubkey,
    String? ownerName,
    String? instructions,
    List<Steward>? stewards,
  }) {
    final defaultStewards = [
      createSteward(pubkey: initiatorPubkey, name: 'Alice'),
      createSteward(pubkey: testPubkey, name: 'Bob'),
      createSteward(pubkey: otherStewardPubkey, name: 'Charlie'),
    ];

    return Vault(
      id: id,
      name: name,
      createdAt: DateTime(2024, 10, 1, 10, 30),
      ownerPubkey: ownerPubkey,
      ownerName: ownerName,
      backupConfig: createBackupConfig(
        vaultId: id,
        threshold: 2,
        totalKeys: (stewards ?? defaultStewards).length,
        stewards: stewards ?? defaultStewards,
        relays: ['wss://relay.example.com'],
        instructions: instructions,
      ),
    );
  }

  group('RecoveryRequestDetailScreen Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          // Mock the vault provider to return loading state
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(null).asyncMap((_) async {
              await Future.delayed(
                const Duration(seconds: 10),
              ); // Never completes to simulate loading
              return null;
            }),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],

        surfaceSize: const Size(375, 1200),
        waitForSettle: false, // Loading state has infinite animations
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_loading',
      );

      await harness.dispose();
    });

    testGoldens('error state', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          // Mock provider to throw an error
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.error('Failed to load vault')),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(tester, 'recovery_request_detail_screen_error');

      await harness.dispose();
    });

    testGoldens('active request with instructions', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        status: RecoveryRequestStatus.inProgress,
        responses: {
          otherStewardPubkey: createTestRecoveryResponse(
            pubkey: otherStewardPubkey,
            approved: true,
          ),
        },
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions:
            'Please verify the requester\'s identity before approving. Contact me at alice@example.com if you have any questions.',
        stewards: [
          createSteward(
            pubkey: initiatorPubkey,
            name: 'Alice',
            contactInfo: 'Email: alice@example.com\nPhone: +1 (555) 123-4567\nSignal: alice.signal',
          ),
          createSteward(pubkey: testPubkey, name: 'Bob'),
          createSteward(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_active_with_instructions',
      );

      await harness.dispose();
    });

    testGoldens('active request without instructions', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        status: RecoveryRequestStatus.inProgress,
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: null, // No instructions
        stewards: [
          createSteward(pubkey: initiatorPubkey, name: 'Alice'),
          createSteward(pubkey: testPubkey, name: 'Bob'),
          createSteward(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_active_no_instructions',
      );

      await harness.dispose();
    });

    testGoldens('request with unknown initiator', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: 'x' * 64, // Unknown pubkey
        status: RecoveryRequestStatus.inProgress,
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: 'Please verify identity before approving.',
        stewards: [
          createSteward(pubkey: testPubkey, name: 'Bob'),
          createSteward(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_unknown_initiator',
      );

      await harness.dispose();
    });

    testGoldens('completed request (no action buttons)', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        status: RecoveryRequestStatus.completed,
        responses: {
          testPubkey: createTestRecoveryResponse(
            pubkey: testPubkey,
            approved: true,
          ),
          otherStewardPubkey: createTestRecoveryResponse(
            pubkey: otherStewardPubkey,
            approved: true,
          ),
        },
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: 'Recovery completed successfully.',
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_completed',
      );

      await harness.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        status: RecoveryRequestStatus.inProgress,
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: 'Please verify the requester\'s identity before approving.',
      );

      final harness = GoldenTestHarness.withOverrides([
        loginServiceProvider.overrideWithValue(
          _GoldenFakeLoginService(testPubkey),
        ),
        vaultDetailProvider(
          'test-vault',
        ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
        currentPublicKeyProvider.overrideWith((ref) => testPubkey),
      ]);

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
          name: 'active_request',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: harness.container,
        ),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_multiple_devices',
      );

      await harness.dispose();
    });

    testGoldens('practice recovery request - pending', (tester) async {
      final recoveryRequest = RecoveryRequest.makeFromParticipants(
        id: 'recovery-practice',
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: RecoveryRequestStatus.pending,
        threshold: 2,
        stewardPubkeys: [testPubkey, otherStewardPubkey],
        responses: [
          RecoveryResponse(pubkey: testPubkey, approved: false),
          RecoveryResponse(pubkey: otherStewardPubkey, approved: false),
        ],
        isPractice: true, // Practice recovery
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: 'This is a practice recovery - stewards should respond to test the process.',
        stewards: [
          createSteward(pubkey: initiatorPubkey, name: 'Alice'),
          createSteward(pubkey: testPubkey, name: 'Bob'),
          createSteward(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_practice_pending',
      );

      await harness.dispose();
    });

    testGoldens('practice recovery request - in progress with responses', (
      tester,
    ) async {
      final recoveryRequest = RecoveryRequest.makeFromParticipants(
        id: 'recovery-practice',
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: [testPubkey, otherStewardPubkey],
        responses: [
          RecoveryResponse(pubkey: testPubkey, approved: false),
          RecoveryResponse(
            pubkey: otherStewardPubkey,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        isPractice: true, // Practice recovery
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: 'This is a practice recovery - no real data will be shared.',
        stewards: [
          createSteward(pubkey: initiatorPubkey, name: 'Alice'),
          createSteward(pubkey: testPubkey, name: 'Bob'),
          createSteward(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_practice_in_progress',
      );

      await harness.dispose();
    });

    testGoldens('practice recovery request - completed', (tester) async {
      final recoveryRequest = RecoveryRequest.makeFromParticipants(
        id: 'recovery-practice',
        vaultId: 'test-vault',
        initiatorPubkey: initiatorPubkey,
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: RecoveryRequestStatus.completed,
        threshold: 2,
        stewardPubkeys: [testPubkey, otherStewardPubkey],
        responses: [
          RecoveryResponse(
            pubkey: testPubkey,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 45)),
          ),
          RecoveryResponse(
            pubkey: otherStewardPubkey,
            approved: true,
            respondedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        isPractice: true, // Practice recovery
      );

      final vault = createTestVault(
        id: 'test-vault',
        name: 'My Important Vault',
        ownerPubkey: ownerPubkey,
        ownerName: 'Alice',
        instructions: 'Practice recovery completed successfully!',
        stewards: [
          createSteward(pubkey: initiatorPubkey, name: 'Alice'),
          createSteward(pubkey: testPubkey, name: 'Bob'),
          createSteward(pubkey: otherStewardPubkey, name: 'Charlie'),
        ],
      );

      final harness = await pumpGoldenWidget(
        tester,
        RecoveryRequestDetailScreen(recoveryRequest: recoveryRequest),
        overrides: [
          loginServiceProvider.overrideWithValue(
            _GoldenFakeLoginService(testPubkey),
          ),
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.value(ownedVaultDetailFromVault(vault))),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'recovery_request_detail_screen_practice_completed',
      );

      await harness.dispose();
    });
  });
}

class _GoldenFakeLoginService extends LoginService {
  _GoldenFakeLoginService(this._pubkey);

  final String _pubkey;

  @override
  Future<String?> getCurrentPublicKey() async => _pubkey;
}
