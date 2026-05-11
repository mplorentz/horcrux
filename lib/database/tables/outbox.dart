import 'package:drift/drift.dart';

import 'vaults.dart';

/// Transactional outbox parent row (signed event JSON + metadata).
@DataClassName('OutboxRow')
class Outbox extends Table {
  TextColumn get id => text()();

  /// Nullable for non-vault-scoped publishes.
  TextColumn get vaultId => text().nullable().references(
        Vaults,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get kind => integer()();
  TextColumn get eventId => text()();
  IntColumn get createdAt => integer()();
  IntColumn get nextAttemptAt => integer().nullable()();
  TextColumn get eventJson => text()();
  TextColumn get correlationId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
