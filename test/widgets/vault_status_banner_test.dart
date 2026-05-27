import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/widgets/vault_status_banner.dart';

/// Non-golden behavioural tests for [VaultStatusBanner]. These cover the
/// per-user manageable-recovery resolution introduced for multi-initiator
/// support: the banner must render off the *current user's* own request, not
/// off `recoveryStatusProvider`'s most-recent representative (which can
/// belong to another initiator under per-user exclusivity).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final me = 'a' * 64;
  final other = 'b' * 64;

  VaultDetail buildVault({
    required List<RecoveryRequest> requests,
    String? ownerPubkey,
  }) {
    return OwnedVaultDetail(
      id: 'vault-1',
      name: 'Test Vault',
      ownerPubkey: ownerPubkey ?? me,
      ownerName: null,
      threshold: 0,
      totalShares: 0,
      stewards: const [],
      recoveryRequests: requests,
      pushEnabled: true,
      createdAt: DateTime(2024, 1, 1),
      archivedAt: null,
      archivedReason: null,
      backupConfig: null,
      content: 'plaintext',
      selfHeldShare: null,
    );
  }

  VaultDetail buildStewardVault({Share? latestShare, String? ownerPubkey}) {
    return StewardedVaultDetail(
      id: 'vault-1',
      name: 'Test Vault',
      ownerPubkey: ownerPubkey ?? other,
      ownerName: null,
      threshold: latestShare?.threshold ?? 2,
      totalShares: latestShare?.totalShares ?? 3,
      stewards: const [],
      recoveryRequests: const [],
      pushEnabled: true,
      createdAt: DateTime(2024, 1, 1),
      archivedAt: null,
      archivedReason: null,
      backupConfig: null,
      latestShare: latestShare,
    );
  }

  Future<void> pumpBanner(
    WidgetTester tester,
    ProviderContainer container,
    VaultDetail vault,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: VaultStatusBanner(vault: vault)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows "Recovery in progress" for current user even when another initiator '
    'has a newer active recovery on the same vault',
    (tester) async {
      // Multi-initiator: `recoveryStatusProvider` would surface the newer
      // request from `other`, with `isInitiator: false` for `me`. The banner
      // must still render off `me`'s own active request.
      final mine = RecoveryRequest(
        id: 'mine',
        vaultId: 'vault-1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 10),
        status: RecoveryRequestStatus.inProgress,
        threshold: 1,
      );
      final theirs = RecoveryRequest(
        id: 'theirs',
        vaultId: 'vault-1',
        initiatorPubkey: other,
        requestedAt: DateTime(2024, 1, 1, 12),
        status: RecoveryRequestStatus.inProgress,
        threshold: 1,
      );
      final vault = buildVault(requests: [mine, theirs]);

      final container = ProviderContainer(
        overrides: [
          currentPublicKeyProvider.overrideWith((ref) async => me),
          // Mirror the real provider: most-recent regardless of initiator.
          // The banner should NOT read this; this override exists only to
          // pin down behavior if a regression re-introduces the dependency.
          recoveryStatusProvider.overrideWith((ref, vaultId) {
            return AsyncValue.data(
              RecoveryStatus(
                hasActiveRecovery: true,
                canRecover: false,
                activeRecoveryRequest: theirs,
                isInitiator: false,
              ),
            );
          }),
        ],
      );

      await pumpBanner(tester, container, vault);

      expect(find.text('Recovery in progress'), findsOneWidget);
      expect(find.text('Tap to manage recovery'), findsOneWidget);

      container.dispose();
    },
  );

  testWidgets(
    'renders the banner when the current user\'s recovery is completed',
    (tester) async {
      // Once enough stewards approve, the request transitions to `completed`
      // but is still manageable (the user finalizes recovery from the same
      // screen). The banner must keep rendering through that transition.
      final mineCompleted = RecoveryRequest(
        id: 'mine-completed',
        vaultId: 'vault-1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 10),
        status: RecoveryRequestStatus.completed,
        threshold: 1,
      );
      final vault = buildVault(requests: [mineCompleted]);

      final container = ProviderContainer(
        overrides: [currentPublicKeyProvider.overrideWith((ref) async => me)],
      );

      await pumpBanner(tester, container, vault);

      expect(find.text('Recovery in progress'), findsOneWidget);

      container.dispose();
    },
  );

  testWidgets(
    'does not render the banner when only OTHER initiators have active recoveries',
    (tester) async {
      // When the current user has no manageable recovery of their own, the
      // banner must fall through to the normal status display rather than
      // attribute someone else's session to them.
      final theirs = RecoveryRequest(
        id: 'theirs',
        vaultId: 'vault-1',
        initiatorPubkey: other,
        requestedAt: DateTime(2024, 1, 1, 12),
        status: RecoveryRequestStatus.inProgress,
        threshold: 1,
      );
      final vault = buildVault(requests: [theirs]);

      final container = ProviderContainer(
        overrides: [currentPublicKeyProvider.overrideWith((ref) async => me)],
      );

      await pumpBanner(tester, container, vault);

      expect(find.text('Recovery in progress'), findsNothing);
      expect(find.text('Practice recovery in progress'), findsNothing);

      container.dispose();
    },
  );

  testWidgets(
    'shows "Practice recovery in progress" when current user\'s session is practice',
    (tester) async {
      final practice = RecoveryRequest(
        id: 'mine-practice',
        vaultId: 'vault-1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 10),
        status: RecoveryRequestStatus.inProgress,
        threshold: 1,
        isPractice: true,
      );
      final vault = buildVault(requests: [practice]);

      final container = ProviderContainer(
        overrides: [currentPublicKeyProvider.overrideWith((ref) async => me)],
      );

      await pumpBanner(tester, container, vault);

      expect(find.text('Practice recovery in progress'), findsOneWidget);

      container.dispose();
    },
  );

  testWidgets(
    'shows unknown status for non-owner viewing owner-style vault detail',
    (tester) async {
      final vault = buildVault(requests: const [], ownerPubkey: other);
      final container = ProviderContainer(
        overrides: [currentPublicKeyProvider.overrideWith((ref) async => me)],
      );

      await pumpBanner(tester, container, vault);

      expect(find.text('Recovery status unavailable'), findsOneWidget);
      expect(find.text('You are a steward'), findsNothing);
      expect(find.text('This is a bug.'), findsNothing);

      container.dispose();
    },
  );

  testWidgets(
    'shows steward waiting banner for steward vault with no share yet',
    (tester) async {
      final vault = buildStewardVault(latestShare: null);
      final container = ProviderContainer(
        overrides: [currentPublicKeyProvider.overrideWith((ref) async => me)],
      );

      await pumpBanner(tester, container, vault);

      expect(find.text('Waiting for your key'), findsOneWidget);

      container.dispose();
    },
  );

  testWidgets(
    'shows steward ready banner for steward vault with received share',
    (tester) async {
      final share = Share(
        payload: 'share-payload',
        threshold: 3,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: other,
        createdAt: DateTime(2024, 1, 1).millisecondsSinceEpoch ~/ 1000,
        vaultId: 'vault-1',
        recipientPubkey: me,
        isReceived: true,
        receivedAt: DateTime(2024, 1, 1),
      );
      final vault = buildStewardVault(latestShare: share);
      final container = ProviderContainer(
        overrides: [currentPublicKeyProvider.overrideWith((ref) async => me)],
      );

      await pumpBanner(tester, container, vault);

      expect(find.text('You\'re ready to help'), findsOneWidget);

      container.dispose();
    },
  );
}
