import 'package:drift/drift.dart';

import 'vaults.dart';

/// Owner-side: one row per redistribution event. UNIQUE(vaultId, version) is
/// enforced via an index in [AppDatabase] migrations. `contentHmac` snapshots
/// the keyed HMAC at distribution time so an ack referencing an old version
/// can still be matched after content changes.
@DataClassName('DistributionRow')
class Distributions extends Table {
  TextColumn get id => text()();
  TextColumn get vaultId =>
      text().references(Vaults, #id, onDelete: KeyAction.cascade)();
  IntColumn get version => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  BlobColumn get contentHmac => blob()();

  @override
  Set<Column> get primaryKey => {id};
}
