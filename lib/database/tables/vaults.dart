import 'package:drift/drift.dart';

/// Shared vault metadata: written by both the owner (on creation /
/// redistribution) and stewards (on share-event ingestion). The owner is
/// authoritative when [OwnedVaults] has a row for the same vault — see the
/// "cross-role write precedence" rule in `docs/data_layer_refactor_plan.md`.
@DataClassName('VaultRow')
class Vaults extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerPubkey => text()();
  TextColumn get ownerName => text().nullable()();
  IntColumn get threshold => integer()();
  TextColumn get primeMod => text().nullable()();
  IntColumn get totalShares => integer()();

  /// Owner-side: highest distribution version this device has authored.
  /// Steward-side: version of the most recent ingested share for this vault.
  IntColumn get currentDistributionVersion => integer().withDefault(const Constant(0))();

  TextColumn get instructions => text().nullable()();

  /// Owner-authored gate. `false` suppresses all push send paths for this
  /// vault, regardless of any steward's local opt-in. See "Push notification
  /// flags" in the refactor plan.
  BoolColumn get pushEnabled => boolean().withDefault(const Constant(true))();

  /// Local-only soft delete. Cascades happen on hard delete only.
  IntColumn get archivedAt => integer().nullable()();
  TextColumn get archivedReason => text().nullable()();

  /// Steward-side timestamp for the last successful ingest from a relay; null
  /// on owner devices.
  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
