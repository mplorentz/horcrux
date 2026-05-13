import 'dart:convert';

import 'app_database.dart';
import '../models/recovery_request.dart';
import '../models/share.dart';

/// Loads participant and response rows and builds a [RecoveryRequest].
///
/// Shared by vault repository and vault detail repository so recovery
/// hydration stays consistent when the schema or mapping changes.
Future<RecoveryRequest> recoveryRequestFromRow(AppDatabase db, RecoveryRequestRow r) async {
  final participants = await db.recoveryDao.participantsFor(r.id);
  final responses = await db.recoveryDao.responsesFor(r.id);
  return RecoveryRequest.makeFromParticipants(
    id: r.id,
    vaultId: r.vaultId,
    initiatorPubkey: r.initiatorPubkey,
    requestedAt: DateTime.fromMillisecondsSinceEpoch(r.startedAt),
    status: RecoveryRequestStatus.values.firstWhere(
      (e) => e.name == r.status,
      orElse: () => RecoveryRequestStatus.pending,
    ),
    threshold: r.thresholdAtStart,
    nostrEventId: r.requestEventId,
    eventCreationTime: r.eventCreationTimeMs != null
        ? DateTime.fromMillisecondsSinceEpoch(r.eventCreationTimeMs!)
        : null,
    expiresAt: r.expiresAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.expiresAt!),
    stewardPubkeys: participants.map((p) => p.pubkey),
    responses: responses.map(recoveryResponseFromRow),
    errorMessage: r.errorMessage,
    isPractice: r.isPractice,
  );
}

/// Maps a persisted recovery response row to the domain model.
RecoveryResponse recoveryResponseFromRow(RecoveryResponseRow r) {
  Share? share;
  if (r.sharePayload.isNotEmpty) {
    try {
      share = shareFromJson(json.decode(r.sharePayload) as Map<String, dynamic>);
    } catch (_) {
      share = null;
    }
  }
  return RecoveryResponse(
    pubkey: r.responderPubkey,
    approved: r.approved,
    respondedAt:
        r.respondedAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(r.respondedAtMs!),
    share: share,
    nostrEventId: r.nostrEventId,
    errorMessage: r.errorMessage,
  );
}
