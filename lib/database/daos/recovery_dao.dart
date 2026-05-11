import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/recovery_request_participants.dart';
import '../tables/recovery_requests.dart';
import '../tables/recovery_responses.dart';

part 'recovery_dao.g.dart';

@DriftAccessor(tables: [RecoveryRequests, RecoveryRequestParticipants, RecoveryResponses])
class RecoveryDao extends DatabaseAccessor<AppDatabase> with _$RecoveryDaoMixin {
  RecoveryDao(super.db);

  Future<List<RecoveryRequestRow>> forVault(String vaultId) => (select(recoveryRequests)
        ..where((r) => r.vaultId.equals(vaultId))
        ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
      .get();

  Stream<List<RecoveryRequestRow>> watchForVault(String vaultId) => (select(recoveryRequests)
        ..where((r) => r.vaultId.equals(vaultId))
        ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
      .watch();

  Future<RecoveryRequestRow?> getById(String id) =>
      (select(recoveryRequests)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<List<RecoveryRequestParticipantRow>> participantsFor(String requestId) =>
      (select(recoveryRequestParticipants)..where((p) => p.requestId.equals(requestId))).get();

  Future<List<RecoveryResponseRow>> responsesFor(String requestId) => (select(recoveryResponses)
        ..where((r) => r.requestId.equals(requestId))
        ..orderBy([(r) => OrderingTerm.asc(r.receivedAt)]))
      .get();

  Future<RecoveryResponseRow?> responseByNostrEventId(String nostrEventId) =>
      (select(recoveryResponses)..where((r) => r.nostrEventId.equals(nostrEventId)))
          .getSingleOrNull();

  Future<void> upsertRequest(RecoveryRequestsCompanion row) =>
      into(recoveryRequests).insertOnConflictUpdate(row);

  Future<void> replaceParticipants(
      String requestId, List<RecoveryRequestParticipantsCompanion> rows) async {
    await (delete(recoveryRequestParticipants)..where((p) => p.requestId.equals(requestId))).go();
    await batch((b) {
      b.insertAll(recoveryRequestParticipants, rows);
    });
  }

  Future<void> upsertResponse(RecoveryResponsesCompanion row) =>
      into(recoveryResponses).insertOnConflictUpdate(row);

  Future<int> deleteResponsesForRequest(String requestId) =>
      (delete(recoveryResponses)..where((r) => r.requestId.equals(requestId))).go();

  Future<int> deleteRequestCascade(String requestId) async {
    await deleteResponsesForRequest(requestId);
    await (delete(recoveryRequestParticipants)..where((p) => p.requestId.equals(requestId))).go();
    return (delete(recoveryRequests)..where((r) => r.id.equals(requestId))).go();
  }

  /// Active-ish sessions used for expiry sweeps (caller filters by clock).
  Future<List<RecoveryRequestRow>> requestsNeedingExpiryCheck() =>
      (select(recoveryRequests)..where((r) => r.status.isIn(['pending', 'sent', 'inProgress'])))
          .get();
}
