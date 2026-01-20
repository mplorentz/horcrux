import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/shard_data.dart';

void main() {
  group('ShardData JSON Serialization', () {
    late Map<String, dynamic> validJsonFixture;
    late Map<String, dynamic> validJsonWithRecoveryMetadata;

    setUp(() {
      // Base fixture from actual shard data
      validJsonFixture = {
        'shard':
            'J93z0EN6ZfWwx3j6zb4_YpxquwyZhSmVmrWCkwqtzR4=dGVzdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        'threshold': 1,
        'shardIndex': 0,
        'totalShards': 1,
        'primeMod':
            'ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmY0Mw==',
        'creatorPubkey': 'a11ac73f57e93ef42ef8bce513de552bcda3b6169c8f9ab96c6143f0c9b73437',
        'createdAt': 1759759657,
      };

      // Extended fixture with recovery metadata
      validJsonWithRecoveryMetadata = {
        ...validJsonFixture,
        'vaultId': 'vault-abc-456',
        'vaultName': 'Shared Vault Test',
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
        'ownerName': 'Owner',
        'recipientPubkey': 'b22bd84f68f94fa53fa9cdf624ef663ccdeb4c7260d9f0ab97d7254f1d9c8454',
        'isReceived': true,
        'receivedAt': '2025-02-06T12:00:00.000Z',
        'nostrEventId': 'event-xyz-789',
      };
    });

    test('shardDataFromJson creates valid ShardData from minimal JSON', () {
      final shardData = shardDataFromJson(validJsonFixture);

      expect(shardData.shard, validJsonFixture['shard']);
      expect(shardData.threshold, validJsonFixture['threshold']);
      expect(shardData.shardIndex, validJsonFixture['shardIndex']);
      expect(shardData.totalShards, validJsonFixture['totalShards']);
      expect(shardData.primeMod, validJsonFixture['primeMod']);
      expect(shardData.creatorPubkey, validJsonFixture['creatorPubkey']);
      expect(shardData.createdAt, validJsonFixture['createdAt']);
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
          validJsonWithRecoveryMetadata['shardIndex'],
        );
        expect(
          shardData.totalShards,
          validJsonWithRecoveryMetadata['totalShards'],
        );
        expect(shardData.primeMod, validJsonWithRecoveryMetadata['primeMod']);
        expect(
          shardData.creatorPubkey,
          validJsonWithRecoveryMetadata['creatorPubkey'],
        );
        expect(shardData.createdAt, validJsonWithRecoveryMetadata['createdAt']);
        expect(shardData.vaultId, validJsonWithRecoveryMetadata['vaultId']);
        expect(shardData.vaultName, validJsonWithRecoveryMetadata['vaultName']);
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
          validJsonWithRecoveryMetadata['recipientPubkey'],
        );
        expect(
          shardData.isReceived,
          validJsonWithRecoveryMetadata['isReceived'],
        );
        expect(
          shardData.receivedAt,
          DateTime.parse(validJsonWithRecoveryMetadata['receivedAt']),
        );
        expect(
          shardData.nostrEventId,
          validJsonWithRecoveryMetadata['nostrEventId'],
        );
      },
    );

    test('shardDataToJson encodes minimal ShardData correctly', () {
      final shardData = shardDataFromJson(validJsonFixture);
      final json = shardDataToJson(shardData);

      expect(json['shard'], validJsonFixture['shard']);
      expect(json['threshold'], validJsonFixture['threshold']);
      expect(json['shardIndex'], validJsonFixture['shardIndex']);
      expect(json['totalShards'], validJsonFixture['totalShards']);
      expect(json['primeMod'], validJsonFixture['primeMod']);
      expect(json['creatorPubkey'], validJsonFixture['creatorPubkey']);
      expect(json['createdAt'], validJsonFixture['createdAt']);
      expect(json.containsKey('vaultId'), isFalse);
      expect(json.containsKey('vaultName'), isFalse);
      expect(json.containsKey('stewards'), isFalse);
      expect(json.containsKey('recipientPubkey'), isFalse);
      expect(json.containsKey('isReceived'), isFalse);
      expect(json.containsKey('receivedAt'), isFalse);
      expect(json.containsKey('nostrEventId'), isFalse);
    });

    test(
      'shardDataToJson encodes ShardData with recovery metadata correctly',
      () {
        final shardData = shardDataFromJson(validJsonWithRecoveryMetadata);
        final json = shardDataToJson(shardData);

        expect(json['shard'], validJsonWithRecoveryMetadata['shard']);
        expect(json['threshold'], validJsonWithRecoveryMetadata['threshold']);
        expect(json['shardIndex'], validJsonWithRecoveryMetadata['shardIndex']);
        expect(
          json['totalShards'],
          validJsonWithRecoveryMetadata['totalShards'],
        );
        expect(json['primeMod'], validJsonWithRecoveryMetadata['primeMod']);
        expect(
          json['creatorPubkey'],
          validJsonWithRecoveryMetadata['creatorPubkey'],
        );
        expect(json['createdAt'], validJsonWithRecoveryMetadata['createdAt']);
        expect(json['vaultId'], validJsonWithRecoveryMetadata['vaultId']);
        expect(json['vaultName'], validJsonWithRecoveryMetadata['vaultName']);
        expect(json['stewards'], isNotNull);
        expect(json['stewards'], isA<List>());
        expect(json['ownerName'], 'Owner');
        expect(
          json['recipientPubkey'],
          validJsonWithRecoveryMetadata['recipientPubkey'],
        );
        expect(json['isReceived'], validJsonWithRecoveryMetadata['isReceived']);
        expect(json['receivedAt'], validJsonWithRecoveryMetadata['receivedAt']);
        expect(
          json['nostrEventId'],
          validJsonWithRecoveryMetadata['nostrEventId'],
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
      jsonWithoutReceivedAt.remove('receivedAt');

      final shardData = shardDataFromJson(jsonWithoutReceivedAt);

      expect(shardData.receivedAt, isNull);
      expect(shardData.vaultId, isNotNull);
      expect(shardData.vaultName, isNotNull);
    });

    test('shardDataFromJson throws on missing required fields', () {
      final invalidJson = {
        'shard': 'abc123',
        'threshold': 2,
        // Missing shardIndex, totalShards, primeMod, creatorPubkey, createdAt
      };

      expect(() => shardDataFromJson(invalidJson), throwsA(isA<TypeError>()));
    });

    test('shardDataToJson omits null optional fields', () {
      final minimalShardData = shardDataFromJson(validJsonFixture);
      final json = shardDataToJson(minimalShardData);

      expect(json.containsKey('vaultId'), isFalse);
      expect(json.containsKey('vaultName'), isFalse);
      expect(json.containsKey('recipientPubkey'), isFalse);
      expect(json.containsKey('isReceived'), isFalse);
      expect(json.containsKey('receivedAt'), isFalse);
      expect(json.containsKey('nostrEventId'), isFalse);
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
      final pastTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600; // 1 hour ago
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
      final pastTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 7200; // 2 hours ago
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
      final recentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600; // 1 hour ago
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
      final oldTimestamp =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400 - 3600; // >24 hours ago
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
}
