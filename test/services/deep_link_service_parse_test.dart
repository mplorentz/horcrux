import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/services/deep_link_service.dart';

/// [DeepLinkService.parseInvitationLink] must correctly parse invitation
/// links containing non-ASCII characters in the vault/owner name query
/// params. Regression coverage for a bug where a vault name containing an
/// iOS curly apostrophe (U+2019) caused parsing to throw
/// "Illegal percent encoding in URI".
///
/// `Uri.queryParameters` already URL-decodes values, so the code must not
/// call `Uri.decodeComponent` a second time on the name/ownerName params.
void main() {
  // A valid DeepLinkService. parseInvitationLink is synchronous and does not
  // touch the injected InvitationService, so throwaway callbacks suffice.
  DeepLinkService makeService() => DeepLinkService(
        getInvitationService: () => throw UnimplementedError(),
        getIsLoggedIn: () async => true,
      );

  const ownerPubkey = '704e34b4d4acd67c8f43ef8f0b0dc905b403bef96d8e94b88271355aef601d2d';

  group('parseInvitationLink', () {
    test('parses a vault name with an iOS curly apostrophe (U+2019)', () {
      // Reported failing URL: name=Ben%E2%80%99s%20Super%20Secret%20Things
      final url = Uri.parse(
        'https://horcruxbackup.com/invite/akEzcK5XMprOCTYy5ikiv6ZMeSHXnToekiSPd8DpJVU'
        '?vault=61_iV28zPv9UWnsMUDP8XfAepuZ9ipl5icDmOav786c'
        '&name=Ben%E2%80%99s%20Super%20Secret%20Things'
        '&owner=$ownerPubkey'
        '&ownerName=Ben%20Moody'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      final data = makeService().parseInvitationLink(url);

      expect(data, isNotNull);
      // U+2019 is the expected decoded value of %E2%80%99 (iOS curly apostrophe)
      expect(data!.vaultName, 'Ben’s Super Secret Things');
      expect(data.ownerName, 'Ben Moody');
    });

    test('parses an ASCII apostrophe vault name', () {
      final url = Uri.parse(
        'https://horcruxbackup.com/invite/akEzcK5XMprOCTYy5ikiv6ZMeSHXnToekiSPd8DpJVU'
        '?vault=vaultId'
        '&name=Ben%27s%20Secret%20Things'
        '&owner=$ownerPubkey'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      final data = makeService().parseInvitationLink(url);

      expect(data, isNotNull);
      expect(data!.vaultName, "Ben's Secret Things");
    });

    test('parses an empty vault name as null', () {
      final url = Uri.parse(
        'https://horcruxbackup.com/invite/akEzcK5XMprOCTYy5ikiv6ZMeSHXnToekiSPd8DpJVU'
        '?vault=vaultId'
        '&name='
        '&owner=$ownerPubkey'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      final data = makeService().parseInvitationLink(url);

      expect(data, isNotNull);
      expect(data!.vaultName, isNull);
    });

    test('parses an accented owner name', () {
      final url = Uri.parse(
        'https://horcruxbackup.com/invite/akEzcK5XMprOCTYy5ikiv6ZMeSHXnToekiSPd8DpJVU'
        '?vault=vaultId'
        '&name=My%20Vault'
        '&owner=$ownerPubkey'
        '&ownerName=Ren%C3%A9e%20M%C3%BCller'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      final data = makeService().parseInvitationLink(url);

      expect(data, isNotNull);
      expect(data!.ownerName, 'Renée Müller');
    });

    test('parses an emoji vault name', () {
      final url = Uri.parse(
        'https://horcruxbackup.com/invite/akEzcK5XMprOCTYy5ikiv6ZMeSHXnToekiSPd8DpJVU'
        '?vault=vaultId'
        '&name=%F0%9F%94%90%20Vault'
        '&owner=$ownerPubkey'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      final data = makeService().parseInvitationLink(url);

      expect(data, isNotNull);
      expect(data!.vaultName, '🔐 Vault');
    });

    test('falls back to null when owner name is absent', () {
      final url = Uri.parse(
        'https://horcruxbackup.com/invite/akEzcK5XMprOCTYy5ikiv6ZMeSHXnToekiSPd8DpJVU'
        '?vault=vaultId'
        '&name=My%20Vault'
        '&owner=$ownerPubkey'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      final data = makeService().parseInvitationLink(url);

      expect(data, isNotNull);
      expect(data!.ownerName, isNull);
      expect(data.vaultName, 'My Vault');
    });

    test('parses a relay URL with a non-ASCII (IDN/punycode) host', () {
      // A relay URL like wss://münchen.example.com is percent-encoded as
      // wss://m%C3%BCnchen.example.com by toUrl(). queryParameters decodes
      // this to the literal ü, so the parse must NOT call
      // Uri.decodeComponent a second time (which would throw for code > 127).
      final url = Uri.parse(
        'https://horcruxbackup.com/invite/akEzcK5XMprOCTYy5ikiv6ZMeSHXnToekiSPd8DpJVU'
        '?vault=vaultId'
        '&name=My%20Vault'
        '&owner=$ownerPubkey'
        '&relays=wss%3A%2F%2Fm%C3%BCnchen.example.com',
      );

      final data = makeService().parseInvitationLink(url);

      expect(data, isNotNull);
      expect(data!.relayUrls, hasLength(1));
      expect(data.relayUrls.first, 'wss://münchen.example.com');
    });

    test('parses multiple relay URLs with non-ASCII characters', () {
      final url = Uri.parse(
        'https://horcruxbackup.com/invite/akEzcK5XMprOCTYy5ikiv6ZMeSHXnToekiSPd8DpJVU'
        '?vault=vaultId'
        '&name=My%20Vault'
        '&owner=$ownerPubkey'
        '&relays=wss%3A%2F%2Frelay1.example.com%2Cwss%3A%2F%2Fm%C3%BCnchen.example.com',
      );

      expect(() => makeService().parseInvitationLink(url), returnsNormally);
    });
  });
}
