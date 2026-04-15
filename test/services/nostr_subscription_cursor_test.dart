import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';

void main() {
  group('computeSinceTime', () {
    test('no cursor yet uses epoch (0)', () {
      final now = DateTime.utc(2026, 4, 14, 12);
      final since = computeSinceTime(
        nowUtc: now,
        lastSeenEventCreatedAtUnix: null,
      );
      expect(since, 0);
    });

    test('zero lastSeen uses epoch', () {
      final since = computeSinceTime(
        nowUtc: DateTime.utc(2026, 4, 14, 12),
        lastSeenEventCreatedAtUnix: 0,
      );
      expect(since, 0);
    });

    test('recent lastSeen still includes full rolling window', () {
      final now = DateTime.utc(2026, 4, 14, 12);
      final threeDaysAgo = now.subtract(const Duration(days: 3)).millisecondsSinceEpoch ~/ 1000;
      final oneHourAgo = now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      expect(oneHourAgo > threeDaysAgo, isTrue);
      final since = computeSinceTime(
        nowUtc: now,
        lastSeenEventCreatedAtUnix: oneHourAgo,
      );
      expect(since, threeDaysAgo);
    });

    test('stale lastSeen extends back to cursor (not capped to rolling window)', () {
      final now = DateTime.utc(2026, 4, 14, 12);
      final threeDaysAgo = now.subtract(const Duration(days: 3)).millisecondsSinceEpoch ~/ 1000;
      final tenDaysAgo = now.subtract(const Duration(days: 10)).millisecondsSinceEpoch ~/ 1000;
      expect(tenDaysAgo < threeDaysAgo, isTrue);
      final since = computeSinceTime(
        nowUtc: now,
        lastSeenEventCreatedAtUnix: tenDaysAgo,
      );
      expect(since, tenDaysAgo);
    });

    test('very stale lastSeen (e.g. weeks) uses that bound', () {
      final now = DateTime.utc(2026, 4, 14, 12);
      final threeWeeksAgo = now.subtract(const Duration(days: 21)).millisecondsSinceEpoch ~/ 1000;
      final since = computeSinceTime(
        nowUtc: now,
        lastSeenEventCreatedAtUnix: threeWeeksAgo,
      );
      expect(since, threeWeeksAgo);
    });
  });

  group('normalizeRelayUrlForNostrEventCursor', () {
    test('strips trailing slash on root path', () {
      expect(
        normalizeRelayUrlForNostrEventCursor('wss://relay.example.com/'),
        'wss://relay.example.com',
      );
    });

    test('preserves non-root path', () {
      expect(
        normalizeRelayUrlForNostrEventCursor('wss://relay.example.com/nostr'),
        'wss://relay.example.com/nostr',
      );
    });

    test('lowercases host and scheme', () {
      expect(
        normalizeRelayUrlForNostrEventCursor('WSS://Relay.EXAMPLE.com'),
        'wss://relay.example.com',
      );
    });

    test('equivalent URLs share the same cursor key', () {
      expect(
        normalizeRelayUrlForNostrEventCursor('wss://relay.example.com/'),
        normalizeRelayUrlForNostrEventCursor('WSS://relay.example.com'),
      );
    });

    test('different hosts do not share a cursor key', () {
      expect(
        normalizeRelayUrlForNostrEventCursor('wss://a.example.com'),
        isNot(normalizeRelayUrlForNostrEventCursor('wss://b.example.com')),
      );
    });
  });
}
