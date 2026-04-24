import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/utils/date_time_extensions.dart';

void main() {
  group('ShardData JSON Serialization', () {
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

    test('shardDataFromJson creates valid ShardData from minimal JSON', () {
      final shardData = shardDataFromJson(validJsonFixture);

      expect(shardData.shard, validJsonFixture['shard']);
      expect(shardData.threshold, validJsonFixture['threshold']);
      expect(shardData.shardIndex, validJsonFixture['shard_index']);
      expect(shardData.totalShards, validJsonFixture['total_shards']);
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

    test(
      'shardDataFromJson creates valid ShardData with recovery metadata',
      () {
        final shardData = shardDataFromJson(validJsonWithRecoveryMetadata);

        expect(shardData.shard, validJsonWithRecoveryMetadata['shard']);
        expect(shardData.threshold, validJsonWithRecoveryMetadata['threshold']);
        expect(
          shardData.shardIndex,
          validJsonWithRecoveryMetadata['shard_index'],
        );
        expect(
          shardData.totalShards,
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

    test('shardDataToJson encodes minimal ShardData correctly', () {
      final shardData = shardDataFromJson(validJsonFixture);
      final json = shardDataToJson(shardData);

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
      'shardDataToJson encodes ShardData with recovery metadata correctly',
      () {
        final shardData = shardDataFromJson(validJsonWithRecoveryMetadata);
        final json = shardDataToJson(shardData);

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
      final originalShardData = shardDataFromJson(
        validJsonWithRecoveryMetadata,
      );
      final json = shardDataToJson(originalShardData);
      final decodedShardData = shardDataFromJson(json);

      expect(decodedShardData.shard, originalShardData.shard);
      expect(decodedShardData.threshold, originalShardData.threshold);
      expect(decodedShardData.shardIndex, originalShardData.shardIndex);
      expect(decodedShardData.totalShards, originalShardData.totalShards);
      expect(decodedShardData.primeMod, originalShardData.primeMod);
      expect(decodedShardData.creatorPubkey, originalShardData.creatorPubkey);
      expect(decodedShardData.createdAt, originalShardData.createdAt);
      expect(decodedShardData.vaultId, originalShardData.vaultId);
      expect(decodedShardData.vaultName, originalShardData.vaultName);
      expect(decodedShardData.stewards, isNotNull);
      expect(decodedShardData.stewards!.length, originalShardData.stewards!.length);
      expect(decodedShardData.ownerName, originalShardData.ownerName);
      expect(
        decodedShardData.recipientPubkey,
        originalShardData.recipientPubkey,
      );
      expect(decodedShardData.isReceived, originalShardData.isReceived);
      expect(decodedShardData.receivedAt, originalShardData.receivedAt);
      expect(decodedShardData.nostrEventId, originalShardData.nostrEventId);
    });

    test('shardDataFromJson handles null receivedAt correctly', () {
      final jsonWithoutReceivedAt = {...validJsonWithRecoveryMetadata};
      jsonWithoutReceivedAt.remove('received_at');

      final shardData = shardDataFromJson(jsonWithoutReceivedAt);

      expect(shardData.receivedAt, isNull);
      expect(shardData.vaultId, isNotNull);
      expect(shardData.vaultName, isNotNull);
    });

    test('shardDataFromJson throws on missing required fields', () {
      final invalidJson = {
        'shard': 'abc123',
        'threshold': 2,
        // Missing shard_index, total_shards, prime_mod, creator_pubkey, created_at
      };

      expect(() => shardDataFromJson(invalidJson), throwsA(isA<TypeError>()));
    });

    test('shardDataFromJson accepts legacy camelCase keys', () {
      final legacy = {
        'shard': validJsonFixture['shard'],
        'threshold': 1,
        'shardIndex': 0,
        'totalShards': 1,
        'primeMod': validJsonFixture['prime_mod'],
        'creatorPubkey': validJsonFixture['creator_pubkey'],
        'createdAt': validJsonFixture['created_at'],
        'vaultId': 'v1',
      };
      final shardData = shardDataFromJson(legacy);
      expect(shardData.vaultId, 'v1');
      expect(shardData.shardIndex, 0);
    });

    test('shardDataToJson omits null optional fields', () {
      final minimalShardData = shardDataFromJson(validJsonFixture);
      final json = shardDataToJson(minimalShardData);

      expect(json.containsKey('vault_id'), isFalse);
      expect(json.containsKey('vault_name'), isFalse);
      expect(json.containsKey('recipient_pubkey'), isFalse);
      expect(json.containsKey('is_received'), isFalse);
      expect(json.containsKey('received_at'), isFalse);
      expect(json.containsKey('nostr_event_id'), isFalse);
    });
  });

  group('ShardData Validation', () {
    test('createShardData creates valid ShardData with minimal fields', () {
      final shardData = createShardData(
        shard: 'J93z0EN6ZfWwx3j6zb4_YpxquwyZhSmVmrWCkwqtzR4=',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'ZmZmZmZmZmZmZg==',
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      expect(shardData.shard, isNotEmpty);
      expect(shardData.threshold, equals(2));
      expect(shardData.shardIndex, equals(0));
      expect(shardData.totalShards, equals(3));
      expect(shardData.createdAt, greaterThan(0));
    });

    test('createShardData validates empty shard', () {
      expect(
        () => createShardData(
          shard: '',
          threshold: 2,
          shardIndex: 0,
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates threshold too low', () {
      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 0, // Too low
          shardIndex: 0,
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates threshold greater than totalShards', () {
      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 5, // Greater than totalShards
          shardIndex: 0,
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates shardIndex negative', () {
      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 2,
          shardIndex: -1, // Negative
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates shardIndex >= totalShards', () {
      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 2,
          shardIndex: 3, // >= totalShards
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates empty primeMod', () {
      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 2,
          shardIndex: 0,
          totalShards: 3,
          primeMod: '', // Empty
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates empty creatorPubkey', () {
      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 2,
          shardIndex: 0,
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: '', // Empty
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates recipientPubkey hex format', () {
      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 2,
          shardIndex: 0,
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
          recipientPubkey: 'not-hex', // Invalid hex
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates recipientPubkey length', () {
      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 2,
          shardIndex: 0,
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
          recipientPubkey: 'abcd1234', // Too short
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData validates receivedAt in past', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));

      expect(
        () => createShardData(
          shard: 'abc123',
          threshold: 2,
          shardIndex: 0,
          totalShards: 3,
          primeMod: 'abc',
          creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
          isReceived: true,
          receivedAt: futureDate, // Future date
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createShardData accepts valid recipientPubkey', () {
      final shardData = createShardData(
        shard: 'abc123',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'abc',
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        recipientPubkey: 'b22bd84f68f94fa53fa9cdf624ef663ccdeb4c7260d9f0ab97d7254f1d9c8454',
      );

      expect(shardData.recipientPubkey, isNotNull);
      expect(shardData.recipientPubkey!.length, equals(64));
    });

    test('isValid returns true for valid ShardData', () {
      final shardData = createShardData(
        shard: 'SGVsbG9Xb3JsZFRlc3RCYXNlNjRTdHJpbmc=',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'QW5vdGhlckJhc2U2NFN0cmluZ0hlcmU=',
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      expect(shardData.isValid, isTrue);
    });
  });

  group('ShardData Utility Methods', () {
    test('copyShardData creates copy with updated fields', () {
      final original = createShardData(
        shard: 'abc123',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'xyz',
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      final copy = original.copyWith(threshold: 3, shardIndex: 1);

      expect(copy.threshold, equals(3));
      expect(copy.shardIndex, equals(1));
      expect(copy.shard, equals(original.shard));
      expect(copy.totalShards, equals(original.totalShards));
      expect(copy.primeMod, equals(original.primeMod));
      expect(copy.creatorPubkey, equals(original.creatorPubkey));
    });

    test('ageInSeconds calculates correctly', () {
      final pastTimestamp = secondsSinceEpoch() - 3600; // 1 hour ago
      final ShardData shardData = ShardData(
        shard: 'abc',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
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
      final ShardData shardData = ShardData(
        shard: 'abc',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
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
      final ShardData shardData = ShardData(
        shard: 'abc',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
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
      final ShardData shardData = ShardData(
        shard: 'abc',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
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

    test('shardDataToString formats correctly', () {
      final shardData = createShardData(
        shard: 'abc123',
        threshold: 2,
        shardIndex: 1,
        totalShards: 3,
        primeMod: 'xyz',
        creatorPubkey: 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
      );

      final str = shardDataToString(shardData);

      expect(str, contains('ShardData'));
      expect(str, contains('1/3')); // shardIndex/totalShards
      expect(str, contains('threshold: 2'));
      expect(str, contains('a11ac73f')); // First 8 chars of pubkey
    });
  });

  group('ShardData.pushEnabled wire format', () {
    const creatorPubkey = 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437';

    ShardData buildShard({bool? pushEnabled}) {
      return createShardData(
        shard: 'abc123',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
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
      final json = shardDataToJson(buildShard());
      expect(json.containsKey('push_enabled'), isFalse);
    });

    test('toJson emits push_enabled=true when set', () {
      final json = shardDataToJson(buildShard(pushEnabled: true));
      expect(json['push_enabled'], isTrue);
    });

    test('toJson emits push_enabled=false when explicitly opted-out', () {
      // We care about the difference between "unspecified" (legacy) and
      // "explicitly false" (owner flipped it off). Both end up having the
      // receiver keep its previous value, but the wire format should still
      // distinguish them so future behaviour can rely on it.
      final json = shardDataToJson(buildShard(pushEnabled: false));
      expect(json['push_enabled'], isFalse);
    });

    test('fromJson round-trips true/false/null', () {
      for (final value in [true, false, null]) {
        final encoded = shardDataToJson(buildShard(pushEnabled: value));
        final decoded = shardDataFromJson(encoded);
        expect(decoded.pushEnabled, value, reason: 'for $value');
      }
    });

    test('fromJson on a legacy JSON (no push_enabled key) yields null', () {
      final legacyJson = <String, dynamic>{
        'shard': 'abc123',
        'threshold': 2,
        'shardIndex': 0,
        'totalShards': 3,
        'primeMod': 'xyz',
        'creatorPubkey': creatorPubkey,
        'createdAt': 1759759657,
        // push_enabled intentionally absent.
      };
      final decoded = shardDataFromJson(legacyJson);
      expect(decoded.pushEnabled, isNull);
    });
  });
}
