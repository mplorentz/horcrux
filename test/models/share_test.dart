import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/utils/date_time_extensions.dart';

import '../fixtures/test_keys.dart';

Share _validRealShare() {
  return Share(
    payload: 'not-empty-payload',
    threshold: 2,
    shareIndex: 0,
    totalShares: 3,
    primeMod: 'abc',
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
        primeMod: 'abc',
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(m.isManifest, isTrue);

      expect(_validRealShare().isManifest, isFalse);
      expect(
        Share(
          payload: '',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          primeMod: 'abc',
          creatorPubkey: 'a' * 64,
          createdAt: secondsSinceEpoch(),
        ).isManifest,
        isFalse,
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
        primeMod: 'abc',
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
        primeMod: 'abc',
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
        primeMod: 'abc',
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
        primeMod: 'abc',
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
      expect(shardData.primeMod, validJsonFixture['prime_mod']);
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
        expect(shardData.primeMod, validJsonWithRecoveryMetadata['prime_mod']);
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
        expect(
          shardData.recipientPubkey,
          validJsonWithRecoveryMetadata['recipient_pubkey'],
        );
        expect(
          shardData.isReceived,
          validJsonWithRecoveryMetadata['is_received'],
        );
        expect(
          shardData.receivedAt,
          DateTime.parse(validJsonWithRecoveryMetadata['received_at'] as String),
        );
        expect(
          shardData.nostrEventId,
          validJsonWithRecoveryMetadata['nostr_event_id'],
        );
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
      expect(json['creator_pubkey'], validJsonFixture['creator_pubkey']);
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
        expect(
          json['creator_pubkey'],
          validJsonWithRecoveryMetadata['creator_pubkey'],
        );
        expect(json['created_at'], validJsonWithRecoveryMetadata['created_at']);
        expect(json['vault_id'], validJsonWithRecoveryMetadata['vault_id']);
        expect(json['vault_name'], validJsonWithRecoveryMetadata['vault_name']);
        expect(json['stewards'], isNotNull);
        expect(json['stewards'], isA<List>());
        expect(json['owner_name'], 'Owner');
        expect(
          json['recipient_pubkey'],
          validJsonWithRecoveryMetadata['recipient_pubkey'],
        );
        expect(json['is_received'], validJsonWithRecoveryMetadata['is_received']);
        expect(json['received_at'], validJsonWithRecoveryMetadata['received_at']);
        expect(
          json['nostr_event_id'],
          validJsonWithRecoveryMetadata['nostr_event_id'],
        );
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
      expect(decodedShare.primeMod, originalShare.primeMod);
      expect(decodedShare.creatorPubkey, originalShare.creatorPubkey);
      expect(decodedShare.createdAt, originalShare.createdAt);
      expect(decodedShare.vaultId, originalShare.vaultId);
      expect(decodedShare.vaultName, originalShare.vaultName);
      expect(decodedShare.stewards, isNotNull);
      expect(decodedShare.stewards!.length, originalShare.stewards!.length);
      expect(decodedShare.ownerName, originalShare.ownerName);
      expect(
        decodedShare.recipientPubkey,
        originalShare.recipientPubkey,
      );
      expect(decodedShare.isReceived, originalShare.isReceived);
      expect(decodedShare.receivedAt, originalShare.receivedAt);
      expect(decodedShare.nostrEventId, originalShare.nostrEventId);
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
        primeMod: 'ZmZmZmZmZmZmZg==',
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
          primeMod: 'abc',
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
          primeMod: 'abc',
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
          primeMod: 'abc',
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
          primeMod: 'abc',
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
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShare validates empty primeMod', () {
      expect(
        () => createShare(
          payload: 'abc123',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          primeMod: '', // Empty
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
          primeMod: 'abc',
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
          primeMod: 'abc',
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
          primeMod: 'abc',
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
          primeMod: 'abc',
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
        primeMod: 'abc',
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
        primeMod: 'QW5vdGhlckJhc2U2NFN0cmluZ0hlcmU=',
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
        primeMod: 'xyz',
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      final copy = original.copyWith(threshold: 3, shareIndex: 1);

      expect(copy.threshold, equals(3));
      expect(copy.shareIndex, equals(1));
      expect(copy.payload, equals(original.payload));
      expect(copy.totalShares, equals(original.totalShares));
      expect(copy.primeMod, equals(original.primeMod));
      expect(copy.creatorPubkey, equals(original.creatorPubkey));
    });

    test('ageInSeconds calculates correctly', () {
      final pastTimestamp = secondsSinceEpoch() - 3600; // 1 hour ago
      final Share shardData = Share(
        payload: 'abc',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        primeMod: 'xyz',
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
        primeMod: 'xyz',
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
        primeMod: 'xyz',
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
        primeMod: 'xyz',
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
        primeMod: 'xyz',
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      final str = shareToString(shardData);

      expect(str, contains('Share'));
      expect(str, contains('1/3')); // shardIndex/totalShards
      expect(str, contains('threshold: 2'));
      expect(str, contains('a11ac73f')); // First 8 chars of pubkey
    });
  });

  group('Share.pushEnabled wire format', () {
    const creatorPubkey = 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437';

    Share buildShard({bool? pushEnabled}) {
      return createShare(
        payload: 'abc123',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        primeMod: 'xyz',
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
}
