import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/login_service.dart';

import '../helpers/shared_preferences_mock.dart';
import 'horcrux_notification_service_test.mocks.dart';

@GenerateMocks([LoginService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sharedPreferencesMock = SharedPreferencesMock();

  setUpAll(sharedPreferencesMock.setUpAll);
  tearDownAll(sharedPreferencesMock.tearDownAll);

  late MockLoginService loginService;
  late KeyPair keyPair;

  setUp(() {
    sharedPreferencesMock.clear();
    loginService = MockLoginService();
    keyPair = Bip340.generatePrivateKey();
    when(loginService.getStoredNostrKey()).thenAnswer((_) async => keyPair);
  });

  /// Decodes the `Authorization: Nostr <base64>` header back into its
  /// underlying NIP-98 event so we can assert on the server's view of the
  /// request.
  Nip01Event decodeAuthHeader(String header) {
    expect(header.startsWith('Nostr '), isTrue, reason: 'header: $header');
    final raw = utf8.decode(base64Decode(header.substring('Nostr '.length)));
    return Nip01Event.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  String? firstTag(Nip01Event event, String name) {
    for (final tag in event.tags) {
      if (tag.isNotEmpty && tag[0] == name && tag.length > 1) return tag[1];
    }
    return null;
  }

  /// Builds a service wired to a stub HTTP client that records the single
  /// request it sees, then replies with [response].
  ({
    HorcruxNotificationService service,
    List<http.Request> received,
  }) buildService({required http.Response Function(http.Request) handler}) {
    final received = <http.Request>[];
    final client = MockClient((request) async {
      received.add(request);
      return handler(request);
    });
    final service = HorcruxNotificationService(
      loginService: loginService,
      httpClient: client,
    );
    return (service: service, received: received);
  }

  group('base URL', () {
    test('defaults to production notifier', () async {
      final svc = HorcruxNotificationService(loginService: loginService);
      expect(await svc.getBaseUrl(), HorcruxNotificationService.defaultBaseUrl);
      svc.dispose();
    });

    test('honors override from SharedPreferences (trailing slash trimmed)', () async {
      final svc = HorcruxNotificationService(loginService: loginService);
      await svc.setBaseUrl('https://notify.example.com/');
      expect(await svc.getBaseUrl(), 'https://notify.example.com');
      svc.dispose();
    });

    test('clearing override reverts to default', () async {
      final svc = HorcruxNotificationService(loginService: loginService);
      await svc.setBaseUrl('https://custom.example.com');
      await svc.setBaseUrl(null);
      expect(await svc.getBaseUrl(), HorcruxNotificationService.defaultBaseUrl);
      svc.dispose();
    });

    test('treats blank override as unset', () async {
      final svc = HorcruxNotificationService(loginService: loginService);
      await svc.setBaseUrl('   ');
      expect(await svc.getBaseUrl(), HorcruxNotificationService.defaultBaseUrl);
      svc.dispose();
    });
  });

  group('register', () {
    test('POSTs /register with device_token/platform and NIP-98 auth', () async {
      final harness = buildService(
        handler: (req) => http.Response(
          jsonEncode({'pubkey': keyPair.publicKey, 'platform': 'ios'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.register(
        fcmToken: 'fcm-token-123',
        platform: NotifierPlatform.ios,
      );

      expect(harness.received, hasLength(1));
      final req = harness.received.single;
      expect(req.method, 'POST');
      expect(
        req.url.toString(),
        '${HorcruxNotificationService.defaultBaseUrl}/register',
      );
      expect(req.headers['Content-Type'], 'application/json');
      final body = json.decode(req.body) as Map<String, dynamic>;
      expect(body, {'device_token': 'fcm-token-123', 'platform': 'ios'});

      final event = decodeAuthHeader(req.headers['Authorization']!);
      expect(event.kind, NostrKind.httpAuth.value);
      expect(event.pubKey, keyPair.publicKey);
      expect(firstTag(event, 'method'), 'POST');
      expect(firstTag(event, 'u'), req.url.toString());
      expect(firstTag(event, 'payload'), isNotNull,
          reason: 'body present -> sha256 payload tag required');
      expect(Bip340.verify(event.id, event.sig, event.pubKey), isTrue);
      harness.service.dispose();
    });

    test('rejects empty FCM tokens before hitting the network', () async {
      final harness = buildService(
        handler: (_) => fail('should not make a request when fcmToken is empty'),
      );
      expect(
        () => harness.service.register(
          fcmToken: '   ',
          platform: NotifierPlatform.android,
        ),
        throwsArgumentError,
      );
      expect(harness.received, isEmpty);
      harness.service.dispose();
    });

    test('maps 4xx into HorcruxNotifierException with server message', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'rate limited'}),
          429,
          headers: {'content-type': 'application/json'},
        ),
      );

      try {
        await harness.service.register(
          fcmToken: 'abc',
          platform: NotifierPlatform.android,
        );
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.statusCode, 429);
        expect(e.isRateLimited, isTrue);
        expect(e.message, 'rate limited');
      }
      harness.service.dispose();
    });

    test('wraps transport failures as statusCode 0', () async {
      final harness = buildService(
        handler: (_) => throw const SocketExceptionLike('connection refused'),
      );
      try {
        await harness.service.register(
          fcmToken: 'abc',
          platform: NotifierPlatform.android,
        );
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.statusCode, 0);
        expect(e.isTransport, isTrue);
        expect(e.message, contains('connection refused'));
      }
      harness.service.dispose();
    });

    test('propagates an auth failure when no Nostr key is available', () async {
      when(loginService.getStoredNostrKey()).thenAnswer((_) async => null);
      final harness = buildService(
        handler: (_) => fail('should not send without a signing key'),
      );
      try {
        await harness.service.register(
          fcmToken: 'abc',
          platform: NotifierPlatform.android,
        );
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.statusCode, 0);
        expect(e.message, contains('No Nostr key'));
      }
      expect(harness.received, isEmpty);
      harness.service.dispose();
    });
  });

  group('deregister', () {
    test('DELETEs /register with NIP-98 and no body', () async {
      final harness = buildService(
        handler: (_) => http.Response('', 204),
      );
      await harness.service.deregister();

      final req = harness.received.single;
      expect(req.method, 'DELETE');
      expect(req.body, isEmpty);
      expect(req.headers.containsKey('Content-Type'), isFalse);

      final event = decodeAuthHeader(req.headers['Authorization']!);
      expect(firstTag(event, 'method'), 'DELETE');
      expect(firstTag(event, 'payload'), isNull, reason: 'no body -> no payload tag');
      harness.service.dispose();
    });

    test('swallows 404 (idempotent)', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'not found'}),
          404,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.deregister(); // Must not throw.
      harness.service.dispose();
    });

    test('still throws on 401', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'bad signature'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );
      try {
        await harness.service.deregister();
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.isUnauthorized, isTrue);
        expect(e.message, 'bad signature');
      }
      harness.service.dispose();
    });
  });

  test('updateToken is a POST /register with the new token', () async {
    final harness = buildService(
      handler: (_) => http.Response('{}', 200, headers: {'content-type': 'application/json'}),
    );
    await harness.service.updateToken(
      newToken: 'rotated-token',
      platform: NotifierPlatform.android,
    );
    final req = harness.received.single;
    expect(req.method, 'POST');
    expect(req.url.path, '/register');
    expect(
      json.decode(req.body),
      {'device_token': 'rotated-token', 'platform': 'android'},
    );
    harness.service.dispose();
  });

  group('replaceConsents', () {
    test('PUTs /consent with authorized_senders', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({
            'authorized_senders': ['a' * 64]
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.replaceConsents(['a' * 64, 'b' * 64]);

      final req = harness.received.single;
      expect(req.method, 'PUT');
      expect(req.url.path, '/consent');
      expect(json.decode(req.body), {
        'authorized_senders': ['a' * 64, 'b' * 64],
      });

      final event = decodeAuthHeader(req.headers['Authorization']!);
      expect(firstTag(event, 'method'), 'PUT');
      harness.service.dispose();
    });
  });

  group('deleteConsent', () {
    test('DELETEs /consent/{sender}', () async {
      final harness = buildService(
        handler: (_) => http.Response('', 204),
      );
      final sender = 'c' * 64;
      await harness.service.deleteConsent(sender);

      final req = harness.received.single;
      expect(req.method, 'DELETE');
      expect(req.url.path, '/consent/$sender');
      harness.service.dispose();
    });

    test('treats 404 as success (idempotent)', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'not found'}),
          404,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.deleteConsent('d' * 64); // Must not throw.
      harness.service.dispose();
    });
  });

  group('push', () {
    test('POSTs /push with full payload when event_json is provided', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'status': 'queued', 'fcm_message_id': 'fcm-xyz'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      await harness.service.push(
        recipientPubkey: 'e' * 64,
        title: 'Alice needs your help',
        body: 'Recovery of Family Vault requires your key.',
        eventJson: const {'id': 'deadbeef', 'kind': 1059},
        relayHints: const ['wss://relay.example.com'],
      );

      final req = harness.received.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/push');
      expect(json.decode(req.body), {
        'recipient_pubkey': 'e' * 64,
        'title': 'Alice needs your help',
        'body': 'Recovery of Family Vault requires your key.',
        'event_json': {'id': 'deadbeef', 'kind': 1059},
        'relay_hints': ['wss://relay.example.com'],
      });
      harness.service.dispose();
    });

    test('includes only event_id when event_json is omitted', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'status': 'queued', 'fcm_message_id': 'id'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.push(
        recipientPubkey: 'f' * 64,
        title: 't',
        body: 'b',
        eventId: '0' * 64,
      );
      final body = json.decode(harness.received.single.body) as Map<String, dynamic>;
      expect(body.containsKey('event_json'), isFalse);
      expect(body.containsKey('relay_hints'), isFalse);
      expect(body['event_id'], '0' * 64);
      harness.service.dispose();
    });

    test('surfaces forbidden responses as HorcruxNotifierException', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'recipient has not authorized this sender'}),
          403,
          headers: {'content-type': 'application/json'},
        ),
      );
      try {
        await harness.service.push(
          recipientPubkey: 'a' * 64,
          title: 't',
          body: 'b',
          eventId: '1' * 64,
        );
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.isForbidden, isTrue);
        expect(e.message, contains('not authorized'));
      }
      harness.service.dispose();
    });
  });
}

/// Simple stand-in for a transport-level failure; the service only cares
/// that the client throws, not about the concrete type.
class SocketExceptionLike implements Exception {
  final String message;
  const SocketExceptionLike(this.message);
  @override
  String toString() => 'SocketException: $message';
}
