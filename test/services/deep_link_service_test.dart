import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/models/invitation_exceptions.dart';
import 'package:horcrux/services/deep_link_service.dart';
import '../fixtures/test_keys.dart';

void main() {
  late DeepLinkService service;

  setUp(() {
    service = DeepLinkService(
      getInvitationService: () => throw UnimplementedError(),
      getIsLoggedIn: () async => false,
    );
  });

  group('parseInvitationLink (new query-param format)', () {
    test(
      'parses new format /invite/?code=<code> and returns correct InvitationLinkData',
      () {
        final uri = Uri.parse(
          'https://horcruxbackup.com/invite/'
          '?code=dGVzdF9pbnZpdGVfY29kZQ'
          '&vault=vault-123'
          '&name=Ben%27s%20Super%20Secret%20Things'
          '&owner=${TestHexPubkeys.alice}'
          '&ownerName=Alice'
          '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
        );

        final result = service.parseInvitationLink(uri);

        expect(result, isNotNull);
        expect(result!.inviteCode, 'dGVzdF9pbnZpdGVfY29kZQ');
        expect(result.vaultId, 'vault-123');
        expect(result.vaultName, "Ben's Super Secret Things");
        expect(result.ownerPubkey, TestHexPubkeys.alice);
        expect(result.ownerName, 'Alice');
        expect(result.relayUrls, ['wss://relay.horcruxbackup.com']);
      },
    );

    test(
      'parses new format with horcrux:// custom scheme',
      () {
        final uri = Uri.parse(
          'horcrux://horcruxbackup.com/invite/'
          '?code=dGVzdF9pbnZpdGVfY29kZQ'
          '&vault=vault-123'
          '&name=Shared%20Vault'
          '&owner=${TestHexPubkeys.alice}'
          '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
        );

        final result = service.parseInvitationLink(uri);

        expect(result, isNotNull);
        expect(result!.inviteCode, 'dGVzdF9pbnZpdGVfY29kZQ');
        expect(result.vaultId, 'vault-123');
      },
    );
  });

  group('parseInvitationLink (legacy path format — backwards compatibility)', () {
    test(
      'still parses legacy format /invite/<code>',
      () {
        final uri = Uri.parse(
          'https://horcruxbackup.com/invite/dGVzdF9pbnZpdGVfY29kZQ'
          '?vault=vault-123'
          '&name=Shared%20Vault'
          '&owner=${TestHexPubkeys.alice}'
          '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
        );

        final result = service.parseInvitationLink(uri);

        expect(result, isNotNull);
        expect(result!.inviteCode, 'dGVzdF9pbnZpdGVfY29kZQ');
        expect(result.vaultId, 'vault-123');
        expect(result.vaultName, 'Shared Vault');
        expect(result.ownerPubkey, TestHexPubkeys.alice);
        expect(result.relayUrls, ['wss://relay.horcruxbackup.com']);
      },
    );

    test(
      'legacy format with horcrux:// custom scheme still works',
      () {
        final uri = Uri.parse(
          'horcrux://horcruxbackup.com/invite/dGVzdF9pbnZpdGVfY29kZQ'
          '?vault=vault-123'
          '&name=Shared%20Vault'
          '&owner=${TestHexPubkeys.alice}'
          '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
        );

        final result = service.parseInvitationLink(uri);

        expect(result, isNotNull);
        expect(result!.inviteCode, 'dGVzdF9pbnZpdGVfY29kZQ');
        expect(result.vaultId, 'vault-123');
      },
    );
  });

  group('parseInvitationLink (error cases)', () {
    test('throws InvalidInvitationLinkException when code is missing in both positions', () {
      final uri = Uri.parse(
        'https://horcruxbackup.com/invite/'
        '?vault=vault-123'
        '&name=Shared%20Vault'
        '&owner=${TestHexPubkeys.alice}'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(isA<InvalidInvitationLinkException>()),
      );
    });

    test('throws InvalidInvitationLinkException for invalid code format', () {
      final uri = Uri.parse(
        'https://horcruxbackup.com/invite/'
        '?code=!!invalid!!'
        '&vault=vault-123'
        '&name=Shared%20Vault'
        '&owner=${TestHexPubkeys.alice}'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(
          isA<InvalidInvitationLinkException>().having(
            (e) => e.reason,
            'reason',
            contains('Invalid invite code'),
          ),
        ),
      );
    });

    test('throws InvalidInvitationLinkException for non-/invite path with no code param', () {
      final uri = Uri.parse('https://horcruxbackup.com/some/other/path');

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(isA<InvalidInvitationLinkException>()),
      );
    });

    test('throws InvalidInvitationLinkException for unsupported scheme', () {
      final uri = Uri.parse(
        'ftp://horcruxbackup.com/invite/'
        '?code=dGVzdF9pbnZpdGVfY29kZQ'
        '&vault=vault-123'
        '&owner=${TestHexPubkeys.alice}'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(
          isA<InvalidInvitationLinkException>().having(
            (e) => e.reason,
            'reason',
            contains('Unsupported URL scheme'),
          ),
        ),
      );
    });

    test('throws InvalidInvitationLinkException for invalid host', () {
      final uri = Uri.parse(
        'https://malicious.example.com/invite/'
        '?code=dGVzdF9pbnZpdGVfY29kZQ'
        '&vault=vault-123'
        '&owner=${TestHexPubkeys.alice}'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(
          isA<InvalidInvitationLinkException>().having(
            (e) => e.reason,
            'reason',
            contains('Invalid host'),
          ),
        ),
      );
    });

    test('throws for missing owner pubkey', () {
      final uri = Uri.parse(
        'https://horcruxbackup.com/invite/'
        '?code=dGVzdF9pbnZpdGVfY29kZQ'
        '&vault=vault-123'
        '&name=Shared%20Vault'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(
          isA<InvalidInvitationLinkException>().having(
            (e) => e.reason,
            'reason',
            contains('Missing required parameter: owner'),
          ),
        ),
      );
    });

    test('throws for missing vault id', () {
      final uri = Uri.parse(
        'https://horcruxbackup.com/invite/'
        '?code=dGVzdF9pbnZpdGVfY29kZQ'
        '&name=Shared%20Vault'
        '&owner=${TestHexPubkeys.alice}'
        '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
      );

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(
          isA<InvalidInvitationLinkException>().having(
            (e) => e.reason,
            'reason',
            contains('Missing required parameter: vault'),
          ),
        ),
      );
    });

    test('throws for missing relay URLs', () {
      final uri = Uri.parse(
        'https://horcruxbackup.com/invite/'
        '?code=dGVzdF9pbnZpdGVfY29kZQ'
        '&vault=vault-123'
        '&name=Shared%20Vault'
        '&owner=${TestHexPubkeys.alice}',
      );

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(
          isA<InvalidInvitationLinkException>().having(
            (e) => e.reason,
            'reason',
            contains('No valid relay URLs'),
          ),
        ),
      );
    });

    test('rejects too many relay URLs (over 3)', () {
      final uri = Uri.parse(
        'https://horcruxbackup.com/invite/'
        '?code=dGVzdF9pbnZpdGVfY29kZQ'
        '&vault=vault-123'
        '&name=Shared%20Vault'
        '&owner=${TestHexPubkeys.alice}'
        '&relays=wss%3A%2F%2Frelay1.com%2Cwss%3A%2F%2Frelay2.com%2Cwss%3A%2F%2Frelay3.com%2Cwss%3A%2F%2Frelay4.com',
      );

      expect(
        () => service.parseInvitationLink(uri),
        throwsA(
          isA<InvalidInvitationLinkException>().having(
            (e) => e.reason,
            'reason',
            contains('Too many relay URLs'),
          ),
        ),
      );
    });
  });
}
