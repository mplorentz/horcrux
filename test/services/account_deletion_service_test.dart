import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/relay_configuration.dart';
import 'package:horcrux/services/account_deletion_service.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/logout_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/publish_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'account_deletion_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<NdkService>(),
  MockSpec<RelayScanService>(),
  MockSpec<HorcruxNotificationService>(),
  MockSpec<LogoutService>(),
])
void main() {
  group('AccountDeletionService', () {
    late MockNdkService ndkService;
    late MockRelayScanService relayScanService;
    late MockHorcruxNotificationService notificationService;
    late MockLogoutService logoutService;
    late AccountDeletionService service;

    final relays = [
      const RelayConfiguration(id: 'r1', url: 'wss://relay.one', name: 'relay.one'),
      const RelayConfiguration(id: 'r2', url: 'wss://relay.two', name: 'relay.two'),
    ];

    /// Builds a fake [PublishBroadcastHandle] whose `done` future resolves
    /// only after [statusEvents] (if any) have all been emitted on
    /// `statusUpdates`, mirroring how `ndk`'s real `broadcastDoneFuture` is
    /// derived from `broadcastDone.last`. Events are emitted from a macrotask
    /// (scheduled via the `Future(...)` constructor) so that
    /// `AccountDeletionService.deleteAccount`'s `statusUpdates.listen(...)`
    /// call -- which happens synchronously once it awaits this handle -- is
    /// always attached before the first event fires.
    PublishBroadcastHandle handleFor(
      List<String> relayUrls,
      Set<String> acknowledged, {
      List<List<RelayPublishStatus>> statusEvents = const [],
    }) {
      final controller = StreamController<List<RelayPublishStatus>>.broadcast();
      final doneCompleter = Completer<Set<String>>();
      Future<void>(() async {
        for (final event in statusEvents) {
          controller.add(event);
        }
        await controller.close();
        doneCompleter.complete(acknowledged);
      });
      return PublishBroadcastHandle(
        relayUrls: relayUrls,
        statusUpdates: controller.stream,
        done: doneCompleter.future,
      );
    }

    setUp(() {
      ndkService = MockNdkService();
      relayScanService = MockRelayScanService();
      notificationService = MockHorcruxNotificationService();
      logoutService = MockLogoutService();
      service = AccountDeletionService(
        ndkService: ndkService,
        relayScanService: relayScanService,
        notificationService: notificationService,
        logoutService: logoutService,
      );

      when(
        relayScanService.getRelayConfigurations(enabledOnly: true),
      ).thenAnswer((_) async => relays);
      when(notificationService.deregister()).thenAnswer((_) async {});
      when(logoutService.logout()).thenAnswer((_) async {});
    });

    test('wipes local state when at least one relay acknowledges', () async {
      when(
        ndkService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor([
          'wss://relay.one',
          'wss://relay.two'
        ], {
          'wss://relay.one',
        }),
      );

      final result = await service.deleteAccount();

      expect(result.relayRequestAcknowledged, isTrue);
      expect(result.relaysAcknowledged, 1);
      expect(result.relaysTotal, 2);
      verify(notificationService.deregister()).called(1);
      verify(logoutService.logout()).called(1);
    });

    test('throws and does nothing when no relays are configured', () async {
      when(
        relayScanService.getRelayConfigurations(enabledOnly: true),
      ).thenAnswer((_) async => []);

      await expectLater(service.deleteAccount(), throwsStateError);

      verifyNever(
        ndkService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      );
      verifyNever(notificationService.deregister());
      verifyNever(logoutService.logout());
    });

    test('does not wipe local state when no relay acknowledges', () async {
      when(
        ndkService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor(['wss://relay.one', 'wss://relay.two'], {}),
      );

      final result = await service.deleteAccount();

      expect(result.relayRequestAcknowledged, isFalse);
      expect(result.relaysAcknowledged, 0);
      verifyNever(notificationService.deregister());
      verifyNever(logoutService.logout());
    });

    test('forwards live relay status updates via onRelayStatusUpdate', () async {
      const pending = [
        RelayPublishStatus(
          relayUrl: 'wss://relay.one',
          state: RelayPublishAckState.pending,
        ),
        RelayPublishStatus(
          relayUrl: 'wss://relay.two',
          state: RelayPublishAckState.pending,
        ),
      ];
      const settled = [
        RelayPublishStatus(
          relayUrl: 'wss://relay.one',
          state: RelayPublishAckState.acknowledged,
        ),
        RelayPublishStatus(
          relayUrl: 'wss://relay.two',
          state: RelayPublishAckState.failed,
        ),
      ];
      when(
        ndkService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor(
          ['wss://relay.one', 'wss://relay.two'],
          {'wss://relay.one'},
          statusEvents: [pending, settled],
        ),
      );

      final received = <List<RelayPublishStatus>>[];
      await service.deleteAccount(onRelayStatusUpdate: received.add);

      expect(received, [pending, settled]);
    });

    test('cancels the relay-status subscription even when the broadcast fails', () async {
      final relayUrls = ['wss://relay.one', 'wss://relay.two'];
      final controller = StreamController<List<RelayPublishStatus>>.broadcast();
      final doneCompleter = Completer<Set<String>>();
      // Complete the error from a later task, mirroring handleFor, so the
      // service's `await broadcast.done` is already attached when it fires.
      Future<void>(() => doneCompleter.completeError(Exception('broadcast failed')));
      final handle = PublishBroadcastHandle(
        relayUrls: relayUrls,
        statusUpdates: controller.stream,
        done: doneCompleter.future,
      );
      when(
        ndkService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer((_) async => handle);

      await expectLater(
        service.deleteAccount(onRelayStatusUpdate: (_) {}),
        throwsException,
      );

      expect(controller.hasListener, isFalse);
      verifyNever(notificationService.deregister());
      verifyNever(logoutService.logout());
    });

    test('still wipes local state when notifier deregister fails', () async {
      when(
        ndkService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor([
          'wss://relay.one',
          'wss://relay.two'
        ], {
          'wss://relay.one',
        }),
      );
      when(notificationService.deregister()).thenThrow(Exception('network error'));

      final result = await service.deleteAccount();

      expect(result.relayRequestAcknowledged, isTrue);
      verify(logoutService.logout()).called(1);
    });
  });
}
