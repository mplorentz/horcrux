import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/relay_configuration.dart';
import 'package:horcrux/screens/delete_account_screen.dart';
import 'package:horcrux/services/account_deletion_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
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

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('confirming state renders copy and buttons; Cancel pops without deleting', (
    tester,
  ) async {
    await openScreen(tester);

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

  testWidgets('tapping Delete Account shows one row per configured relay and live updates icons', (
    tester,
  ) async {
    final completer = Completer<AccountDeletionResult>();
    void Function(List<RelayVanishStatus>)? capturedCallback;
    when(accountDeletionService.deleteAccount(
      onRelayStatusUpdate: anyNamed('onRelayStatusUpdate'),
    )).thenAnswer((invocation) {
      capturedCallback = invocation.namedArguments[#onRelayStatusUpdate] as void Function(
          List<RelayVanishStatus>)?;
      return completer.future;
    });

    await openScreen(tester);

    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pump();

    expect(find.text('wss://relay.one'), findsOneWidget);
    expect(find.text('wss://relay.two'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    capturedCallback!([
      const RelayVanishStatus(
        relayUrl: 'wss://relay.one',
        state: RelayVanishAckState.acknowledged,
      ),
      const RelayVanishStatus(
        relayUrl: 'wss://relay.two',
        state: RelayVanishAckState.pending,
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

    await openScreen(tester);
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

    await openScreen(tester);
    await tester.tap(find.byIcon(Icons.delete_forever));
    // The confirming->broadcasting->failure transition never emits a relay
    // status update in this test, so the row list keeps its initial pending
    // spinners in the failure state; pumpAndSettle would time out on those
    // indeterminate CircularProgressIndicators, so pump explicitly instead.
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('has not been'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(callCount, 1);

    await tester.tap(find.text('Try Again'));
    await tester.pump();
    await tester.pump();

    expect(callCount, 2);
  });
}
