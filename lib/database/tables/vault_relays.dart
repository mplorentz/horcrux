import 'package:drift/drift.dart';

import 'vaults.dart';

/// Per-vault relay list. Replaces any global relay table. The `role` column
/// records whether this entry came from the owner side ("authoritative for
/// this vault") or from a steward's ingested share event ("learned from").
@DataClassName('VaultRelayRow')
class VaultRelays extends Table {
  TextColumn get id => text()();
  TextColumn get vaultId => text().references(Vaults, #id, onDelete: KeyAction.cascade)();
  TextColumn get url => text()();
  TextColumn get role => text()(); // 'owner' | 'steward'
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
