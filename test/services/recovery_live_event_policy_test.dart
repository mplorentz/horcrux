import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/services/recovery_service.dart';

void main() {
  group('RecoveryLiveNotificationPolicy.isLiveEventTime', () {
    final firstOpen = DateTime.utc(2026, 4, 1, 12, 0);

    test('matches slack window', () {
      expect(
        RecoveryNotificationPolicy.isLiveEventTime(
          DateTime.utc(2026, 3, 1),
          firstOpen,
        ),
        isFalse,
      );
      expect(
        RecoveryNotificationPolicy.isLiveEventTime(
          DateTime.utc(2026, 4, 1, 11, 30),
          firstOpen,
        ),
        isTrue,
      );
      expect(
        RecoveryNotificationPolicy.isLiveEventTime(
          DateTime.utc(2026, 4, 1, 13),
          firstOpen,
        ),
        isTrue,
      );
    });
  });

  group('recovery live event policy', () {
    final firstOpen = DateTime.utc(2026, 4, 1, 12, 0);

    test('should not notify historical recovery request', () {
      final req = RecoveryRequest(
        id: 'r1',
        vaultId: 'v1',
        initiatorPubkey: 'a' * 64,
        requestedAt: DateTime.utc(2026, 3, 1),
        status: RecoveryRequestStatus.sent,
        threshold: 2,
        eventCreationTime: DateTime.utc(2026, 3, 1),
      );
      expect(
        RecoveryNotificationPolicy.shouldNotifyRecoveryRequest(req, firstOpen),
        isFalse,
      );
    });

    test('should notify recovery request after first open (inner time)', () {
      final req = RecoveryRequest(
        id: 'r1',
        vaultId: 'v1',
        initiatorPubkey: 'a' * 64,
        requestedAt: DateTime.utc(2026, 4, 1, 10, 0),
        status: RecoveryRequestStatus.sent,
        threshold: 2,
        eventCreationTime: DateTime.utc(2026, 4, 1, 12, 30),
      );
      expect(
        RecoveryNotificationPolicy.shouldNotifyRecoveryRequest(req, firstOpen),
        isTrue,
      );
    });

    test('should notify within slack before first open', () {
      final req = RecoveryRequest(
        id: 'r1',
        vaultId: 'v1',
        initiatorPubkey: 'a' * 64,
        requestedAt: DateTime.utc(2026, 4, 1, 11, 0),
        status: RecoveryRequestStatus.sent,
        threshold: 2,
        eventCreationTime: DateTime.utc(2026, 4, 1, 11, 30),
      );
      expect(
        RecoveryNotificationPolicy.shouldNotifyRecoveryRequest(req, firstOpen),
        isTrue,
      );
    });

    test('should not notify recovery request when initiator is current user', () {
      final me = 'a' * 64;
      final req = RecoveryRequest(
        id: 'r1',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime.utc(2026, 4, 1, 10, 0),
        status: RecoveryRequestStatus.sent,
        threshold: 2,
        eventCreationTime: DateTime.utc(2026, 4, 1, 12, 30),
      );
      expect(
        RecoveryNotificationPolicy.shouldNotifyRecoveryRequest(
          req,
          firstOpen,
          currentPubkeyHex: me,
        ),
        isFalse,
      );
    });

    group('shouldNotifyIncomingRecoveryResponseLocally', () {
      final initiator = 'a' * 64;
      final stewardMe = 'b' * 64;
      final stewardOther = 'c' * 64;
      final liveInnerTime = DateTime.utc(2026, 4, 1, 13);

      RecoveryRequest baseRequest({
        required RecoveryRequestStatus status,
        required Map<String, RecoveryResponse> responses,
      }) {
        return RecoveryRequest(
          id: 'r1',
          vaultId: 'v1',
          initiatorPubkey: initiator,
          requestedAt: DateTime.utc(2026, 4, 1),
          status: status,
          threshold: 2,
          stewardResponses: responses,
        );
      }

      test('false without inner created time', () {
        final req = baseRequest(
          status: RecoveryRequestStatus.inProgress,
          responses: {
            stewardOther: RecoveryResponse(pubkey: stewardOther, approved: false),
          },
        );
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: null,
            firstOpenUtc: firstOpen,
            requestBeforeApply: req,
            currentPubkeyHex: initiator,
            responseSenderPubkey: stewardOther,
          ),
          isFalse,
        );
      });

      test('true when live inner time and initiator hears peer response', () {
        final req = baseRequest(
          status: RecoveryRequestStatus.inProgress,
          responses: {
            initiator: RecoveryResponse(
              pubkey: initiator,
              approved: true,
              respondedAt: DateTime.utc(2026, 4, 1, 11),
            ),
            stewardOther: RecoveryResponse(pubkey: stewardOther, approved: false),
          },
        );
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: liveInnerTime,
            firstOpenUtc: firstOpen,
            requestBeforeApply: req,
            currentPubkeyHex: initiator,
            responseSenderPubkey: stewardOther,
          ),
          isTrue,
        );
      });

      test('false when inner time is historical even if initiator', () {
        final req = baseRequest(
          status: RecoveryRequestStatus.inProgress,
          responses: {
            initiator: RecoveryResponse(
              pubkey: initiator,
              approved: true,
              respondedAt: DateTime.utc(2026, 4, 1, 11),
            ),
            stewardOther: RecoveryResponse(pubkey: stewardOther, approved: false),
          },
        );
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: DateTime.utc(2026, 3, 1),
            firstOpenUtc: firstOpen,
            requestBeforeApply: req,
            currentPubkeyHex: initiator,
            responseSenderPubkey: stewardOther,
          ),
          isFalse,
        );
      });

      test('false for non-initiator steward (peer responses)', () {
        final req = baseRequest(
          status: RecoveryRequestStatus.inProgress,
          responses: {
            stewardMe: RecoveryResponse(
              pubkey: stewardMe,
              approved: false,
              respondedAt: DateTime.utc(2026, 4, 1, 12),
            ),
            stewardOther: RecoveryResponse(pubkey: stewardOther, approved: false),
          },
        );
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: liveInnerTime,
            firstOpenUtc: firstOpen,
            requestBeforeApply: req,
            currentPubkeyHex: stewardMe,
            responseSenderPubkey: stewardOther,
          ),
          isFalse,
        );
      });

      test('false for non-initiator steward still pending', () {
        final req = baseRequest(
          status: RecoveryRequestStatus.inProgress,
          responses: {
            stewardMe: RecoveryResponse(pubkey: stewardMe, approved: false),
            stewardOther: RecoveryResponse(pubkey: stewardOther, approved: false),
          },
        );
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: liveInnerTime,
            firstOpenUtc: firstOpen,
            requestBeforeApply: req,
            currentPubkeyHex: stewardMe,
            responseSenderPubkey: stewardOther,
          ),
          isFalse,
        );
      });

      test('false when response is from self', () {
        final req = baseRequest(
          status: RecoveryRequestStatus.inProgress,
          responses: {
            initiator: RecoveryResponse(
              pubkey: initiator,
              approved: true,
              respondedAt: DateTime.utc(2026, 4, 1, 11),
            ),
            stewardOther: RecoveryResponse(pubkey: stewardOther, approved: false),
          },
        );
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: liveInnerTime,
            firstOpenUtc: firstOpen,
            requestBeforeApply: req,
            currentPubkeyHex: initiator,
            responseSenderPubkey: initiator,
          ),
          isFalse,
        );
      });

      test('false when session already terminal', () {
        final req = baseRequest(
          status: RecoveryRequestStatus.archived,
          responses: {
            stewardMe: RecoveryResponse(
              pubkey: stewardMe,
              approved: false,
              respondedAt: DateTime.utc(2026, 4, 1, 12),
            ),
          },
        );
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: liveInnerTime,
            firstOpenUtc: firstOpen,
            requestBeforeApply: req,
            currentPubkeyHex: stewardMe,
            responseSenderPubkey: stewardOther,
          ),
          isFalse,
        );
      });

      test('false when request or pubkey unknown', () {
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: liveInnerTime,
            firstOpenUtc: firstOpen,
            requestBeforeApply: null,
            currentPubkeyHex: initiator,
            responseSenderPubkey: stewardOther,
          ),
          isFalse,
        );
        expect(
          RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
            responseCreatedAt: liveInnerTime,
            firstOpenUtc: firstOpen,
            requestBeforeApply: baseRequest(
              status: RecoveryRequestStatus.inProgress,
              responses: {},
            ),
            currentPubkeyHex: null,
            responseSenderPubkey: stewardOther,
          ),
          isFalse,
        );
      });
    });
  });
}
