import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/vault.dart';

void main() {
  final me = 'a' * 64;

  Vault vaultWith(List<RecoveryRequest> requests) {
    return Vault(
      id: 'v1',
      name: 'V',
      content: 'x',
      createdAt: DateTime(2024, 1, 1),
      ownerPubkey: me,
      recoveryRequests: requests,
    );
  }

  group('Vault.manageableRecoveryFor', () {
    test('picks the newest active request when an older completed row comes first in the list', () {
      final olderCompleted = RecoveryRequest(
        id: 'old-done',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 10),
        status: RecoveryRequestStatus.completed,
        threshold: 1,
      );
      final newerActive = RecoveryRequest(
        id: 'new-active',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 12),
        status: RecoveryRequestStatus.inProgress,
        threshold: 1,
      );
      final v = vaultWith([olderCompleted, newerActive]);
      expect(v.manageableRecoveryFor(me, isPractice: false)?.id, newerActive.id);
    });

    test('returns null for real recovery when the newest real request is cancelled', () {
      final olderCompleted = RecoveryRequest(
        id: 'old-done',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 10),
        status: RecoveryRequestStatus.completed,
        threshold: 1,
      );
      final newerCancelled = RecoveryRequest(
        id: 'new-cancelled',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 12),
        status: RecoveryRequestStatus.cancelled,
        threshold: 1,
      );
      final v = vaultWith([olderCompleted, newerCancelled]);
      expect(v.manageableRecoveryFor(me, isPractice: false), isNull);
    });

    test('archived as newest real request also clears manageable real recovery', () {
      final olderCompleted = RecoveryRequest(
        id: 'old-done',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 10),
        status: RecoveryRequestStatus.completed,
        threshold: 1,
      );
      final newerArchived = RecoveryRequest(
        id: 'new-archived',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 12),
        status: RecoveryRequestStatus.archived,
        threshold: 1,
      );
      final v = vaultWith([olderCompleted, newerArchived]);
      expect(v.manageableRecoveryFor(me, isPractice: false), isNull);
    });

    test('with isPractice null, practice cancelled does not hide older real completed', () {
      final realCompleted = RecoveryRequest(
        id: 'real-done',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 10),
        status: RecoveryRequestStatus.completed,
        threshold: 1,
        isPractice: false,
      );
      final practiceCancelled = RecoveryRequest(
        id: 'practice-x',
        vaultId: 'v1',
        initiatorPubkey: me,
        requestedAt: DateTime(2024, 1, 1, 12),
        status: RecoveryRequestStatus.cancelled,
        threshold: 1,
        isPractice: true,
      );
      final v = vaultWith([realCompleted, practiceCancelled]);
      expect(v.manageableRecoveryFor(me)?.id, realCompleted.id);
    });
  });
}
