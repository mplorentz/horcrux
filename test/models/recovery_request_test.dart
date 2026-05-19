import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';

void main() {
  group('RecoveryRequest JSON contract', () {
    const initiator = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const stewardA = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    const stewardB = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

    test('makeFromParticipants fills missing steward response placeholders', () {
      final request = RecoveryRequest.makeFromParticipants(
        id: 'req-1',
        vaultId: 'vault-1',
        initiatorPubkey: initiator,
        requestedAt: DateTime.utc(2026, 1, 1),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: const [stewardA, stewardB],
        responses: const [
          RecoveryResponse(
            pubkey: stewardA,
            approved: true,
            respondedAt: null,
            errorMessage: 'temporary',
          ),
        ],
      );

      expect(request.stewardPubkeys, [stewardA, stewardB]);
      expect(request.responses, hasLength(2));
      expect(request.responseForPubkey(stewardA)?.errorMessage, 'temporary');
      expect(request.responseForPubkey(stewardB)?.status, RecoveryResponseStatus.pending);
    });

    test('toJson/fromJson round-trip preserves participants and responses', () {
      final request = RecoveryRequest.makeFromParticipants(
        id: 'req-2',
        vaultId: 'vault-2',
        initiatorPubkey: initiator,
        requestedAt: DateTime.utc(2026, 2, 2, 12),
        status: RecoveryRequestStatus.sent,
        threshold: 2,
        stewardPubkeys: const [stewardA, stewardB],
        responses: [
          RecoveryResponse(
            pubkey: stewardA,
            approved: true,
            respondedAt: DateTime.utc(2026, 2, 2, 12, 5),
          ),
          RecoveryResponse(
            pubkey: stewardB,
            approved: false,
            respondedAt: DateTime.utc(2026, 2, 2, 12, 6),
            nostrEventId: 'nostr-evt-1',
          ),
        ],
        isPractice: true,
      );

      final decoded = RecoveryRequest.fromJson(request.toJson());

      expect(decoded.id, request.id);
      expect(decoded.vaultId, request.vaultId);
      expect(decoded.stewardPubkeys, request.stewardPubkeys);
      expect(decoded.responses.map((r) => r.pubkey), request.responses.map((r) => r.pubkey));
      expect(decoded.responseForPubkey(stewardA)?.status, RecoveryResponseStatus.approved);
      expect(decoded.responseForPubkey(stewardB)?.nostrEventId, 'nostr-evt-1');
      expect(decoded.isPractice, isTrue);
    });

    test('fromJson ignores legacy stewardResponses payload shape', () {
      final legacyJson = <String, dynamic>{
        'id': 'legacy-req',
        'vaultId': 'legacy-vault',
        'initiatorPubkey': initiator,
        'requestedAt': DateTime.utc(2026, 3, 1).toIso8601String(),
        'status': RecoveryRequestStatus.pending.name,
        'threshold': 2,
        'stewardResponses': {
          stewardA: {
            'pubkey': stewardA,
            'approved': true,
            'respondedAt': DateTime.utc(2026, 3, 1, 1).toIso8601String(),
          },
        },
      };

      final request = RecoveryRequest.fromJson(legacyJson);

      expect(request.stewardPubkeys, isEmpty);
      expect(request.responses, isEmpty);
      expect(request.totalStewards, 0);
    });
  });

  group('RecoveryResponse.isValid', () {
    const validPubkey = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    Share _validShare() {
      return Share(
        payload: 'abc123',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        primeMod: 'xyz',
        creatorPubkey: validPubkey,
        createdAt: 1759759657,
      );
    }

    test('isValid returns true for valid approved response with share', () {
      final response = RecoveryResponse(
        pubkey: validPubkey,
        approved: true,
        share: _validShare(),
        respondedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(response.isValid, isTrue);
    });

    test('isValid returns false for invalid pubkey', () {
      final response = RecoveryResponse(
        pubkey: 'too-short',
        approved: true,
        share: _validShare(),
        respondedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(response.isValid, isFalse);
    });

    test('isValid returns false when approved but share is null', () {
      final response = RecoveryResponse(
        pubkey: validPubkey,
        approved: true,
        share: null,
        respondedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(response.isValid, isFalse);
    });
  });

  group('RecoveryResponse JSON serialization', () {
    const validPubkey = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    Share _validShare() {
      return Share(
        payload: 'abc123',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        primeMod: 'xyz',
        creatorPubkey: validPubkey,
        createdAt: 1759759657,
      );
    }

    test('toJson encodes share as shardData with shareToJson', () {
      final share = _validShare();
      final response = RecoveryResponse(
        pubkey: validPubkey,
        approved: true,
        share: share,
        respondedAt: DateTime.utc(2026, 1, 1),
      );
      final json = response.toJson();

      expect(json['pubkey'], validPubkey);
      expect(json['approved'], isTrue);
      expect(json['shardData'], isNotNull);
      expect(json['shardData']['shard'], 'abc123');
      expect(json['respondedAt'], isNotNull);
    });

    test('fromJson reconstructs approved response with share', () {
      final json = {
        'pubkey': validPubkey,
        'approved': true,
        'shardData': {
          'shard': 'abc123',
          'threshold': 2,
          'shard_index': 0,
          'total_shards': 3,
          'prime_mod': 'xyz',
          'creator_pubkey': validPubkey,
          'created_at': 1759759657,
        },
        'respondedAt': '2026-01-01T00:00:00.000',
      };
      final response = RecoveryResponse.fromJson(json);

      expect(response.pubkey, validPubkey);
      expect(response.approved, isTrue);
      expect(response.share, isNotNull);
      expect(response.share!.payload, 'abc123');
      expect(response.respondedAt?.year, 2026);
      expect(response.respondedAt?.month, 1);
      expect(response.respondedAt?.day, 1);
    });

    test('fromJson reconstructs denied response without share', () {
      final json = {
        'pubkey': validPubkey,
        'approved': false,
        'respondedAt': '2026-01-01T00:00:00.000',
      };
      final response = RecoveryResponse.fromJson(json);

      expect(response.pubkey, validPubkey);
      expect(response.approved, isFalse);
      expect(response.share, isNull);
    });

    test('toJson <-> fromJson round-trip', () {
      final original = RecoveryResponse(
        pubkey: validPubkey,
        approved: true,
        share: _validShare(),
        respondedAt: DateTime.utc(2026, 1, 1),
        nostrEventId: 'nostr-evt-roundtrip',
        errorMessage: null,
      );
      final json = original.toJson();
      final decoded = RecoveryResponse.fromJson(json);

      expect(decoded.pubkey, original.pubkey);
      expect(decoded.approved, original.approved);
      expect(decoded.share!.payload, original.share!.payload);
      expect(decoded.nostrEventId, original.nostrEventId);
    });
  });

  group('RecoveryRequest.isValid', () {
    const validPubkey = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    test('isValid returns true for valid request', () {
      final request = RecoveryRequest(
        id: 'req-valid',
        vaultId: 'vault-1',
        initiatorPubkey: validPubkey,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
      );
      expect(request.isValid, isTrue);
    });

    test('isValid returns false for empty id', () {
      final request = RecoveryRequest(
        id: '',
        vaultId: 'vault-1',
        initiatorPubkey: validPubkey,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
      );
      expect(request.isValid, isFalse);
    });

    test('isValid returns false for empty vaultId', () {
      final request = RecoveryRequest(
        id: 'req-1',
        vaultId: '',
        initiatorPubkey: validPubkey,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
      );
      expect(request.isValid, isFalse);
    });

    test('isValid returns false for invalid initiatorPubkey', () {
      final request = RecoveryRequest(
        id: 'req-1',
        vaultId: 'vault-1',
        initiatorPubkey: 'too-short',
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
      );
      expect(request.isValid, isFalse);
    });
  });

  group('RecoveryRequest.withUpsertedResponse', () {
    const validPubkey = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const stewardA = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    test('adds new response', () {
      final request = RecoveryRequest(
        id: 'req-upsert-add',
        vaultId: 'vault-1',
        initiatorPubkey: validPubkey,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
      );

      final updated = request.withUpsertedResponse(
        response: RecoveryResponse(
          pubkey: stewardA,
          approved: true,
          respondedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      expect(updated.responses, hasLength(1));
      expect(updated.responseForPubkey(stewardA)?.approved, isTrue);
      expect(updated.stewardPubkeys, contains(stewardA));
    });

    test('updates existing response', () {
      final request = RecoveryRequest(
        id: 'req-upsert-update',
        vaultId: 'vault-1',
        initiatorPubkey: validPubkey,
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: [stewardA],
        responses: [
          RecoveryResponse(
            pubkey: stewardA,
            approved: false,
            respondedAt: null,
          ),
        ],
      );

      final updated = request.withUpsertedResponse(
        response: RecoveryResponse(
          pubkey: stewardA,
          approved: true,
          respondedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      expect(updated.responses, hasLength(1));
      expect(updated.responseForPubkey(stewardA)?.approved, isTrue);
      expect(updated.responseForPubkey(stewardA)?.status, RecoveryResponseStatus.approved);
    });
  });
}
