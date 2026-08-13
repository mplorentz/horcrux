import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/models/invitation_link.dart';

import '../fixtures/test_keys.dart';

void main() {
  group('InvitationLink.toUrl', () {
    test(
      'emits the legacy path format (code in path, not query param)',
      () {
        final link = createInvitationLink(
          inviteCode: 'dGVzdF9pbnZpdGVfY29kZQ',
          vaultId: 'vault-123',
          vaultName: 'Ben\'s Super Secret Things',
          ownerPubkey: TestHexPubkeys.alice,
          ownerName: 'Alice',
          relayUrls: ['wss://relay.horcruxbackup.com'],
        );

        final url = link.toUrl();

        expect(
          url,
          'https://horcruxbackup.com/invite/dGVzdF9pbnZpdGVfY29kZQ'
          '?vault=vault-123'
          "&name=Ben's%20Super%20Secret%20Things"
          '&owner=${TestHexPubkeys.alice}'
          '&ownerName=Alice'
          '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
        );
      },
    );

    test('omits ownerName when null (existing behavior preserved)', () {
      final link = createInvitationLink(
        inviteCode: 'dGVzdF9pbnZpdGVfY29kZQ',
        vaultId: 'vault-123',
        vaultName: 'Shared Vault',
        ownerPubkey: TestHexPubkeys.alice,
        relayUrls: ['wss://relay.horcruxbackup.com'],
      );

      final url = link.toUrl();

      expect(url, isNot(contains('ownerName=')));
      expect(url, contains('dGVzdF9pbnZpdGVfY29kZQ'));
      expect(url, startsWith('https://horcruxbackup.com/invite/'));
      // Legacy format: code is in the path, not a query param.
      expect(url, isNot(contains('code=')));
    });

    test('omits ownerName when empty (existing behavior preserved)', () {
      final link = createInvitationLink(
        inviteCode: 'dGVzdF9pbnZpdGVfY29kZQ',
        vaultId: 'vault-123',
        vaultName: 'Shared Vault',
        ownerPubkey: TestHexPubkeys.alice,
        ownerName: '',
        relayUrls: ['wss://relay.horcruxbackup.com'],
      );

      final url = link.toUrl();

      expect(url, isNot(contains('ownerName=')));
    });

    test('encodes relay URLs comma-separated and percent-encoded', () {
      final link = createInvitationLink(
        inviteCode: 'dGVzdF9pbnZpdGVfY29kZQ',
        vaultId: 'vault-123',
        vaultName: 'Shared Vault',
        ownerPubkey: TestHexPubkeys.alice,
        relayUrls: [
          'wss://relay.horcruxbackup.com',
          'ws://localhost:10547',
        ],
      );

      final url = link.toUrl();

      expect(
        url,
        contains(
          'relays=wss%3A%2F%2Frelay.horcruxbackup.com,ws%3A%2F%2Flocalhost%3A10547',
        ),
      );
    });
  });

  group('InvitationLink.toNewFormatUrl', () {
    test(
      'emits the query-param format with code= as the first parameter',
      () {
        final link = createInvitationLink(
          inviteCode: 'dGVzdF9pbnZpdGVfY29kZQ',
          vaultId: 'vault-123',
          vaultName: 'Shared Vault',
          ownerPubkey: TestHexPubkeys.alice,
          relayUrls: ['wss://relay.horcruxbackup.com'],
        );

        final url = link.toNewFormatUrl();

        expect(
          url,
          'https://horcruxbackup.com/invite/'
          '?code=dGVzdF9pbnZpdGVfY29kZQ'
          '&vault=vault-123'
          '&name=Shared%20Vault'
          '&owner=${TestHexPubkeys.alice}'
          '&relays=wss%3A%2F%2Frelay.horcruxbackup.com',
        );
      },
    );
  });
}
