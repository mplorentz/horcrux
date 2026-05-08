import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/held_shares.dart';

part 'held_share_dao.g.dart';

/// Default number of distribution versions to retain per vault.
///
/// Configurable at runtime via the `kv` table (Phase 5); this constant is the
/// compile-time default used until that override mechanism lands.
const int defaultHeldShareRetentionCount = 3;

@DriftAccessor(tables: [HeldShares])
class HeldShareDao extends DatabaseAccessor<AppDatabase> with _$HeldShareDaoMixin {
  HeldShareDao(super.db);

  /// All held shares for [vaultId], most-recent distribution version first.
  Future<List<HeldShareRow>> forVault(String vaultId) => (select(heldShares)
        ..where((s) => s.vaultId.equals(vaultId))
        ..orderBy([
          (s) => OrderingTerm.desc(s.distributionVersion),
          (s) => OrderingTerm.desc(s.receivedAt),
        ]))
      .get();

  /// Most recently received share for [vaultId], or null if none exist.
  Future<HeldShareRow?> mostRecentForVault(String vaultId) => (select(heldShares)
        ..where((s) => s.vaultId.equals(vaultId))
        ..orderBy([
          (s) => OrderingTerm.desc(s.distributionVersion),
          (s) => OrderingTerm.desc(s.receivedAt),
        ])
        ..limit(1))
      .getSingleOrNull();

  /// Reactive stream of all held shares for [vaultId].
  Stream<List<HeldShareRow>> watchForVault(String vaultId) => (select(heldShares)
        ..where((s) => s.vaultId.equals(vaultId))
        ..orderBy([
          (s) => OrderingTerm.desc(s.distributionVersion),
          (s) => OrderingTerm.desc(s.receivedAt),
        ]))
      .watch();

  /// Insert [row], ignoring duplicates.
  ///
  /// Uses `INSERT OR IGNORE` so conflicts on **any** uniqueness constraint are
  /// skipped without error — including the partial index
  /// `held_shares_vault_version_event` on
  /// `(vault_id, distribution_version, nostr_event_id)` where
  /// `nostr_event_id IS NOT NULL`.
  ///
  /// [InsertStatement.insertOnConflictUpdate] only targets the primary key; the
  /// ingestion path generates a fresh synthetic `id` per insert, so replays of
  /// the same Nostr event would otherwise violate the partial unique index and
  /// throw.
  ///
  /// Returns the value reported by the executor for `last_insert_rowid` (often
  /// `0` when ignored); callers should not use this to detect dedup.
  Future<int> insertIfNew(HeldSharesCompanion row) =>
      into(heldShares).insert(row, mode: InsertMode.insertOrIgnore);

  /// Delete all held shares for [vaultId].
  Future<int> deleteForVault(String vaultId) =>
      (delete(heldShares)..where((s) => s.vaultId.equals(vaultId))).go();

  /// Prune old versions so that at most [keepCount] distinct
  /// `distribution_version` values remain for [vaultId].
  ///
  /// Keeps the rows with the highest distribution_version values; deletes
  /// everything older. Run inside the same transaction as [insertIfNew] so
  /// the retention invariant is upheld atomically.
  Future<void> pruneOldVersions(
    String vaultId, {
    int keepCount = defaultHeldShareRetentionCount,
  }) async {
    // Collect all distinct distribution_version values for this vault,
    // ordered descending. If we're within the retention window, bail early.
    final rows = await (select(heldShares)
          ..where((s) => s.vaultId.equals(vaultId))
          ..orderBy([(s) => OrderingTerm.desc(s.distributionVersion)]))
        .get();

    if (rows.length <= keepCount) return;

    // Determine the cutoff version: the (keepCount)th-highest version.
    final versions = rows.map((r) => r.distributionVersion).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    if (versions.length <= keepCount) return;

    final cutoff = versions[keepCount - 1]; // last version we keep

    await (delete(heldShares)
          ..where(
            (s) => s.vaultId.equals(vaultId) & s.distributionVersion.isSmallerThanValue(cutoff),
          ))
        .go();
  }
}
