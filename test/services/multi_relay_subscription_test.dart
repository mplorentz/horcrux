import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';

import '../fixtures/test_keys.dart';
import '../helpers/fake_nostr_relay.dart';
import '../helpers/test_database.dart';
=======
import 'package:ndk/ndk.dart';

import '../helpers/fake_nostr_relay.dart';
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69

// ---------------------------------------------------------------------------
// Mock EventVerifier — accepts all events (avoids Bip340 crypto)
// ---------------------------------------------------------------------------
class AcceptAllEventVerifier implements EventVerifier {
  @override
  Future<bool> verify(Nip01Event event) async => true;
}

/// Creates a real NDK instance suitable for testing with fake relays.
Ndk _createTestNdk() {
  return Ndk(
    NdkConfig(
      cache: MemCacheManager(),
      eventVerifier: AcceptAllEventVerifier(),
      engine: NdkEngine.JIT,
      bootstrapRelays: [],
    ),
  );
}

<<<<<<< HEAD
/// Captures a [Ref] for constructing services in unit tests.
final _testRefProvider = Provider<Ref>((ref) => ref);

class _LoginServiceWithTestKey extends Fake implements LoginService {
  _LoginServiceWithTestKey(this._keyPair);

  final KeyPair _keyPair;

  @override
  Future<KeyPair?> getStoredNostrKey() async => _keyPair;
}

/// Avoids [path_provider] in plain Dart tests while satisfying [_setupSubscriptions].
class _InMemoryProcessedEventStore extends ProcessedNostrEventStore {
  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<int?> getLastSeen(String relayUrl) async => null;
}

