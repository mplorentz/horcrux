import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/local_notification_service.dart';
import 'package:horcrux/services/push_notification_receiver.dart';
import 'package:horcrux/utils/owner_push_opt_in_prompt.dart';

import 'owner_push_opt_in_prompt_test.mocks.dart';

@GenerateMocks([VaultRepository, LocalNotificationService, PushNotificationReceiver])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ownerPubkey = 'a' * 64;
  final otherPubkey = 'b' * 64;
  const vaultId = 'vault-1';

  late MockVaultRepository vaultRepository;
  late MockLocalNotificationService localNotifications;
  late MockPushNotificationReceiver pushReceiver;

  setUp(() {
    vaultRepository = MockVaultRepository();
    localNotifications = MockLocalNotificationService();
    pushReceiver = MockPushNotificationReceiver();
    PushNotificationReceiver.debugIsSupportedOverride = true;
  });

  tearDown(() {
    PushNotificationReceiver.debugIsSupportedOverride = null;
  });

  Vault makeVault({required bool pushEnabled, String? owner}) {
    return Vault(
      id: vaultId,
      name: 'Test Vault',
      content: 'secret',
      createdAt: DateTime(2024, 1, 1),
      ownerPubkey: owner ?? ownerPubkey,
      pushEnabled: pushEnabled,
    );
  }

  /// Pumps a minimal widget tree, captures a [BuildContext]/[WidgetRef] pair
  /// scoped to a `ProviderScope` with the given overrides, then invokes
  /// [maybePromptOwnerForVaultPush] against them.
  Future<void> runPrompt(
    WidgetTester tester, {
    required String currentPubkey,
    Vault? vault,
  }) async {
    when(vaultRepository.getVault(vaultId)).thenAnswer((_) async => vault);

    BuildContext? capturedContext;
    WidgetRef? capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultRepositoryProvider.overrideWithValue(vaultRepository),
          localNotificationServiceProvider.overrideWithValue(localNotifications),
          pushNotificationReceiverProvider.overrideWithValue(pushReceiver),
          currentPublicKeyProvider.overrideWith((ref) async => currentPubkey),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedContext = context;
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    await maybePromptOwnerForVaultPush(
      context: capturedContext!,
      ref: capturedRef!,
      vaultId: vaultId,
    );
  }

  group('maybePromptOwnerForVaultPush', () {
    testWidgets('persisted opted-in + OS permission granted: silent no-op', (tester) async {
      when(pushReceiver.isOptedIn()).thenAnswer((_) async => true);
      when(localNotifications.areOsNotificationsEnabled()).thenAnswer((_) async => true);

      await runPrompt(
        tester,
        currentPubkey: ownerPubkey,
        vault: makeVault(pushEnabled: true),
      );

      verify(pushReceiver.isOptedIn()).called(1);
      verify(localNotifications.areOsNotificationsEnabled()).called(1);
      verifyNever(pushReceiver.optIn());
    });

    testWidgets(
      'persisted opted-in + OS permission missing: re-runs optIn '
      '(this is the auto-backup divergence path the new branch covers)',
      (tester) async {
        when(pushReceiver.isOptedIn()).thenAnswer((_) async => true);
        when(localNotifications.areOsNotificationsEnabled()).thenAnswer((_) async => false);
        when(pushReceiver.optIn()).thenAnswer((_) async => true);

        await runPrompt(
          tester,
          currentPubkey: ownerPubkey,
          vault: makeVault(pushEnabled: true),
        );

        verify(pushReceiver.isOptedIn()).called(1);
        verify(localNotifications.areOsNotificationsEnabled()).called(1);
        verify(pushReceiver.optIn()).called(1);
      },
    );

    testWidgets('not opted in: skips OS probe and runs optIn directly', (tester) async {
      when(pushReceiver.isOptedIn()).thenAnswer((_) async => false);
      when(pushReceiver.optIn()).thenAnswer((_) async => true);

      await runPrompt(
        tester,
        currentPubkey: ownerPubkey,
        vault: makeVault(pushEnabled: true),
      );

      verify(pushReceiver.isOptedIn()).called(1);
      verifyNever(localNotifications.areOsNotificationsEnabled());
      verify(pushReceiver.optIn()).called(1);
    });

    testWidgets('vault has push disabled: silent no-op', (tester) async {
      await runPrompt(
        tester,
        currentPubkey: ownerPubkey,
        vault: makeVault(pushEnabled: false),
      );

      verifyNever(pushReceiver.isOptedIn());
      verifyNever(localNotifications.areOsNotificationsEnabled());
      verifyNever(pushReceiver.optIn());
    });

    testWidgets('current user is not the owner: silent no-op', (tester) async {
      await runPrompt(
        tester,
        currentPubkey: otherPubkey,
        vault: makeVault(pushEnabled: true, owner: ownerPubkey),
      );

      verifyNever(pushReceiver.isOptedIn());
      verifyNever(localNotifications.areOsNotificationsEnabled());
      verifyNever(pushReceiver.optIn());
    });

    testWidgets('vault no longer exists: silent no-op', (tester) async {
      await runPrompt(tester, currentPubkey: ownerPubkey, vault: null);

      verifyNever(pushReceiver.isOptedIn());
      verifyNever(localNotifications.areOsNotificationsEnabled());
      verifyNever(pushReceiver.optIn());
    });

    testWidgets('push unsupported on platform: silent no-op (no provider reads)', (tester) async {
      PushNotificationReceiver.debugIsSupportedOverride = false;

      await runPrompt(
        tester,
        currentPubkey: ownerPubkey,
        vault: makeVault(pushEnabled: true),
      );

      // Repository call short-circuits before any push receiver reads.
      verifyNever(pushReceiver.isOptedIn());
      verifyNever(localNotifications.areOsNotificationsEnabled());
      verifyNever(pushReceiver.optIn());
      verifyNever(vaultRepository.getVault(any));
    });
  });
}
