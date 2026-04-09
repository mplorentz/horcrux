import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/invitation_link.dart';
import 'package:horcrux/models/invitation_status.dart';
import 'package:horcrux/providers/invitation_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/invitation_acceptance_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final ownerPubkey = 'b' * 64;
  final inviteePubkey = 'c' * 64;

  // Helper to create invitation links
  InvitationLink createTestInvitation({
    required String inviteCode,
    required InvitationStatus status,
    String? inviteeName,
    String? ownerName,
    List<String>? relayUrls,
    String? redeemedBy,
    DateTime? redeemedAt,
  }) {
    return (
      inviteCode: inviteCode,
      vaultId: 'vault-123',
      vaultName: 'My Shared Vault',
      ownerPubkey: ownerPubkey,
      ownerName: ownerName,
      relayUrls: relayUrls ?? ['wss://relay.example.com'],
      inviteeName: inviteeName,
      createdAt: DateTime(2024, 10, 1, 10, 30),
      status: status,
      redeemedBy: redeemedBy,
      redeemedAt: redeemedAt,
    );
  }

  group('InvitationAcceptanceScreen Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Use a Stream that never emits to show loading state
          invitationByCodeProvider('test-code').overrideWith(
            (ref) => Stream<InvitationLink?>.multi((controller) {
              // Never emit, keeping the stream in loading state
              // Don't await anything - just return without emitting
            }),
          ),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'test-code'),
        container: container,
        waitForSettle: false, // Loading state
      );

      await screenMatchesGoldenWithoutSettle<InvitationAcceptanceScreen>(
        tester,
        'invitation_acceptance_screen_loading',
      );

      container.dispose();
    });

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'test-code',
          ).overrideWith((ref) => Stream.error('Failed to load invitation')),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'test-code'),
        container: container,
      );

      await screenMatchesGolden(tester, 'invitation_acceptance_screen_error');

      container.dispose();
    });

    testGoldens('invitation not found', (tester) async {
      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'invalid-code',
          ).overrideWith((ref) => Stream.value(null)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'invalid-code'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_not_found',
      );

      container.dispose();
    });

    testGoldens('active invitation - logged in user', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'active-code',
        status: InvitationStatus.pending,
        inviteeName: 'Alice',
        ownerName: 'Bob',
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'active-code',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'active-code'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_active_logged_in',
      );

      container.dispose();
    });

    testGoldens('active invitation - no invitee name', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'active-code-2',
        status: InvitationStatus.created,
        inviteeName: null,
        ownerName: 'Bob',
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'active-code-2',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'active-code-2'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_active_no_name',
      );

      container.dispose();
    });

    testGoldens('active invitation - multiple relays', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'active-code-3',
        status: InvitationStatus.pending,
        inviteeName: 'Bob',
        ownerName: 'Bob',
        relayUrls: [
          'wss://relay1.example.com',
          'wss://relay2.example.com',
          'wss://relay3.example.com',
        ],
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'active-code-3',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'active-code-3'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_active_multiple_relays',
      );

      container.dispose();
    });

    testGoldens('active invitation - not logged in', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'active-code-4',
        status: InvitationStatus.pending,
        inviteeName: 'Charlie',
        ownerName: 'Bob',
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'active-code-4',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith((ref) => Future.value(null)),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'active-code-4'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_active_not_logged_in',
      );

      container.dispose();
    });

    testGoldens('active invitation - checking account', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'active-code-5',
        status: InvitationStatus.pending,
        inviteeName: 'Diana',
        ownerName: 'Bob',
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'active-code-5',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith((ref) {
            // Use a Completer that never completes to simulate loading state
            final completer = Completer<String?>();
            return completer.future; // This will never complete
          }),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'active-code-5'),
        container: container,
        waitForSettle: false, // Loading state
      );

      await screenMatchesGoldenWithoutSettle<InvitationAcceptanceScreen>(
        tester,
        'invitation_acceptance_screen_active_checking_account',
      );

      container.dispose();
    });

    testGoldens('active invitation - account check error', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'active-code-6',
        status: InvitationStatus.pending,
        inviteeName: 'Eve',
        ownerName: 'Bob',
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'active-code-6',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.error('Failed to check account'),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'active-code-6'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_active_account_error',
      );

      container.dispose();
    });

    testGoldens('redeemed invitation', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'redeemed-code',
        status: InvitationStatus.redeemed,
        inviteeName: 'Frank',
        ownerName: 'Bob',
        redeemedBy: inviteePubkey,
        redeemedAt: DateTime(2024, 10, 1, 11, 0),
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'redeemed-code',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'redeemed-code'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_redeemed',
      );

      container.dispose();
    });

    testGoldens('denied invitation', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'denied-code',
        status: InvitationStatus.denied,
        inviteeName: 'Grace',
        ownerName: 'Bob',
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'denied-code',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'denied-code'),
        container: container,
      );

      await screenMatchesGolden(tester, 'invitation_acceptance_screen_denied');

      container.dispose();
    });

    testGoldens('invalidated invitation', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'invalidated-code',
        status: InvitationStatus.invalidated,
        inviteeName: 'Henry',
        ownerName: 'Bob',
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'invalidated-code',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'invalidated-code'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_invalidated',
      );

      container.dispose();
    });

    testGoldens('error status invitation', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'error-code',
        status: InvitationStatus.error,
        inviteeName: 'Iris',
        ownerName: 'Bob',
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'error-code',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const InvitationAcceptanceScreen(inviteCode: 'error-code'),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_error_status',
      );

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final invitation = createTestInvitation(
        inviteCode: 'device-test-code',
        status: InvitationStatus.pending,
        inviteeName: 'Jane',
        ownerName: 'Bob',
        relayUrls: ['wss://relay1.example.com', 'wss://relay2.example.com'],
      );

      final container = ProviderContainer(
        overrides: [
          invitationByCodeProvider(
            'device-test-code',
          ).overrideWith((ref) => Stream.value(invitation)),
          currentPublicKeyProvider.overrideWith(
            (ref) => Future.value(testPubkey),
          ),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const InvitationAcceptanceScreen(
            inviteCode: 'device-test-code',
          ),
          name: 'active_invitation',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(
        tester,
        'invitation_acceptance_screen_multiple_devices',
      );

      container.dispose();
    });
  });
}
