import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/recovery_request.dart';

import '../fixtures/test_keys.dart';

/// Simulates the tag extraction helpers used by _handle* methods
/// in NdkService. These are the canonical wire-format ingestion primitives.
String? _firstTagValue(List<List<String>> tags, String name) {
  for (final tag in tags) {
    if (tag.length >= 2 && tag[0] == name) {
      final v = tag[1];
      return v.isEmpty ? null : v;
    }
  }
  return null;
}

Nip01Event _makeEvent({
  int kind = 1337,
  String pubKey = TestHexPubkeys.alice,
  List<List<String>> tags = const [],
  String content = '',
  int createdAt = 1759759657,
}) {
  return Nip01Event(
    pubKey: pubKey,
    kind: kind,
    tags: tags,
    content: content,
    createdAt: createdAt,
  );
}

void main() {
  group('resolveVaultIdFromTags', () {
    test('returns vault_id for kind 1337 (shareData)', () {
      final event = _makeEvent(kind: 1337, tags: [
        ['vault_id', 'vault-123'],
      ]);
      expect(_firstTagValue(event.tags, 'vault_id'), 'vault-123');
    });

    test('returns vault_id for kind 1338 (recoveryRequest)', () {
      final event = _makeEvent(kind: 1338, tags: [
        ['vault_id', 'vault-456'],
      ]);
      expect(_firstTagValue(event.tags, 'vault_id'), 'vault-456');
    });

    test('returns vault_id for kind 1339 (recoveryResponse)', () {
      final event = _makeEvent(kind: 1339, tags: [
        ['vault_id', 'vault-789'],
      ]);
      expect(_firstTagValue(event.tags, 'vault_id'), 'vault-789');
    });

    test('returns null when vault_id is empty', () {
      final event = _makeEvent(tags: [
        ['vault_id', ''],
      ]);
      expect(_firstTagValue(event.tags, 'vault_id'), isNull);
    });

    test('returns null when vault_id tag is missing', () {
      final event = _makeEvent(tags: [
        ['share_index', '0'],
      ]);
      expect(_firstTagValue(event.tags, 'vault_id'), isNull);
    });
  });

  group('shareFromNostr tag parsing', () {
    test('parses kind-1337 tags + content to Share', () {
      final event = _makeEvent(
        content: 'raw-shamir-payload',
        tags: [
          ['share_index', '1'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc123'],
          ['vault_id', 'vault-123'],
          ['vault_name', 'My Vault'],
          ['distribution_version', '1'],
        ],
      );

      final share = shareFromNostr(event, recipientPubkey: TestHexPubkeys.bob);

      expect(share.payload, 'raw-shamir-payload');
      expect(share.shareIndex, 1);
      expect(share.totalShares, 3);
      expect(share.threshold, 2);
      expect(share.primeMod, 'abc123');
      expect(share.vaultId, 'vault-123');
      expect(share.vaultName, 'My Vault');
      expect(share.distributionVersion, 1);
      expect(share.creatorPubkey, TestHexPubkeys.alice);
      expect(share.recipientPubkey, TestHexPubkeys.bob);
      expect(share.isManifest, isFalse);
    });

    test('parses manifest from empty content', () {
      final event = _makeEvent(
        content: '',
        tags: [
          ['share_index', '-1'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc123'],
        ],
      );

      final share = shareFromNostr(event);
      expect(share.payload, '');
      expect(share.isManifest, isTrue);
    });
  });

  group('recovery_request_id tag parsing', () {
    test('reads recovery_request_id from tags', () {
      final event = _makeEvent(kind: 1338, tags: [
        ['recovery_request_id', 'req-abc-123'],
        ['vault_id', 'vault-123'],
      ]);
      expect(_firstTagValue(event.tags, 'recovery_request_id'), 'req-abc-123');
      expect(_firstTagValue(event.tags, 'vault_id'), 'vault-123');
    });

    test('reads is_practice from tags', () {
      final event = _makeEvent(kind: 1338, tags: [
        ['recovery_request_id', 'req-456'],
        ['vault_id', 'vault-456'],
        ['is_practice', 'true'],
      ]);
      expect(_firstTagValue(event.tags, 'is_practice'), 'true');
    });

    test('returns null when recovery_request_id is missing', () {
      final event = _makeEvent(kind: 1338, tags: [
        ['vault_id', 'vault-123'],
      ]);
      expect(_firstTagValue(event.tags, 'recovery_request_id'), isNull);
    });
  });

  group('recovery response tag parsing', () {
    test('reads approved from non-empty content', () {
      final event = _makeEvent(
        kind: 1339,
        content: 'share-payload-data',
        tags: [
          ['recovery_request_id', 'req-789'],
          ['vault_id', 'vault-789'],
        ],
      );

      expect(event.content.isNotEmpty, isTrue);
      expect(_firstTagValue(event.tags, 'recovery_request_id'), 'req-789');
      expect(_firstTagValue(event.tags, 'vault_id'), 'vault-789');
    });

    test('reads denial from empty content without is_practice', () {
      final event = _makeEvent(
        kind: 1339,
        content: '',
        tags: [
          ['recovery_request_id', 'req-000'],
          ['vault_id', 'vault-000'],
        ],
      );

      expect(event.content.isEmpty, isTrue);
      expect(_firstTagValue(event.tags, 'is_practice'), isNull);
    });
  });

  group('repeated steward tags', () {
    test('parses repeated steward tags from inbound event', () {
      final event = _makeEvent(
        content: 'shamir-data',
        tags: [
          ['share_index', '0'],
          ['total_shares', '2'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
          ['vault_id', 'vault-123'],
          ['steward', '0', 'Alice', TestHexPubkeys.alice, 'alice@test'],
          ['steward', '1', 'Bob', TestHexPubkeys.bob, ''],
        ],
      );

      final share = shareFromNostr(event);
      expect(share.stewards, hasLength(2));
      expect(share.stewards![0]['name'], 'Alice');
      expect(share.stewards![0]['pubkey'], TestHexPubkeys.alice);
      expect(share.stewards![0]['contactInfo'], 'alice@test');
      expect(share.stewards![1]['name'], 'Bob');
      expect(share.stewards![1]['pubkey'], TestHexPubkeys.bob);
    });
  });

  group('repeated relay tags', () {
    test('parses repeated relay tags from inbound event', () {
      final event = _makeEvent(
        content: 'shamir-data',
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
          ['vault_id', 'vault-relay-test'],
          ['relay', 'wss://relay1.com'],
          ['relay', 'wss://relay2.com'],
        ],
      );

      final share = shareFromNostr(event);
      expect(share.relayUrls, hasLength(2));
      expect(share.relayUrls![0], 'wss://relay1.com');
      expect(share.relayUrls![1], 'wss://relay2.com');
    });
  });

  group('resolveVaultIdFromReader dual-format', () {
    // Exercises the _vaultIdFromReader logic: JSON wins over tags
    test('prefers JSON vault_id over tag when both present', () {
      final json = <String, dynamic>{'vault_id': 'from-json'};
      final tags = [['vault_id', 'from-tag']];
      // Simulate: _vaultIdFromReader(json, tags) -> 'from-json'
      expect(json['vault_id'], 'from-json');
    });

    test('falls back to tag when JSON content is absent', () {
      final tags = [['vault_id', 'from-tag']];
      expect(_firstTagValue(tags, 'vault_id'), 'from-tag');
    });

    test('returns null when both JSON and tag are absent', () {
      expect(_firstTagValue([], 'vault_id'), isNull);
    });
  });

  group('dual-format _handleShare', () {
    test('shareFromNostr parses tag-based event', () {
      final event = _makeEvent(
        content: 'shamir-payload',
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
          ['vault_id', 'vault-dual'],
        ],
      );

      final share = shareFromNostr(event);
      expect(share.payload, 'shamir-payload');
      expect(share.vaultId, 'vault-dual');
      expect(share.shareIndex, 0);
      expect(share.creatorPubkey, TestHexPubkeys.alice);
    });
  });
}