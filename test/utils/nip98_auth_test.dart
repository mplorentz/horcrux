import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/utils/date_time_extensions.dart';
import 'package:horcrux/utils/nip98_auth.dart';

/// Round-trip a `Nostr <base64>` Authorization header back into a
/// [Nip01Event] for inspection, mirroring what a NIP-98 verifying server
/// would do.
Nip01Event _decodeHeader(String header) {
  expect(header.startsWith('Nostr '), isTrue, reason: 'header: $header');
  final encoded = header.substring('Nostr '.length);
  final jsonStr = utf8.decode(base64Decode(encoded));
  final map = json.decode(jsonStr) as Map<String, dynamic>;
  return Nip01Event.fromJson(map);
}

String? _firstTag(Nip01Event event, String name) {
  for (final tag in event.tags) {
    if (tag.isNotEmpty && tag[0] == name && tag.length > 1) {
      return tag[1];
    }
  }
  return null;
}

void main() {
  // Deterministic test key pair — fresh per test run via Bip340.
  late KeyPair keyPair;

  setUp(() {
    keyPair = Bip340.generatePrivateKey();
  });

  group('Nip98Auth.buildAuthorizationHeader', () {
    test('signs a kind-27235 event with u and method tags for a GET', () {
      final url = Uri.parse('https://notify.example.com/register');
      final header = Nip98Auth.buildAuthorizationHeader(
        keyPair: keyPair,
        method: 'GET',
        url: url,
      );

      final event = _decodeHeader(header);
      expect(event.kind, NostrKind.httpAuth.value);
      expect(event.content, '');
      expect(event.pubKey, keyPair.publicKey);
      expect(_firstTag(event, 'u'), url.toString());
      expect(_firstTag(event, 'method'), 'GET');
      expect(
        _firstTag(event, 'payload'),
        isNull,
        reason: 'GET has no body, so no payload tag',
      );
      expect(event.isIdValid, isTrue, reason: 'event id must match content');
      expect(
        Bip340.verify(event.id, event.sig, event.pubKey),
        isTrue,
        reason: 'signature must verify against pubkey',
      );
    });

    test('adds sha256 payload tag when body is present', () {
      final body = utf8.encode('{"device_token":"abc","platform":"ios"}');
      final expectedDigest = sha256.convert(body).toString();

      final header = Nip98Auth.buildAuthorizationHeader(
        keyPair: keyPair,
        method: 'post',
        url: Uri.parse('https://notify.example.com/register'),
        body: body,
      );

      final event = _decodeHeader(header);
      expect(
        _firstTag(event, 'method'),
        'POST',
        reason: 'method tag must be upper-cased',
      );
      expect(_firstTag(event, 'payload'), expectedDigest);
    });

    test('omits payload tag when body is empty', () {
      final header = Nip98Auth.buildAuthorizationHeader(
        keyPair: keyPair,
        method: 'DELETE',
        url: Uri.parse('https://notify.example.com/register'),
        body: const <int>[],
      );

      final event = _decodeHeader(header);
      expect(_firstTag(event, 'payload'), isNull);
      expect(_firstTag(event, 'method'), 'DELETE');
    });

    test('uses provided createdAt (seconds) when supplied', () {
      final pinned = DateTime.utc(2026, 4, 21, 12, 30, 45);
      final header = Nip98Auth.buildAuthorizationHeader(
        keyPair: keyPair,
        method: 'GET',
        url: Uri.parse('https://notify.example.com/health'),
        createdAt: pinned,
      );

      final event = _decodeHeader(header);
      expect(event.createdAt, pinned.secondsSinceEpoch);
    });

    test('preserves URL exactly including query string', () {
      final url = Uri.parse(
        'https://notify.example.com/consent/abc123?foo=bar&baz=qux',
      );
      final header = Nip98Auth.buildAuthorizationHeader(
        keyPair: keyPair,
        method: 'DELETE',
        url: url,
      );

      final event = _decodeHeader(header);
      expect(_firstTag(event, 'u'), url.toString());
    });

    test('produces distinct signatures across calls', () {
      final url = Uri.parse('https://notify.example.com/push');
      final h1 = Nip98Auth.buildAuthorizationHeader(
        keyPair: keyPair,
        method: 'POST',
        url: url,
      );
      // Force a different createdAt so the event id (and hence sig) differs
      // deterministically even if the two calls land in the same second.
      final h2 = Nip98Auth.buildAuthorizationHeader(
        keyPair: keyPair,
        method: 'POST',
        url: url,
        createdAt: DateTime.now().add(const Duration(seconds: 5)),
      );
      expect(h1, isNot(equals(h2)));
    });

    test('throws ArgumentError for a public-key-only key pair', () {
      final readOnly = KeyPair.justPublicKey(keyPair.publicKey);
      expect(
        () => Nip98Auth.buildAuthorizationHeader(
          keyPair: readOnly,
          method: 'GET',
          url: Uri.parse('https://notify.example.com/health'),
        ),
        throwsArgumentError,
      );
    });
  });
}
