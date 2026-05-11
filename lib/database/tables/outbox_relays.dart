import 'package:drift/drift.dart';

import 'outbox.dart';

/// Per-relay publish state for an [Outbox] row.
@DataClassName('OutboxRelayRow')
class OutboxRelays extends Table {
  TextColumn get outboxId => text().references(
        Outbox,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get relayUrl => text()();

  /// `pending` | `success` | `failed`
  TextColumn get status => text()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {outboxId, relayUrl};
}
