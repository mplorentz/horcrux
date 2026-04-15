import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/services/recovery_service.dart';

void main() {
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
        RecoveryLiveNotificationPolicy.shouldNotifyRecoveryRequest(req, firstOpen),
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
        RecoveryLiveNotificationPolicy.shouldNotifyRecoveryRequest(req, firstOpen),
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
        RecoveryLiveNotificationPolicy.shouldNotifyRecoveryRequest(req, firstOpen),
        isTrue,
      );
    });

    test('should not notify response without inner created time', () {
      expect(
        RecoveryLiveNotificationPolicy.shouldNotifyRecoveryResponse(
          createdAt: null,
          firstOpenUtc: firstOpen,
        ),
        isFalse,
      );
    });

    test('should notify response when inner time is after first open', () {
      expect(
        RecoveryLiveNotificationPolicy.shouldNotifyRecoveryResponse(
          createdAt: DateTime.utc(2026, 4, 1, 13),
          firstOpenUtc: firstOpen,
        ),
        isTrue,
      );
    });
  });
}
