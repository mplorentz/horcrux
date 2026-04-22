import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/push_notification_receiver.dart';

void main() {
  group('parseFcmEmbeddedEventJson', () {
    test('returns null when event_json is absent', () {
      expect(parseFcmEmbeddedEventJson({'event_id': 'abc'}), isNull);
    });

    test('accepts a decoded Map', () {
      final map = <String, dynamic>{'kind': 1059, 'id': 'x' * 64};
      expect(
        parseFcmEmbeddedEventJson({'event_json': map}),
        map,
      );
    });

    test('decodes a JSON string (typical FCM Android/iOS)', () {
      final map = <String, dynamic>{'kind': 1059, 'content': 'cipher'};
      final encoded = jsonEncode(map);
      expect(
        parseFcmEmbeddedEventJson({'event_json': encoded}),
        map,
      );
    });

    test('returns null for invalid JSON string', () {
      expect(parseFcmEmbeddedEventJson({'event_json': '{not json'}), isNull);
    });

    test('returns null when event_json is a JSON array', () {
      expect(parseFcmEmbeddedEventJson({'event_json': '[1,2]'}), isNull);
    });
  });

  group('parseFcmEventId', () {
    test('parses string event_id', () {
      expect(
        parseFcmEventId({'event_id': 'ab' * 32}),
        'ab' * 32,
      );
    });

    test('returns null when absent', () {
      expect(parseFcmEventId({}), isNull);
    });
  });

  group('parseFcmRelayHints', () {
    test('parses JSON array string', () {
      expect(
        parseFcmRelayHints({'relay_hints': '["wss://a.com","wss://b.com"]'}),
        ['wss://a.com', 'wss://b.com'],
      );
    });

    test('accepts a decoded List', () {
      expect(
        parseFcmRelayHints({
          'relay_hints': ['wss://r.example/nostr'],
        }),
        ['wss://r.example/nostr'],
      );
    });

    test('returns null for invalid JSON string', () {
      expect(parseFcmRelayHints({'relay_hints': '['}), isNull);
    });
  });
}
