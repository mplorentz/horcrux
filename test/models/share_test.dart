import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/utils/date_time_extensions.dart';
import 'package:ndk/ndk.dart';

import '../fixtures/test_keys.dart';

Share _validRealShare() {
  return Share(
    payload: 'not-empty-payload',
    threshold: 2,
    shareIndex: 0,
    totalShares: 3,
    scheme: null,
    creatorPubkey: 'a' * 64,
    createdAt: secondsSinceEpoch(),
    vaultId: 'vault-1',
  );
}

void main() {
  group('Share.isManifest', () {
    test('true only for empty payload and shareIndex -1', () {
      final m = Share(
        payload: '',
        threshold: 2,
        shareIndex: -1,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(m.isManifest, isTrue);

      expect(_validRealShare().isManifest, isFalse);
      // Empty payload with shareIndex 0 is also a manifest now.
      expect(
        Share(
          payload: '',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a' * 64,
          createdAt: secondsSinceEpoch(),
        ).isManifest,
        isTrue,
      );
    });
  });

  group('Share.isValid manifest', () {
    test('accepts manifest-shaped share', () {
      final m = Share(
        payload: '',
        threshold: 2,
        shareIndex: -1,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
        stewards: [
          {'name': 'Bob', 'pubkey': 'b' * 64},
        ],
      );
      expect(m.isValid, isTrue);
    });

    test('rejects empty payload unless manifest', () {
      final bad = Share(
        payload: '',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(bad.isValid, isFalse);
    });

    test('rejects manifest with wrong shareIndex', () {
      final bad = Share(
        payload: 'x',
        threshold: 2,
        shareIndex: -2,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(bad.isValid, isFalse);
    });

    test('rejects manifest with shareIndex -1 but non-empty payload', () {
      final bad = Share(
        payload: 'x',
        threshold: 2,
        shareIndex: -1,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(bad.isValid, isFalse);
    });
  });

  group('Share JSON Serialization', () {
    late Map<String, dynamic> validJsonFixture;
    late Map<String, dynamic> validJsonWithRecoveryMetadata;

    setUp(() {
      // Base fixture: snake_case Nostr / wire format
      validJsonFixture = {
        'shard':
            'J93z0EN6ZfWwx3j6zb4_YpxquwyZhSmVmrWCkwqtzR4=dGVzdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        'threshold': 1,
        'shard_index': 0,
        'total_shards': 1,
        'prime_mod':
            'ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmY0Mw==',
        'creator_pubkey': 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        'created_at': 1759759657,
      };

      // Extended fixture with recovery metadata
      validJsonWithRecoveryMetadata = {
        ...validJsonFixture,
        'vault_id': 'vault-abc-456',
        'vault_name': 'Shared Vault Test',
        'stewards': [
          {
            'name': 'Alice',
            'pubkey': 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
          },
          {
            'name': 'Bob',
            'pubkey': 'b22bd84f68f94fa53fa9cdf624ef663ccdeb4c7260d9f0ab97d7254f1d9c8454',
          },
          {
            'name': 'Charlie',
            'pubkey': 'c33ce95f79fa5ab64fa0def735fa774ddfc5d8371e0a1bc08e8263a2e0d9546',
          },
        ],
        'owner_name': 'Owner',
        'recipient_pubkey': 'b22bd84f68f94fa53fa9cdf624ef663ccdeb4c7260d9f0ab97d7254f1d9c8454',
        'is_received': true,
        'received_at': '2025-02-06T12:00:00.000Z',
        'nostr_event_id': 'event-xyz-789',
      };
    });

    test('shareFromJson creates valid Share from minimal JSON', () {
      final shardData = shareFromJson(validJsonFixture);

      expect(shardData.payload, validJsonFixture['shard']);
      expect(shardData.threshold, validJsonFixture['threshold']);
      expect(shardData.shareIndex, validJsonFixture['shard_index']);
      expect(shardData.totalShares, validJsonFixture['total_shards']);
      expect(shardData.scheme, validJsonFixture['prime_mod']);
      expect(shardData.creatorPubkey, validJsonFixture['creator_pubkey']);
      expect(shardData.createdAt, validJsonFixture['created_at']);
      expect(shardData.vaultId, isNull);
      expect(shardData.vaultName, isNull);
      expect(shardData.stewards, isNull);
      expect(shardData.recipientPubkey, isNull);
      expect(shardData.isReceived, isNull);
      expect(shardData.receivedAt, isNull);
      expect(shardData.nostrEventId, isNull);
    });

    test('shareFromJson normalizes embedded stewards from loose wire JSON', () {
      final json = {
        ...validJsonFixture,
        'shard_index': 1,
        'total_shards': 3,
        'threshold': 2,
        'vault_id': 'vault-wire-stewards',
        'stewards': [
          {
            'name': 'Alice',
            'pubKey': TestHexPubkeys.alice,
            'shard_index': 0,
            'contact_info': 'alice@example.test',
          },
          {
            'name': 'Bob',
            'pubkey': TestHexPubkeys.bob,
            'shardIndex': 2,
          },
        ],
      };

      final shardData = shareFromJson(json);

      expect(shardData.stewards, hasLength(2));
      expect(shardData.stewards![0]['pubkey'], TestHexPubkeys.alice);
      expect(shardData.stewards![0]['shard_index'], '0');
      expect(shardData.stewards![0]['contactInfo'], 'alice@example.test');
      expect(shardData.stewards![1]['shard_index'], '2');
      expect(shardData.isValid, isTrue);
    });

    test(
      'shareFromJson creates valid Share with recovery metadata',
      () {
        final shardData = shareFromJson(validJsonWithRecoveryMetadata);

        expect(shardData.payload, validJsonWithRecoveryMetadata['shard']);
        expect(shardData.threshold, validJsonWithRecoveryMetadata['threshold']);
        expect(
          shardData.shareIndex,
          validJsonWithRecoveryMetadata['shard_index'],
        );
        expect(
          shardData.totalShares,
          validJsonWithRecoveryMetadata['total_shards'],
        );
        expect(shardData.scheme, validJsonWithRecoveryMetadata['prime_mod']);
        expect(
          shardData.creatorPubkey,
          validJsonWithRecoveryMetadata['creator_pubkey'],
        );
        expect(shardData.createdAt, validJsonWithRecoveryMetadata['created_at']);
        expect(shardData.vaultId, validJsonWithRecoveryMetadata['vault_id']);
        expect(shardData.vaultName, validJsonWithRecoveryMetadata['vault_name']);
        expect(shardData.stewards, isNotNull);
        expect(shardData.stewards!.length, 3);
        expect(shardData.stewards![0]['name'], 'Alice');
        expect(
          shardData.stewards![0]['pubkey'],
          'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        );
        expect(shardData.ownerName, 'Owner');
        expect(shardData.recipientPubkey, isNull,
            reason: 'recipientPubkey is not in wire JSON anymore');
        expect(shardData.isReceived, isNull, reason: 'isReceived is not in wire JSON anymore');
        expect(shardData.receivedAt, isNull, reason: 'receivedAt is not in wire JSON anymore');
        expect(shardData.nostrEventId, isNull, reason: 'nostrEventId is not in wire JSON anymore');
      },
    );

    test('shareToJson encodes minimal Share correctly', () {
      final shardData = shareFromJson(validJsonFixture);
      final json = shareToJson(shardData);

      expect(json['shard'], validJsonFixture['shard']);
      expect(json['threshold'], validJsonFixture['threshold']);
      expect(json['shard_index'], validJsonFixture['shard_index']);
      expect(json['total_shards'], validJsonFixture['total_shards']);
      expect(json['prime_mod'], validJsonFixture['prime_mod']);
      expect(json.containsKey('creator_pubkey'), isFalse,
          reason: 'creator_pubkey no longer emitted on wire');
      expect(json['created_at'], validJsonFixture['created_at']);
      expect(json.containsKey('vault_id'), isFalse);
      expect(json.containsKey('vault_name'), isFalse);
      expect(json.containsKey('stewards'), isFalse);
      expect(json.containsKey('recipient_pubkey'), isFalse);
      expect(json.containsKey('is_received'), isFalse);
      expect(json.containsKey('received_at'), isFalse);
      expect(json.containsKey('nostr_event_id'), isFalse);
    });

    test(
      'shareToJson encodes Share with recovery metadata correctly',
      () {
        final shardData = shareFromJson(validJsonWithRecoveryMetadata);
        final json = shareToJson(shardData);

        expect(json['shard'], validJsonWithRecoveryMetadata['shard']);
        expect(json['threshold'], validJsonWithRecoveryMetadata['threshold']);
        expect(json['shard_index'], validJsonWithRecoveryMetadata['shard_index']);
        expect(
          json['total_shards'],
          validJsonWithRecoveryMetadata['total_shards'],
        );
        expect(json['prime_mod'], validJsonWithRecoveryMetadata['prime_mod']);
        expect(json.containsKey('creator_pubkey'), isFalse,
            reason: 'creator_pubkey no longer emitted on wire');
        expect(json['created_at'], validJsonWithRecoveryMetadata['created_at']);
        expect(json['vault_id'], validJsonWithRecoveryMetadata['vault_id']);
        expect(json['vault_name'], validJsonWithRecoveryMetadata['vault_name']);
        expect(json['stewards'], isNotNull);
        expect(json['stewards'], isA<List>());
        expect(json['owner_name'], 'Owner');
        expect(json.containsKey('recipient_pubkey'), isFalse,
            reason: 'recipientPubkey no longer serialized to wire JSON');
        expect(json.containsKey('is_received'), isFalse,
            reason: 'isReceived no longer serialized to wire JSON');
        expect(json.containsKey('received_at'), isFalse,
            reason: 'receivedAt no longer serialized to wire JSON');
        expect(json.containsKey('nostr_event_id'), isFalse,
            reason: 'nostrEventId no longer serialized to wire JSON');
      },
    );

    test('round-trip encoding and decoding preserves data', () {
      final originalShare = shareFromJson(
        validJsonWithRecoveryMetadata,
      );
      final json = shareToJson(originalShare);
      final decodedShare = shareFromJson(json);

      expect(decodedShare.payload, originalShare.payload);
      expect(decodedShare.threshold, originalShare.threshold);
      expect(decodedShare.shareIndex, originalShare.shareIndex);
      expect(decodedShare.totalShares, originalShare.totalShares);
      expect(decodedShare.scheme, originalShare.scheme);
      // creatorPubkey is not serialized to wire JSON anymore
      expect(decodedShare.creatorPubkey, isEmpty,
          reason: 'creatorPubkey is not in wire JSON anymore');
      expect(decodedShare.createdAt, originalShare.createdAt);
      expect(decodedShare.vaultId, originalShare.vaultId);
      expect(decodedShare.vaultName, originalShare.vaultName);
      expect(decodedShare.stewards, isNotNull);
      expect(decodedShare.stewards!.length, originalShare.stewards!.length);
      expect(decodedShare.ownerName, originalShare.ownerName);
      expect(decodedShare.recipientPubkey, isNull,
          reason: 'recipientPubkey is not in wire JSON anymore');
      expect(decodedShare.isReceived, isNull, reason: 'isReceived is not in wire JSON anymore');
      expect(decodedShare.receivedAt, isNull, reason: 'receivedAt is not in wire JSON anymore');
      expect(decodedShare.nostrEventId, isNull, reason: 'nostrEventId is not in wire JSON anymore');
    });

    test('round-trip preserves null scheme through JSON serialization', () {
      // Bug 3: null scheme must not be coerced to 'gf256_v1' on re-serialization.
      // Create a JSON fixture with neither 'scheme' nor 'prime_mod'
      final noSchemeJson = <String, dynamic>{
        'shard': 'dGVzdA==',
        'threshold': 2,
        'shard_index': 0,
        'total_shards': 3,
        'creator_pubkey': 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        'created_at': 1759759657,
      };

      final share = shareFromJson(noSchemeJson);
      // Legacy share with no scheme should have null scheme
      expect(share.scheme, isNull, reason: 'legacy share without scheme should have null scheme');

      // Re-serialize and verify null is preserved
      final json = shareToJson(share);
      expect(json.containsKey('scheme'), isFalse,
          reason: 'null scheme must not appear in serialized JSON');

      final decodedShare = shareFromJson(json);
      expect(decodedShare.scheme, isNull, reason: 'null scheme round-trip must preserve null');
    });

    test('shareFromJson handles null receivedAt correctly', () {
      final jsonWithoutReceivedAt = {...validJsonWithRecoveryMetadata};
      jsonWithoutReceivedAt.remove('received_at');

      final shardData = shareFromJson(jsonWithoutReceivedAt);

      expect(shardData.receivedAt, isNull);
      expect(shardData.vaultId, isNotNull);
      expect(shardData.vaultName, isNotNull);
    });

    test('shareFromJson throws on missing required fields', () {
      final invalidJson = {
        'shard': 'abc123',
        'threshold': 2,
        // Missing shard_index, total_shards, prime_mod, creator_pubkey, created_at
      };

      expect(() => shareFromJson(invalidJson), throwsA(isA<TypeError>()));
    });

    test('shareFromJson rejects camelCase keys (use snake_case wire format)', () {
      final legacy = {
        'shard': validJsonFixture['shard'],
        'threshold': 1,
        'shareIndex': 0,
        'totalShards': 1,
        'primeMod': validJsonFixture['prime_mod'],
        'creatorPubkey': validJsonFixture['creator_pubkey'],
        'createdAt': validJsonFixture['created_at'],
        'vaultId': 'v1',
      };
      expect(() => shareFromJson(legacy), throwsA(isA<TypeError>()));
    });

    test('shareToJson omits null optional fields', () {
      final minimalShare = shareFromJson(validJsonFixture);
      final json = shareToJson(minimalShare);

      expect(json.containsKey('vault_id'), isFalse);
      expect(json.containsKey('vault_name'), isFalse);
      expect(json.containsKey('recipient_pubkey'), isFalse);
      expect(json.containsKey('is_received'), isFalse);
      expect(json.containsKey('received_at'), isFalse);
      expect(json.containsKey('nostr_event_id'), isFalse);
    });
  });

  group('Share Validation', () {
    test('createShare creates valid Share with minimal fields', () {
      final shardData = createShare(
        payload: 'J93z0EN6ZfWwx3j6zb4_YpxquwyZhSmVmrWCkwqtzR4=',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      expect(shardData.payload, isNotEmpty);
      expect(shardData.threshold, equals(2));
      expect(shardData.shareIndex, equals(0));
      expect(shardData.totalShares, equals(3));
      expect(shardData.createdAt, greaterThan(0));
    });

    test('createShare validates empty shard', () {
      expect(
        () => createShare(
          payload: '',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates threshold too low', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 0, // Too low
          shareIndex: 0,
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates threshold greater than totalShards', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 5, // Greater than totalShards
          shareIndex: 0,
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates shardIndex negative', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 2,
          shareIndex: -1, // Negative
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates shardIndex >= totalShards', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 2,
          shareIndex: 3, // >= totalShards
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates empty scheme', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          scheme: '', // Empty scheme string
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates empty creatorPubkey', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          scheme: null,
          creatorPubkey: '', // Empty
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates recipientPubkey hex format', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
          recipientPubkey: 'not-hex', // Invalid hex
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates recipientPubkey length', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
          recipientPubkey: 'abcd1234', // Too short
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates receivedAt in past', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));

      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          scheme: null,
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
          isReceived: true,
          receivedAt: futureDate, // Future date
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare accepts valid recipientPubkey', () {
      final shardData = createShare(
        payload: 'abc123',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        recipientPubkey: 'b22bd84f68f94fa53fa9cdf624ef663ccdeb4c7260d9f0ab97d7254f1d9c8454',
      );

      expect(shardData.recipientPubkey, isNotNull);
      expect(shardData.recipientPubkey!.length, equals(64));
    });

    test('isValid returns true for valid Share', () {
      final shardData = createShare(
        payload: 'SGVsbG9Xb3JsZFRlc3RCYXNlNjRTdHJpbmc=',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      expect(shardData.isValid, isTrue);
    });
  });

  group('Share Utility Methods', () {
    test('copyShare creates copy with updated fields', () {
      final original = createShare(
        payload: 'abc123',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      final copy = original.copyWith(threshold: 3, shareIndex: 1);

      expect(copy.threshold, equals(3));
      expect(copy.shareIndex, equals(1));
      expect(copy.payload, equals(original.payload));
      expect(copy.totalShares, equals(original.totalShares));
      expect(copy.scheme, equals(original.scheme));
      expect(copy.creatorPubkey, equals(original.creatorPubkey));
    });

    test('ageInSeconds calculates correctly', () {
      final pastTimestamp = secondsSinceEpoch() - 3600; // 1 hour ago
      final Share shardData = Share(
        payload: 'abc',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        createdAt: pastTimestamp,
        vaultId: null,
        vaultName: null,
        stewards: null,
        ownerName: null,
        instructions: null,
        recipientPubkey: null,
        isReceived: null,
        receivedAt: null,
        nostrEventId: null,
        relayUrls: null,
        distributionVersion: null,
      );

      expect(shardData.ageInSeconds, greaterThanOrEqualTo(3600));
      expect(shardData.ageInSeconds, lessThan(3700)); // Allow some margin
    });

    test('ageInHours calculates correctly', () {
      final pastTimestamp = secondsSinceEpoch() - 7200; // 2 hours ago
      final Share shardData = Share(
        payload: 'abc',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        createdAt: pastTimestamp,
        vaultId: null,
        vaultName: null,
        stewards: null,
        ownerName: null,
        instructions: null,
        recipientPubkey: null,
        isReceived: null,
        receivedAt: null,
        nostrEventId: null,
        relayUrls: null,
        distributionVersion: null,
      );

      expect(shardData.ageInHours, greaterThanOrEqualTo(2.0));
      expect(shardData.ageInHours, lessThan(2.1)); // Allow some margin
    });

    test('isRecent returns true for recent shard', () {
      final recentTimestamp = secondsSinceEpoch() - 3600; // 1 hour ago
      final Share shardData = Share(
        payload: 'abc',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        createdAt: recentTimestamp,
        vaultId: null,
        vaultName: null,
        stewards: null,
        ownerName: null,
        instructions: null,
        recipientPubkey: null,
        isReceived: null,
        receivedAt: null,
        nostrEventId: null,
        relayUrls: null,
        distributionVersion: null,
      );

      expect(shardData.isRecent, isTrue);
    });

    test('isRecent returns false for old shard', () {
      final oldTimestamp = secondsSinceEpoch() - 86400 - 3600; // >24 hours ago
      final Share shardData = Share(
        payload: 'abc',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        createdAt: oldTimestamp,
        vaultId: null,
        vaultName: null,
        stewards: null,
        ownerName: null,
        instructions: null,
        recipientPubkey: null,
        isReceived: null,
        receivedAt: null,
        nostrEventId: null,
        relayUrls: null,
        distributionVersion: null,
      );

      expect(shardData.isRecent, isFalse);
    });

    test('shareToString formats correctly', () {
      final shardData = createShare(
        payload: 'abc123',
        threshold: 2,
        shareIndex: 1,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      final str = shareToString(shardData);

      expect(str, contains('Share'));
      expect(str, contains('1/3')); // shardIndex/totalShards
      expect(str, contains('threshold: 2'));
      expect(str, contains('a11ac73f')); // First 8 chars of pubkey
    });
  });

  group('latestShare', () {
    Share heldStyleShare({
      required int shareIndex,
      required int distributionVersion,
      required int createdAt,
      DateTime? receivedAt,
    }) {
      return Share(
        payload: 'p$shareIndex',
        threshold: 2,
        shareIndex: shareIndex,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: createdAt,
        distributionVersion: distributionVersion,
        receivedAt: receivedAt,
      );
    }

    test('higher distributionVersion wins', () {
      final v1 = heldStyleShare(
        shareIndex: 0,
        distributionVersion: 1,
        createdAt: 200,
        receivedAt: null,
      );
      final v3 = heldStyleShare(
        shareIndex: 1,
        distributionVersion: 3,
        createdAt: 100,
        receivedAt: null,
      );
      expect(latestShare([v1, v3]), v3);
      expect(latestShare([v3, v1]), v3);
    });

    test('same distributionVersion picks later receivedAt when createdAt ties', () {
      final early = heldStyleShare(
        shareIndex: 0,
        distributionVersion: 4,
        createdAt: 1700000000,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final late = heldStyleShare(
        shareIndex: 1,
        distributionVersion: 4,
        createdAt: 1700000000,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(9000),
      );
      expect(latestShare([early, late]), late);
      expect(latestShare([late, early]), late);
    });

    test('same version without receivedAt falls back to createdAt', () {
      final older = heldStyleShare(
        shareIndex: 0,
        distributionVersion: 2,
        createdAt: 100,
        receivedAt: null,
      );
      final newer = heldStyleShare(
        shareIndex: 1,
        distributionVersion: 2,
        createdAt: 200,
        receivedAt: null,
      );
      expect(latestShare([older, newer]), newer);
    });

    test(
      'same version with only one receivedAt uses createdAt (not one-sided receivedAt)',
      () {
        final withReceived = heldStyleShare(
          shareIndex: 0,
          distributionVersion: 5,
          createdAt: 100,
          receivedAt: DateTime.fromMillisecondsSinceEpoch(5000),
        );
        final wireOnly = heldStyleShare(
          shareIndex: 1,
          distributionVersion: 5,
          createdAt: 200,
          receivedAt: null,
        );
        expect(latestShare([withReceived, wireOnly]), wireOnly);
        expect(latestShare([wireOnly, withReceived]), wireOnly);
      },
    );
  });

  group('Share.pushEnabled wire format', () {
    const creatorPubkey = 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437';

    Share buildShard({bool? pushEnabled}) {
      return createShare(
        payload: 'abc123',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: creatorPubkey,
        vaultId: 'vault-1',
        vaultName: 'My Vault',
        pushEnabled: pushEnabled,
      );
    }

    test('defaults to null when not supplied', () {
      expect(buildShard().pushEnabled, isNull);
    });

    test('toJson omits push_enabled when null (legacy shard)', () {
      final json = shareToJson(buildShard());
      expect(json.containsKey('push_enabled'), isFalse);
    });

    test('toJson emits push_enabled=true when set', () {
      final json = shareToJson(buildShard(pushEnabled: true));
      expect(json['push_enabled'], isTrue);
    });

    test('toJson emits push_enabled=false when explicitly opted-out', () {
      // We care about the difference between "unspecified" (legacy) and
      // "explicitly false" (owner flipped it off). Both end up having the
      // receiver keep its previous value, but the wire format should still
      // distinguish them so future behaviour can rely on it.
      final json = shareToJson(buildShard(pushEnabled: false));
      expect(json['push_enabled'], isFalse);
    });

    test('fromJson round-trips true/false/null', () {
      for (final value in [true, false, null]) {
        final encoded = shareToJson(buildShard(pushEnabled: value));
        final decoded = shareFromJson(encoded);
        expect(decoded.pushEnabled, value, reason: 'for $value');
      }
    });

    test('fromJson on a legacy JSON (no push_enabled key) yields null', () {
      final legacyJson = <String, dynamic>{
        'shard': 'abc123',
        'threshold': 2,
        'shard_index': 0,
        'total_shards': 3,
        'prime_mod': 'xyz',
        'creator_pubkey': creatorPubkey,
        'created_at': 1759759657,
        // push_enabled intentionally absent.
      };
      final decoded = shareFromJson(legacyJson);
      expect(decoded.pushEnabled, isNull);
    });
  });

  group('Nostr wire format - shareToNostrTags', () {
    const creatorPubkey = 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437';

    Share sampleShare({bool withStewards = false, bool withRelays = false, bool withPush = false}) {
      return Share(
        payload: 'raw-shamir-payload',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: 'gf256_v1',
        creatorPubkey: creatorPubkey,
        createdAt: 1759759657,
        vaultId: 'vault-1',
        vaultName: 'My Vault',
        ownerName: 'Alice',
        instructions: 'Keep this safe',
        distributionVersion: 1,
        pushEnabled: withPush ? true : null,
        stewards: withStewards
            ? [
                {'name': 'Bob', 'pubkey': 'b' * 64, 'contactInfo': 'bob@test'},
                {'name': 'Charlie', 'pubkey': 'c' * 64},
              ]
            : null,
        relayUrls: withRelays ? ['wss://relay1.com', 'wss://relay2.com'] : null,
      );
    }

    test('includes required tags', () {
      final tags = shareToNostrTags(sampleShare());
      expect(tags.any((t) => t[0] == 'share_index' && t[1] == '0'), isTrue,
          reason: 'should have share_index tag');
      expect(tags.any((t) => t[0] == 'total_shares' && t[1] == '3'), isTrue,
          reason: 'should have total_shares tag');
      expect(tags.any((t) => t[0] == 'threshold' && t[1] == '2'), isTrue,
          reason: 'should have threshold tag');
      expect(tags.any((t) => t[0] == 'scheme' && t[1] == 'gf256_v1'), isTrue,
          reason: 'should have scheme tag');
    });

    test('includes optional string tags when present', () {
      final tags = shareToNostrTags(sampleShare());
      expect(tags.any((t) => t[0] == 'vault_id' && t[1] == 'vault-1'), isTrue);
      expect(tags.any((t) => t[0] == 'vault_name' && t[1] == 'My Vault'), isTrue);
      expect(tags.any((t) => t[0] == 'owner_name' && t[1] == 'Alice'), isTrue);
      expect(tags.any((t) => t[0] == 'instructions' && t[1] == 'Keep this safe'), isTrue);
    });

    test('includes distribution_version when present', () {
      final tags = shareToNostrTags(sampleShare());
      expect(tags.any((t) => t[0] == 'distribution_version' && t[1] == '1'), isTrue);
    });

    test('includes push_enabled when present', () {
      final tags = shareToNostrTags(sampleShare(withPush: true));
      expect(tags.any((t) => t[0] == 'push_enabled' && t[1] == 'true'), isTrue);
    });

    test('omits push_enabled when null', () {
      final tags = shareToNostrTags(sampleShare());
      expect(tags.any((t) => t[0] == 'push_enabled'), isFalse);
    });

    test('includes repeated steward tags', () {
      final tags = shareToNostrTags(sampleShare(withStewards: true));
      expect(
        tags.any((t) =>
            t[0] == 'steward' &&
            t[1] == '0' &&
            t[2] == 'Bob' &&
            t[3] == 'b' * 64 &&
            t[4] == 'bob@test'),
        isTrue,
        reason: 'should have Bob steward tag',
      );
      expect(
        tags.any((t) =>
            t[0] == 'steward' &&
            t[1] == '1' &&
            t[2] == 'Charlie' &&
            t[3] == 'c' * 64 &&
            t[4] == ''),
        isTrue,
        reason: 'should have Charlie steward tag',
      );
    });

    test('includes repeated relay tags', () {
      final tags = shareToNostrTags(sampleShare(withRelays: true));
      expect(tags.any((t) => t[0] == 'relay' && t[1] == 'wss://relay1.com'), isTrue);
      expect(tags.any((t) => t[0] == 'relay' && t[1] == 'wss://relay2.com'), isTrue);
    });

    test('omits optional tags when null', () {
      const share = Share(
        payload: 'p',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: creatorPubkey,
        createdAt: 1759759657,
      );
      final tags = shareToNostrTags(share);
      expect(tags.any((t) => t[0] == 'vault_id'), isFalse);
      expect(tags.any((t) => t[0] == 'vault_name'), isFalse);
      expect(tags.any((t) => t[0] == 'owner_name'), isFalse);
      expect(tags.any((t) => t[0] == 'steward'), isFalse);
      expect(tags.any((t) => t[0] == 'relay'), isFalse);
      expect(tags.any((t) => t[0] == 'distribution_version'), isFalse);
      expect(tags.any((t) => t[0] == 'push_enabled'), isFalse);
    });
  });

  group('Nostr wire format - shareToNostrContent', () {
    test('returns payload for normal share', () {
      final share = Share(
        payload: 'shamir-data',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: 1759759657,
      );
      expect(shareToNostrContent(share), 'shamir-data');
    });

    test('returns empty string for manifest share', () {
      final share = Share(
        payload: '',
        threshold: 2,
        shareIndex: -1,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: 1759759657,
      );
      expect(shareToNostrContent(share), '');
    });

    test('empty payload with shareIndex 0 is also manifest', () {
      final share = Share(
        payload: '',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: 1759759657,
      );
      expect(shareToNostrContent(share), '');
    });
  });

  group('Nostr wire format - shareFromNostr', () {
    const creatorPubkey = 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437';

    Nip01Event makeRumor({
      required String content,
      List<List<String>> tags = const [],
      String pubKey = creatorPubkey,
      int createdAt = 1759759657,
    }) {
      return Nip01Event(
        pubKey: pubKey,
        kind: 1337,
        tags: tags,
        content: content,
        createdAt: createdAt,
      );
    }

    test('parses required tags and content from rumor', () {
      final rumor = makeRumor(
        content: 'shamir-data',
        tags: [
          ['share_index', '2'],
          ['total_shares', '5'],
          ['threshold', '3'],
          ['prime_mod', 'xyz789'],
        ],
      );
      final share = shareFromNostr(rumor, recipientPubkey: 'r' * 64);

      expect(share.payload, 'shamir-data');
      expect(share.shareIndex, 2);
      expect(share.totalShares, 5);
      expect(share.threshold, 3);
      expect(share.scheme, 'xyz789');
      expect(share.creatorPubkey, creatorPubkey);
      expect(share.createdAt, 1759759657);
      expect(share.recipientPubkey, 'r' * 64);
      expect(share.isManifest, isFalse);
    });

    test('parses manifest from empty content', () {
      final rumor = makeRumor(
        content: '',
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
        ],
      );
      final share = shareFromNostr(rumor);

      expect(share.payload, '');
      expect(share.isManifest, isTrue);
    });

    test('parses optional string tags', () {
      final rumor = makeRumor(
        content: 'data',
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
          ['vault_id', 'vault-42'],
          ['vault_name', 'Secret Vault'],
          ['owner_name', 'Alice'],
          ['instructions', 'Handle with care'],
        ],
      );
      final share = shareFromNostr(rumor);

      expect(share.vaultId, 'vault-42');
      expect(share.vaultName, 'Secret Vault');
      expect(share.ownerName, 'Alice');
      expect(share.instructions, 'Handle with care');
    });

    test('parses distribution_version and push_enabled', () {
      final rumor = makeRumor(
        content: 'data',
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
          ['distribution_version', '5'],
          ['push_enabled', 'true'],
        ],
      );
      final share = shareFromNostr(rumor);

      expect(share.distributionVersion, 5);
      expect(share.pushEnabled, isTrue);
    });

    test('parses repeated steward tags', () {
      final rumor = makeRumor(
        content: 'data',
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
          ['steward', '0', 'Bob', 'b' * 64, 'bob@test'],
          ['steward', '1', 'Charlie', 'c' * 64, ''],
        ],
      );
      final share = shareFromNostr(rumor);

      expect(share.stewards, hasLength(2));
      expect(share.stewards![0]['name'], 'Bob');
      expect(share.stewards![0]['pubkey'], 'b' * 64);
      expect(share.stewards![0]['contactInfo'], 'bob@test');
      expect(share.stewards![1]['name'], 'Charlie');
      expect(share.stewards![1]['pubkey'], 'c' * 64);
    });

    test('parses repeated relay tags', () {
      final rumor = makeRumor(
        content: 'data',
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
          ['relay', 'wss://relay1.com'],
          ['relay', 'wss://relay2.com'],
        ],
      );
      final share = shareFromNostr(rumor);

      expect(share.relayUrls, hasLength(2));
      expect(share.relayUrls![0], 'wss://relay1.com');
      expect(share.relayUrls![1], 'wss://relay2.com');
    });

    test('sets null for absent optional fields', () {
      final rumor = makeRumor(
        content: 'data',
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
        ],
      );
      final share = shareFromNostr(rumor);

      expect(share.vaultId, isNull);
      expect(share.vaultName, isNull);
      expect(share.ownerName, isNull);
      expect(share.instructions, isNull);
      expect(share.stewards, isNull);
      expect(share.relayUrls, isNull);
      expect(share.distributionVersion, isNull);
      expect(share.pushEnabled, isNull);
      expect(share.recipientPubkey, isNull);
    });

    test('uses rumor.pubKey as creatorPubkey', () {
      final rumor = makeRumor(
        content: 'data',
        pubKey: 'b' * 64,
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['prime_mod', 'abc'],
        ],
      );
      final share = shareFromNostr(rumor);

      expect(share.creatorPubkey, 'b' * 64);
    });
  });

  group('Nostr wire format - round trip', () {
    const creatorPubkey = 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437';

    test('shareToNostrTags + shareToNostrContent -> shareFromNostr round-trips', () {
      final original = Share(
        payload: 'shamir-secret-data',
        threshold: 3,
        shareIndex: 1,
        totalShares: 5,
        scheme: null,
        creatorPubkey: creatorPubkey,
        createdAt: 1759759657,
        vaultId: 'vault-1',
        vaultName: 'My Vault',
        ownerName: 'Alice',
        instructions: 'Keep safe',
        distributionVersion: 2,
        pushEnabled: true,
        stewards: [
          {'name': 'Bob', 'pubkey': 'b' * 64, 'contactInfo': 'bob@test'},
        ],
        relayUrls: ['wss://relay1.com'],
      );

      final tags = shareToNostrTags(original);
      final content = shareToNostrContent(original);

      final rumor = Nip01Event(
        pubKey: creatorPubkey,
        kind: 1337,
        tags: tags,
        content: content,
        createdAt: 1759759657,
      );

      final decoded = shareFromNostr(rumor, recipientPubkey: 'r' * 64);

      expect(decoded.payload, original.payload);
      expect(decoded.threshold, original.threshold);
      expect(decoded.shareIndex, original.shareIndex);
      expect(decoded.totalShares, original.totalShares);
      // null scheme must be preserved through Nostr round-trip
      expect(decoded.scheme, isNull);
      expect(decoded.creatorPubkey, original.creatorPubkey);
      expect(decoded.createdAt, original.createdAt);
      expect(decoded.vaultId, original.vaultId);
      expect(decoded.vaultName, original.vaultName);
      expect(decoded.ownerName, original.ownerName);
      expect(decoded.instructions, original.instructions);
      expect(decoded.distributionVersion, original.distributionVersion);
      expect(decoded.pushEnabled, original.pushEnabled);
      expect(decoded.recipientPubkey, 'r' * 64);
      expect(decoded.stewards, hasLength(1));
      expect(decoded.stewards![0]['name'], 'Bob');
      expect(decoded.stewards![0]['pubkey'], 'b' * 64);
      expect(decoded.stewards![0]['contactInfo'], 'bob@test');
      expect(decoded.relayUrls, hasLength(1));
      expect(decoded.relayUrls![0], 'wss://relay1.com');
    });

    test('manifest round-trip', () {
      final original = Share(
        payload: '',
        threshold: 2,
        shareIndex: -1,
        totalShares: 3,
        scheme: null,
        creatorPubkey: creatorPubkey,
        createdAt: 1759759657,
        vaultId: 'vault-m',
        vaultName: 'Manifest Vault',
        ownerName: 'Alice',
        stewards: [
          {'name': 'Bob', 'pubkey': 'b' * 64},
        ],
      );

      final tags = shareToNostrTags(original);
      final content = shareToNostrContent(original);

      expect(content, '');

      final rumor = Nip01Event(
        pubKey: creatorPubkey,
        kind: 1337,
        tags: tags,
        content: content,
        createdAt: 1759759657,
      );

      final decoded = shareFromNostr(rumor);

      expect(decoded.isManifest, isTrue);
      expect(decoded.payload, '');
      expect(decoded.vaultId, 'vault-m');
      expect(decoded.stewards, hasLength(1));
    });
  });

  group('Nostr wire format - stewardToNostrTag', () {
    test('produces steward tag with slot', () {
      final tag = stewardToNostrTag(
        {'name': 'Bob', 'pubkey': 'b' * 64, 'contactInfo': 'bob@test'},
        slot: '0',
      );
      expect(tag, orderedEquals(['steward', '0', 'Bob', 'b' * 64, 'bob@test']));
    });

    test('produces steward tag without slot', () {
      final tag = stewardToNostrTag(
        {'name': 'Alice', 'pubkey': 'a' * 64},
      );
      expect(tag, orderedEquals(['steward', 'Alice', 'a' * 64, '']));
    });

    test('handles missing contactInfo', () {
      final tag = stewardToNostrTag(
        {'name': 'Charlie', 'pubkey': 'c' * 64},
        slot: '2',
      );
      expect(tag, orderedEquals(['steward', '2', 'Charlie', 'c' * 64, '']));
    });
  });

  group('Share.isValid edge cases', () {
    Share baseShare() {
      return Share(
        payload: 'abc123',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
    }

    test('isValid returns false for zero threshold', () {
      final share = baseShare().copyWith(threshold: 0);
      expect(share.isValid, isFalse);
    });

    test('isValid returns false for negative createdAt', () {
      final share = baseShare().copyWith(createdAt: -1);
      expect(share.isValid, isFalse);
    });

    test('isValid returns false for empty scheme', () {
      final share = baseShare().copyWith(scheme: '');
      expect(share.isValid, isFalse);
    });

    test('isValid returns false for empty creatorPubkey', () {
      final share = baseShare().copyWith(creatorPubkey: '');
      expect(share.isValid, isFalse);
    });

    test('isValid returns false for shareIndex >= totalShares', () {
      final share = baseShare().copyWith(shareIndex: 3, totalShares: 3);
      expect(share.isValid, isFalse);
    });

    test('isValid returns false when steward pubkey is not 64-char hex', () {
      final share = baseShare().copyWith(stewards: [
        {'name': 'Alice', 'pubkey': 'tooshort'},
      ]);
      expect(share.isValid, isFalse);
    });

    test('isValid returns false when steward name is empty', () {
      final share = baseShare().copyWith(stewards: [
        {'name': '', 'pubkey': 'b' * 64},
      ]);
      expect(share.isValid, isFalse);
    });

    test('isValid returns false when steward contactInfo exceeds 500 chars', () {
      final share = baseShare().copyWith(stewards: [
        {
          'name': 'Alice',
          'pubkey': 'b' * 64,
          'contactInfo': 'x' * 501,
        },
      ]);
      expect(share.isValid, isFalse);
    });

    test('isValid returns false for negative steward shard_index', () {
      final share = baseShare().copyWith(stewards: [
        {
          'name': 'Alice',
          'pubkey': 'b' * 64,
          'shard_index': '-1',
        },
      ]);
      expect(share.isValid, isFalse);
    });

    test('isValid returns true for steward with valid optional contactInfo', () {
      final share = baseShare().copyWith(stewards: [
        {
          'name': 'Alice',
          'pubkey': 'b' * 64,
          'contactInfo': 'alice@example.test',
        },
      ]);
      expect(share.isValid, isTrue);
    });

    test('shareFromJson reads distributionVersion as int or num', () {
      final asInt = shareFromJson({
        'shard': 'abc',
        'threshold': 2,
        'shard_index': 0,
        'total_shards': 3,
        'prime_mod': 'xyz',
        'creator_pubkey': 'a' * 64,
        'created_at': 1759759657,
        'distribution_version': 5,
      });
      expect(asInt.distributionVersion, 5);

      // Pass a double to test the num -> int path in _readIntFlexible
      final asNum = shareFromJson({
        'shard': 'abc',
        'threshold': 2,
        'shard_index': 0,
        'total_shards': 3,
        'prime_mod': 'xyz',
        'creator_pubkey': 'a' * 64,
        'created_at': 1759759657,
        'distribution_version': 5.0,
      });
      expect(asNum.distributionVersion, 5);
    });

    test('shareFromJson ignores legacy is_received wire key', () {
      final legacy = shareFromJson({
        'shard': 'abc',
        'threshold': 2,
        'shard_index': 0,
        'total_shards': 3,
        'prime_mod': 'xyz',
        'creator_pubkey': 'a' * 64,
        'created_at': 1759759657,
        'is_received': true,
      });
      expect(legacy.isReceived, isNull);
    });

    test('shareFromJson throws on non-int threshold', () {
      expect(
        () => shareFromJson({
          'shard': 'abc',
          'threshold': 'not-a-number',
          'shard_index': 0,
          'total_shards': 3,
          'prime_mod': 'xyz',
          'creator_pubkey': 'a' * 64,
          'created_at': 1759759657,
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('blob (AEAD ciphertext)', () {
    const creatorPubkey = 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437';
    const sampleBlob = 'AAECAwQFBgcICQoLDA0ODw=='; // arbitrary base64

    test('JSON round-trip preserves blob', () {
      const share = Share(
        payload: 'k-share',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: 'gf256_v1',
        blob: sampleBlob,
        creatorPubkey: creatorPubkey,
        createdAt: 1759759657,
      );
      final decoded = shareFromJson(shareToJson(share));
      expect(decoded.blob, equals(sampleBlob));
    });

    test('shareToJson omits blob when null', () {
      const share = Share(
        payload: 'k-share',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: creatorPubkey,
        createdAt: 1759759657,
      );
      expect(shareToJson(share).containsKey('blob'), isFalse);
    });

    test('Nostr tag round-trip preserves blob', () {
      const share = Share(
        payload: 'k-share',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: 'gf256_v1',
        blob: sampleBlob,
        creatorPubkey: creatorPubkey,
        createdAt: 1759759657,
        vaultId: 'vault-x',
      );
      final tags = shareToNostrTags(share);
      // Sanity: emitted as a single 2-tuple tag.
      final blobTag = tags.firstWhere((t) => t[0] == 'blob');
      expect(blobTag, equals(['blob', sampleBlob]));

      final rumor = Nip01Event(
        pubKey: creatorPubkey,
        kind: 1337,
        tags: tags,
        content: shareToNostrContent(share),
        createdAt: 1759759657,
      );
      final decoded = shareFromNostr(rumor);
      expect(decoded.blob, equals(sampleBlob));
    });

    test('shareToNostrTags omits blob tag when null', () {
      const share = Share(
        payload: 'k-share',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: 'gf256_v1',
        creatorPubkey: creatorPubkey,
        createdAt: 1759759657,
        vaultId: 'vault-x',
      );
      final tags = shareToNostrTags(share);
      expect(tags.any((t) => t[0] == 'blob'), isFalse);
    });

    test('shareFromNostr leaves blob null when tag is absent', () {
      final rumor = Nip01Event(
        pubKey: creatorPubkey,
        kind: 1337,
        tags: [
          ['share_index', '0'],
          ['total_shares', '3'],
          ['threshold', '2'],
          ['scheme', 'gf256_v1'],
        ],
        content: 'k-share',
        createdAt: 1759759657,
      );
      final decoded = shareFromNostr(rumor);
      expect(decoded.blob, isNull);
    });

    test('createShare accepts blob and stores it', () {
      final share = createShare(
        payload: 'k-share',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        creatorPubkey: creatorPubkey,
        scheme: 'gf256_v1',
        blob: sampleBlob,
      );
      expect(share.blob, equals(sampleBlob));
      expect(share.scheme, equals('gf256_v1'));
    });
  });
}
