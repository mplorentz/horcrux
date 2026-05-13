import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/outbox.dart';
import '../tables/outbox_relays.dart';

part 'outbox_dao.g.dart';

@DriftAccessor(tables: [Outbox, OutboxRelays])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  Future<OutboxRow?> getById(String id) =>
      (select(outbox)..where((o) => o.id.equals(id))).getSingleOrNull();

  Future<OutboxRow?> byEventId(String eventId) =>
      (select(outbox)..where((o) => o.eventId.equals(eventId))).getSingleOrNull();

  Future<void> upsertOutbox(OutboxCompanion row) => into(outbox).insertOnConflictUpdate(row);

  Future<void> upsertRelay(OutboxRelaysCompanion row) =>
      into(outboxRelays).insertOnConflictUpdate(row);

  Future<List<OutboxRelayRow>> relaysFor(String outboxId) =>
      (select(outboxRelays)..where((r) => r.outboxId.equals(outboxId))).get();

  /// Rows eligible for the worker (`pending` with due or no scheduled backoff).
  Future<List<OutboxRelayRow>> dueRelays({required int nowMs, int limit = 50}) {
    return (select(outboxRelays)
          ..where((r) =>
              r.status.equals('pending') &
              (r.nextAttemptAt.isNull() | r.nextAttemptAt.isSmallerOrEqualValue(nowMs)))
          ..limit(limit))
        .get();
  }

  Future<int> deleteOutboxCascade(String outboxId) async {
    await (delete(outboxRelays)..where((r) => r.outboxId.equals(outboxId))).go();
    return (delete(outbox)..where((o) => o.id.equals(outboxId))).go();
  }

  Future<void> deleteForVault(String vaultId) async {
    final rows = await (select(outbox)..where((o) => o.vaultId.equals(vaultId))).get();
    for (final row in rows) {
      await deleteOutboxCascade(row.id);
    }
  }
}