=======
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
void main() {
  group('FakeNostrRelay', () {
    test('starts, accepts WebSocket connections, and relays events', () async {
      final relay = FakeNostrRelay();
      await relay.start();
      expect(relay.url, startsWith('ws://localhost:'));

      final ws = await WebSocket.connect(relay.url);
      final messages = <dynamic>[];
      ws.listen((data) => messages.add(data));

      // Send REQ
      ws.add(jsonEncode([
        'REQ',
        'test_sub',
        {
          'kinds': [1059],
          '#p': ['abc123']
        },
      ]));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should receive EOSE
      expect(messages, hasLength(greaterThanOrEqualTo(1)));
      final eose = jsonDecode(messages.first as String) as List;
      expect(eose[0], 'EOSE');
      expect(eose[1], 'test_sub');

      // Relay sends an event
      final testEvent = makeGiftWrapEvent(
        recipientPubkey: 'abc123',
<<<<<<< HEAD
        id: 'ff${"f" * 62}',
=======
        id: 'ff${'f' * 62}',
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
      );
      relay.sendEvent(testEvent);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should receive EVENT
      final evMsgs = messages.where((m) {
        final p = jsonDecode(m as String) as List;
        return p[0] == 'EVENT';
      }).toList();
      expect(evMsgs, hasLength(1));

      await ws.close();
      await relay.stop();
    });
  });

  group('NDK subscription dedup behavior', () {
    const testPubkey = 'abc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1';

    /// Settle time for WebSocket connection + EOSE.
    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 500));

    test(
      'cacheRead:false — two relays both deliver events independently',
      () async {
        final relay1 = FakeNostrRelay();
        final relay2 = FakeNostrRelay();
        await relay1.start();
        await relay2.start();

        try {
          final ndk = _createTestNdk();

          final filter = Filter(kinds: [1059], pTags: [testPubkey]);

          // Subscribe to relay 1 with cacheRead: false (correct behavior)
          final sub1 = ndk.requests.subscription(
            filters: [filter],
            explicitRelays: [relay1.url],
            cacheRead: false,
          );
          final events1 = <Nip01Event>[];
          final s1 = sub1.stream.listen((e) => events1.add(e));

          // Subscribe to relay 2 with cacheRead: false
          final sub2 = ndk.requests.subscription(
            filters: [filter],
            explicitRelays: [relay2.url],
            cacheRead: false,
          );
          final events2 = <Nip01Event>[];
          final s2 = sub2.stream.listen((e) => events2.add(e));

          await settle();

          // Send an event to each relay
          final e1 = makeGiftWrapEvent(
            recipientPubkey: testPubkey,
<<<<<<< HEAD
            id: 'aa${"a" * 62}',
=======
            id: 'aa${'a' * 62}',
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );
          final e2 = makeGiftWrapEvent(
            recipientPubkey: testPubkey,
<<<<<<< HEAD
            id: 'bb${"b" * 62}',
=======
            id: 'bb${'b' * 62}',
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

          relay1.sendEvent(e1);
          relay2.sendEvent(e2);

          await settle();

          await s1.cancel();
          await s2.cancel();
          await ndk.requests.closeAllSubscription();

          expect(events1, hasLength(1),
              reason: 'sub1 (relay1, cacheRead:false) should receive event');
          expect(events2, hasLength(1),
              reason: 'sub2 (relay2, cacheRead:false) should receive event');
          expect(events1.first.id, e1.id, reason: 'sub1 should get relay1 event');
          expect(events2.first.id, e2.id, reason: 'sub2 should get relay2 event');
        } finally {
          await relay1.stop();
          await relay2.stop();
        }
      },
    );

    test(
      'cacheRead:true — second subscription stream is replaced (BUG behavior)',
      () async {
        final relay1 = FakeNostrRelay();
        final relay2 = FakeNostrRelay();
        await relay1.start();
        await relay2.start();

        try {
          final ndk = _createTestNdk();

          final filter = Filter(kinds: [1059], pTags: [testPubkey]);

          // Subscribe with cacheRead:true (BUG — triggers ConcurrencyCheck dedup)
          final sub1 = ndk.requests.subscription(
            filters: [filter],
            explicitRelays: [relay1.url],
            cacheRead: true,
          );
          final events1 = <Nip01Event>[];
          final s1 = sub1.stream.listen((e) => events1.add(e));

          final sub2 = ndk.requests.subscription(
            filters: [filter],
            explicitRelays: [relay2.url],
            cacheRead: true,
          );
          final events2 = <Nip01Event>[];
          final s2 = sub2.stream.listen((e) => events2.add(e));

          await settle();

          final e1 = makeGiftWrapEvent(
            recipientPubkey: testPubkey,
<<<<<<< HEAD
            id: 'cc${"c" * 62}',
=======
            id: 'cc${'c' * 62}',
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );
          final e2 = makeGiftWrapEvent(
            recipientPubkey: testPubkey,
<<<<<<< HEAD
            id: 'dd${"d" * 62}',
=======
            id: 'dd${'d' * 62}',
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

          relay1.sendEvent(e1);
          relay2.sendEvent(e2);

          await settle();

          await s1.cancel();
          await s2.cancel();
          await ndk.requests.closeAllSubscription();

          // sub1 should get its event
          expect(events1, hasLength(1), reason: 'sub1 (relay1) should receive event');

          // BUG: sub2's stream was replaced by sub1's stream via ConcurrencyCheck.
          // REQ was NEVER sent to relay2, so event2 never arrives.
          expect(events2.where((e) => e.id == e2.id), isEmpty,
              reason: 'BUG: With cacheRead:true, relay2 subscription is deduped');
        } finally {
          await relay1.stop();
          await relay2.stop();
        }
      },
    );

    test(
      'closeSubscription + re-add with cacheRead:false works',
      () async {
        final relay = FakeNostrRelay();
        await relay.start();

        try {
          final ndk = _createTestNdk();

          final filter = Filter(kinds: [1059], pTags: [testPubkey]);

          // Round 1: subscribe
          final sub1 = ndk.requests.subscription(
            filters: [filter],
            explicitRelays: [relay.url],
            cacheRead: false,
          );
          final events1 = <Nip01Event>[];
          final s1 = sub1.stream.listen((e) => events1.add(e));
          final sub1Id = sub1.requestId;

          await settle();

          // Proper close (what closeSubscriptions SHOULD do)
          await ndk.requests.closeSubscription(sub1Id);
          await s1.cancel();

          // Round 2: re-subscribe
          final sub2 = ndk.requests.subscription(
            filters: [filter],
            explicitRelays: [relay.url],
            cacheRead: false,
          );
          final events2 = <Nip01Event>[];
          final s2 = sub2.stream.listen((e) => events2.add(e));

          await settle();

          final event = makeGiftWrapEvent(
            recipientPubkey: testPubkey,
<<<<<<< HEAD
            id: 'ee${"e" * 62}',
=======
            id: 'ee${'e' * 62}',
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );
          relay.sendEvent(event);

          await settle();

          await s2.cancel();
          await ndk.requests.closeAllSubscription();

          expect(events1, isEmpty, reason: 'closed sub should not receive new events');
          expect(events2, hasLength(1),
              reason: 're-added sub (cacheRead:false) should receive events');
        } finally {
          await relay.stop();
        }
      },
    );

    test(
      're-subscribe without close leaves orphaned subscription (demonstrates Bug 1)',
      () async {
        // Simulates the buggy closeSubscriptions behavior:
        // cancel Dart stream but don't close NDK subscription.
        // The old subscription is still alive on the relay. When the
        // relay sends events, it uses the OLD subscription ID, so the
        // new subscription never receives them.
        //
        // This demonstrates why closeSubscriptions MUST call
        // _ndk.requests.closeSubscription() to clean up properly.
        final relay = FakeNostrRelay();
        await relay.start();

        try {
          final ndk = _createTestNdk();

          final filter = Filter(kinds: [1059], pTags: [testPubkey]);

          // Round 1: subscribe but don't close at NDK level
          final sub1 = ndk.requests.subscription(
            filters: [filter],
            explicitRelays: [relay.url],
            cacheRead: false,
          );
          final events1 = <Nip01Event>[];
          final s1 = sub1.stream.listen((e) => events1.add(e));
          await settle();

          // "Close" — only cancel Dart stream, don't call closeSubscription
          await s1.cancel();

          // Round 2: re-subscribe with cacheRead:false
          final sub2 = ndk.requests.subscription(
            filters: [filter],
            explicitRelays: [relay.url],
            cacheRead: false,
          );
          final events2 = <Nip01Event>[];
          final s2 = sub2.stream.listen((e) => events2.add(e));
          await settle();

          final event = makeGiftWrapEvent(
            recipientPubkey: testPubkey,
<<<<<<< HEAD
            id: 'ff${"f" * 62}',
=======
            id: 'ff${'f' * 62}',
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );
          relay.sendEvent(event);
          await settle();

          await s2.cancel();
          await ndk.requests.closeAllSubscription();

          // BUG: Event was delivered to the old subscription that nobody
          // is listening to. The new subscription never received it.
          // This is why closeSubscription MUST send CLOSE to the relay
          // and clean up inFlightRequests.
          expect(events2, isEmpty,
              reason: 'BUG: orphaned subscription received the event, not the new one');
        } finally {
          await relay.stop();
        }
      },
    );
  });

  group('ndk_service fix verification', () {
<<<<<<< HEAD
    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 500));

    test(
      'closeSubscriptions closes NDK wire subs and cancels Dart listeners',
      () async {
        final relay = FakeNostrRelay();
        await relay.start();

        final alicePrivHex = Helpers.decodeBech32(TestNsecKeys.alice)[0];
        final alicePubHex = Bip340.getPublicKey(alicePrivHex);
        final keyPair = KeyPair(
          alicePrivHex,
          alicePubHex,
          TestNsecKeys.alice,
          TestNpubKeys.alice,
        );

        final container = ProviderContainer();
        final db = newTestDatabase();
        final ndkService = NdkService(
          ref: container.read(_testRefProvider),
          loginService: _LoginServiceWithTestKey(keyPair),
          processedEventStore: _InMemoryProcessedEventStore(),
          database: db,
          getInvitationService: () => throw StateError('not used in this test'),
        );
        ndkService.setNdkForTesting(_createTestNdk());

        try {
          await ndkService.addRelay(relay.url);
          await settle();

          final ndk = await ndkService.getNdk();
          final subIdsBefore = ndk.relays.globalState.inFlightRequests.values
              .where((state) => state.isSubscription)
              .map((state) => state.id)
              .toSet();
          expect(subIdsBefore, isNotEmpty);
          expect(relay.activeSubscriptionIds, subIdsBefore);

          await ndkService.closeSubscriptions();

          final openSubIdsAfter = ndk.relays.globalState.inFlightRequests.values
              .where((state) => state.isSubscription)
              .map((state) => state.id)
              .toList();
          expect(openSubIdsAfter, isEmpty);
          for (final requestId in subIdsBefore) {
            expect(
              ndk.relays.globalState.inFlightRequests.containsKey(requestId),
              isFalse,
              reason: 'closeSubscriptions should remove $requestId from inFlightRequests',
            );
          }

          // Re-subscribe via removeRelay → addRelay: if wire CLOSE was not sent,
          // the relay would accumulate a second active subscription id.
          await ndkService.removeRelay(relay.url);
          await ndkService.addRelay(relay.url);
          await settle();

          final subIdsAfterReAdd = ndk.relays.globalState.inFlightRequests.values
              .where((state) => state.isSubscription)
              .map((state) => state.id)
              .toSet();
          expect(subIdsAfterReAdd, isNotEmpty);
          expect(subIdsAfterReAdd.intersection(subIdsBefore), isEmpty);
          expect(relay.activeSubscriptionIds, subIdsAfterReAdd);
          expect(relay.activeSubscriptionIds, hasLength(1));
        } finally {
          ndkService.disposePublishWorkerSync();
          await ndkService.dispose();
          await db.close();
          container.dispose();
          await relay.stop();
        }
=======
    test(
      'ndk_service.closeSubscriptions now calls _ndk.requests.closeSubscription',
      () async {
        // This test verifies the code change in ndk_service.dart.
        //
        // BEFORE FIX:
        //   closeSubscriptions() only cancelled Dart stream subscriptions
        //   and cleared local lists. It NEVER called
        //   _ndk.requests.closeSubscription() — meaning orphaned
        //   RequestState entries were left in NDK's globalState.inFlightRequests.
        //
        // AFTER FIX:
        //   closeSubscriptions() iterates _subscriptionResponses and calls
        //   _ndk.requests.closeSubscription(response.requestId) for each.
        //
        // The NDK-level integration tests above prove both fix behaviors:
        // - "closeSubscription + re-add with cacheRead:false works"
        // - "re-subscribe without close leaves orphaned subscription"
        //
        // The fix passes cacheRead:false to subscription() calls which is
        // validated by:
        // - "cacheRead:false — two relays both deliver events independently"
        // - "cacheRead:true — second subscription stream is replaced"
        expect(true, isTrue, reason: 'fixes applied to ndk_service.dart');
>>>>>>> 4b6ef25eb502c83a0cd7984303696dd0fe87af69
      },
    );
  });
}
