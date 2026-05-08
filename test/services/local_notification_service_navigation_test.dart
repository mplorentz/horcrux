import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'package:horcrux/app_navigator.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/local_notification_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/recovery_service.dart';

import 'local_notification_service_navigation_test.mocks.dart';

/// Mockito-friendly stand-in for [RecoveryService]. We only exercise
/// `getRecoveryRequest` here; the rest of the surface stays unimplemented.
class _FakeRecoveryService extends Fake implements RecoveryService {
  final Map<String, RecoveryRequest> requests = {};

  @override
  Future<RecoveryRequest?> getRecoveryRequest(String id) async => requests[id];
}

/// Stand-in for [LoginService] that returns no current key. The navigation
/// tests don't exercise the self-origin filter, so a "no key" stub is
/// sufficient and avoids touching `flutter_secure_storage`.
class _FakeLoginService extends Fake implements LoginService {
  @override
  Future<String?> getCurrentPublicKey() async => null;
}

/// Records `didPush` / `didRemove` events as `'<verb>:<routeName>'` strings.
///
/// Routes pushed by [LocalNotificationService] carry stable
/// [RouteSettings.name] values produced by [vaultDetailRouteName] /
/// [recoveryStatusRouteName] / [recoveryRequestRouteName], so we can assert
/// on the navigation contract without rendering the destination screens
/// (whose providers are not wired up in these tests).
class _RouteEventRecorder extends NavigatorObserver {
  final List<String> events = <String>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    events.add('push:${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    events.add('remove:${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    events.add('replace:${oldRoute?.settings.name}->${newRoute?.settings.name}');
  }

  List<String> get pushNames =>
      events.where((e) => e.startsWith('push:')).map((e) => e.substring('push:'.length)).toList();

  List<String> get removeNames => events
      .where((e) => e.startsWith('remove:'))
      .map((e) => e.substring('remove:'.length))
      .toList();
}

@GenerateMocks([VaultRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ownerPubkey = '0000000000000000000000000000000000000000000000000000000000000001';
  const vaultId = 'vault-1';
  const requestId = 'req-1';
  const fallbackVaultId = 'vault-fallback';
  // [MaterialApp.home] is registered as the implicit root route with the
  // synthesized name `/`.
  const homeRouteName = '/';

  late MockVaultRepository vaultRepository;
  late _FakeRecoveryService recoveryService;
  late LocalNotificationService service;

  setUp(() {
    vaultRepository = MockVaultRepository();
    recoveryService = _FakeRecoveryService();
    service = LocalNotificationService(
      vaultRepository: vaultRepository,
      loginService: _FakeLoginService(),
      getRecoveryService: () => recoveryService,
    );
  });

  RecoveryRequest testRequest({String id = requestId, String vault = vaultId}) {
    return RecoveryRequest(
      id: id,
      vaultId: vault,
      initiatorPubkey: ownerPubkey,
      requestedAt: DateTime(2024, 1, 1),
      status: RecoveryRequestStatus.pending,
      threshold: 2,
    );
  }

  /// Pumps a minimal [MaterialApp] bound to the global [navigatorKey] with
  /// [observer] attached. `home` is a placeholder screen so it doesn't
  /// require any provider overrides.
  Future<void> pumpHostApp(WidgetTester tester, _RouteEventRecorder observer) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [observer],
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
  }

  group('LocalNotificationService.navigateForKind', () {
    testWidgets(
      'recovery response with known request: stack becomes '
      '[home, vault_detail, recovery_status]',
      (tester) async {
        recoveryService.requests[requestId] = testRequest();
        final observer = _RouteEventRecorder();
        await pumpHostApp(tester, observer);

        await service.navigateForKind(NostrKind.recoveryResponse, requestId);
        // Flush microtasks + scheduled navigator work without rebuilding the
        // destination screens (whose providers are intentionally not wired).
        await tester.pump();

        expect(
          observer.pushNames,
          equals([
            homeRouteName,
            vaultDetailRouteName(vaultId),
            recoveryStatusRouteName(requestId),
          ]),
        );
        // `(route) => route.isFirst` preserves the home route, so nothing was
        // removed.
        expect(observer.removeNames, isEmpty);

        // Discard build errors from the unwired screens.
        while (tester.takeException() != null) {}
      },
    );

    testWidgets(
      'recovery response with unknown request + fallback vaultId: '
      'navigates to vault detail only',
      (tester) async {
        // recoveryService.requests is empty → getRecoveryRequest returns null.
        final observer = _RouteEventRecorder();
        await pumpHostApp(tester, observer);

        await service.navigateForKind(
          NostrKind.recoveryResponse,
          requestId,
          vaultId: fallbackVaultId,
        );
        await tester.pump();

        expect(
          observer.pushNames,
          equals([
            homeRouteName,
            vaultDetailRouteName(fallbackVaultId),
          ]),
        );
        expect(observer.removeNames, isEmpty);

        while (tester.takeException() != null) {}
      },
    );

    testWidgets(
      'recovery response with unknown request + no fallback: no navigation',
      (tester) async {
        final observer = _RouteEventRecorder();
        await pumpHostApp(tester, observer);

        final navigated = await service.navigateForKind(NostrKind.recoveryResponse, requestId);
        await tester.pump();

        expect(navigated, isFalse);
        expect(observer.pushNames, equals([homeRouteName])); // only the home route
        expect(observer.removeNames, isEmpty);
      },
    );

    testWidgets(
      'recovery request: stack becomes [home, vault_detail, recovery_request]',
      (tester) async {
        recoveryService.requests[requestId] = testRequest();
        final observer = _RouteEventRecorder();
        await pumpHostApp(tester, observer);

        await service.navigateForKind(NostrKind.recoveryRequest, requestId);
        await tester.pump();

        expect(
          observer.pushNames,
          equals([
            homeRouteName,
            vaultDetailRouteName(vaultId),
            recoveryRequestRouteName(requestId),
          ]),
        );
        expect(observer.removeNames, isEmpty);

        while (tester.takeException() != null) {}
      },
    );

    testWidgets(
      'shard data tap: pushes vault detail only, no recovery screen',
      (tester) async {
        final observer = _RouteEventRecorder();
        await pumpHostApp(tester, observer);

        await service.navigateForKind(
          NostrKind.shareData,
          'shard-event-id',
          vaultId: vaultId,
        );
        await tester.pump();

        expect(
          observer.pushNames,
          equals([
            homeRouteName,
            vaultDetailRouteName(vaultId),
          ]),
        );
        expect(observer.removeNames, isEmpty);

        while (tester.takeException() != null) {}
      },
    );

    testWidgets(
      'shard data tap with no vaultId: returns false, no navigation',
      (tester) async {
        final observer = _RouteEventRecorder();
        await pumpHostApp(tester, observer);

        final navigated = await service.navigateForKind(
          NostrKind.shareData,
          'shard-event-id',
        );
        await tester.pump();

        expect(navigated, isFalse);
        expect(observer.pushNames, equals([homeRouteName]));
        expect(observer.removeNames, isEmpty);
      },
    );

    testWidgets(
      'stack reset preserves the root route: routes pushed before the '
      'notification tap are removed, the root home is kept',
      (tester) async {
        recoveryService.requests[requestId] = testRequest();
        final observer = _RouteEventRecorder();
        await pumpHostApp(tester, observer);

        // Push a couple of unrelated routes (mimicking the user navigating
        // around before the notification arrives).
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'unrelated_a'),
            builder: (_) => const Scaffold(body: Text('A')),
          ),
        );
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'unrelated_b'),
            builder: (_) => const Scaffold(body: Text('B')),
          ),
        );
        await tester.pump();

        // Sanity: both unrelated routes pushed.
        expect(
          observer.pushNames,
          containsAllInOrder(['unrelated_a', 'unrelated_b']),
        );

        // Now fire the notification tap.
        await service.navigateForKind(NostrKind.recoveryResponse, requestId);
        await tester.pump();

        // The two unrelated routes should be removed by `pushAndRemoveUntil`,
        // but the root home route should be preserved.
        expect(
          observer.removeNames,
          containsAll(<String>['unrelated_b', 'unrelated_a']),
        );
        expect(observer.removeNames, isNot(contains(homeRouteName))); // root preserved

        // Final stack ends in [home, vault_detail, recovery_status].
        expect(
          observer.pushNames,
          containsAllInOrder([
            vaultDetailRouteName(vaultId),
            recoveryStatusRouteName(requestId),
          ]),
        );

        while (tester.takeException() != null) {}
      },
    );
  });
}
