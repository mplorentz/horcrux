import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/recovery_request.dart';

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
}
