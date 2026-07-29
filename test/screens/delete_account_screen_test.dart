import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/relay_configuration.dart';
import 'package:horcrux/screens/delete_account_screen.dart';
import 'package:horcrux/services/account_deletion_service.dart';
import 'package:horcrux/services/publish_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:horcrux/widgets/row_button_stack.dart';
import 'package:horcrux/widgets/theme.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'delete_account_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AccountDeletionService>(),
  MockSpec<RelayScanService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final relays = [
    const RelayConfiguration(id: 'r1', url: 'wss://relay.one', name: 'relay.one'),
    const RelayConfiguration(id: 'r2', url: 'wss://relay.two', name: 'relay.two'),
  ];

  late MockAccountDeletionService accountDeletionService;
  late MockRelayScanService relayScanService;

  setUp(() {
    accountDeletionService = MockAccountDeletionService();
    relayScanService = MockRelayScanService();
    when(relayScanService.getRelayConfigurations(enabledOnly: true))
        .thenAnswer((_) async => relays);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        accountDeletionServiceProvider.overrideWithValue(accountDeletionService),
        relayScanServiceProvider.overrideWithValue(relayScanService),
      ],
      child: MaterialApp(
        theme: horcrux3Dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the account-deletion screen in the test harness.
  Future<void> openScreen({required WidgetTester tester}) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  /// Enters [confirmationText] into the deletion confirmation field.
  Future<void> enterConfirmText({
    required WidgetTester tester,
    String confirmationText = 'DELETE ALL MY NOSTR DATA',
  }) async {
    await tester.enterText(find.byType(TextField), confirmationText);
    await tester.pump();
  }

  testWidgets('confirming state renders copy and buttons; Cancel pops without deleting', (
    tester,
  ) async {
    await openScreen(tester: tester);

    expect(find.text('Delete Account'), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.textContaining('irreversible'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    verifyNever(accountDeletionService.deleteAccount(
      onRelayStatusUpdate: anyNamed('onRelayStatusUpdate'),
    ));
  });

  testWidgets(
    'Delete Account button is disabled until the confirm phrase is typed exactly',
    (tester) async {
      await openScreen(tester: tester);

      RowButtonConfig deleteButtonConfig() => tester
          .widgetList<RowButtonStack>(find.byType(RowButtonStack))
          .single
          .buttons
          .firstWhere((b) => b.text == 'Delete Account');

      expect(deleteButtonConfig().onPressed, isNull);
      expect(deleteButtonConfig().color, horcrux3Dark.colorScheme.error);

      await enterConfirmText(tester: tester, confirmationText: 'delete');
      expect(deleteButtonConfig().onPressed, isNull);

      await enterConfirmText(tester: tester, confirmationText: 'DELETE ALL MY NOSTR DATA');
      expect(deleteButtonConfig().onPressed, isNotNull);

      verifyNever(accountDeletionService.deleteAccount(
        onRelayStatusUpdate: anyNamed('onRelayStatusUpdate'),
      ));
    },
  );

  testWidgets('rapid double-tap on Delete Account only starts one deletion', (tester) async {
    final relayConfigCompleter = Completer<List<RelayConfiguration>>();
    when(relayScanService.getRelayConfigurations(enabledOnly: true))
        .thenAnswer((_) => relayConfigCompleter.future);
    when(accountDeletionService.deleteAccount(
      onRelayStatusUpdate: anyNamed('onRelayStatusUpdate'),
    )).thenAnswer(
      (_) async => const AccountDeletionResult(
        relayRequestAcknowledged: true,
        relaysAcknowledged: 2,
        relaysTotal: 2,
      ),
    );

    await openScreen(tester: tester);
    await enterConfirmText(tester: tester);

    // Tap twice before the relay-configuration lookup resolves, simulating a
    // double tap landing before the button has a chance to disable itself.
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pump();

    relayConfigCompleter.complete(relays);
    await tester.pumpAndSettle();

    verify(accountDeletionService.deleteAccount(
      onRelayStatusUpdate: anyNamed('onRelayStatusUpdate'),
    )).called(1);
  });

  testWidgets('tapping Delete Account shows one row per configured relay and live updates icons', (
    tester,
  ) async {
    final completer = Completer<AccountDeletionResult>();
    void Function(List<RelayPublishStatus>)? capturedCallback;
    when(accountDeletionService.deleteAccount(
      onRelayStatusUpdate: anyNamed('onRelayStatusUpdate'),
    )).thenAnswer((invocation) {
      capturedCallback = invocation.namedArguments[#onRelayStatusUpdate] as void Function(
          List<RelayPublishStatus>)?;
      return completer.future;
    });

    await openScreen(tester: tester);
    await enterConfirmText(tester: tester);

    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pump();

    expect(find.text('wss://relay.one'), findsOneWidget);
    expect(find.text('wss://relay.two'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    capturedCallback!([
      const RelayPublishStatus(
        relayUrl: 'wss://relay.one',
        state: RelayPublishAckState.acknowledged,
      ),
      const RelayPublishStatus(
        relayUrl: 'wss://relay.two',
        state: RelayPublishAckState.pending,
      ),
    ]);
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const AccountDeletionResult(
        relayRequestAcknowledged: true,
        relaysAcknowledged: 1,
        relaysTotal: 2,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('successful deletion shows the success state', (tester) async {
    when(accountDeletionService.deleteAccount(
      onRelayStatusUpdate: anyNamed('onRelayStatusUpdate'),
    )).thenAnswer(
      (_) async => const AccountDeletionResult(
        relayRequestAcknowledged: true,
        relaysAcknowledged: 2,
        relaysTotal: 2,
      ),
    );

    await openScreen(tester: tester);
    await enterConfirmText(tester: tester);
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();

    expect(find.text('Account deletion requested'), findsOneWidget);
  });

  testWidgets('failed deletion shows failure state with retry', (tester) async {
    var callCount = 0;
    when(accountDeletionService.deleteAccount(
      onRelayStatusUpdate: anyNamed('onRelayStatusUpdate'),
    )).thenAnswer((_) async {
      callCount++;
      return const AccountDeletionResult(
        relayRequestAcknowledged: false,
        relaysAcknowledged: 0,
        relaysTotal: 2,
      );
    });

    await openScreen(tester: tester);
    await enterConfirmText(tester: tester);
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();

    // The confirming->broadcasting->failure transition never emits a relay
    // status update in this test, so both rows start and stay pending; the
    // screen finalizes them to failed once the broadcast is known to be
    // over, rather than leaving stale spinners for a request that's done.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.cancel), findsNWidgets(2));
    expect(find.textContaining('has not been'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(callCount, 1);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(callCount, 2);
  });
}
