import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/stewards.dart';

part 'steward_dao.g.dart';

@DriftAccessor(tables: [Stewards])
class StewardDao extends DatabaseAccessor<AppDatabase>
    with _$StewardDaoMixin {
  StewardDao(super.db);

  Future<List<StewardRow>> activeForVault(String vaultId) =>
      (select(stewards)
            ..where((s) => s.vaultId.equals(vaultId) & s.leftAt.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.shareIndex)]))
          .get();

  Stream<List<StewardRow>> watchActiveForVault(String vaultId) =>
      (select(stewards)
            ..where((s) => s.vaultId.equals(vaultId) & s.leftAt.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.shareIndex)]))
          .watch();

  Future<List<StewardRow>> historyForVaultPosition({
    required String vaultId,
    required int shareIndex,
  }) =>
      (select(stewards)
            ..where((s) =>
                s.vaultId.equals(vaultId) & s.shareIndex.equals(shareIndex))
            ..orderBy([(s) => OrderingTerm.asc(s.joinedAt)]))
          .get();

  Future<StewardRow?> getById(String id) =>
      (select(stewards)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> upsert(StewardsCompanion row) =>
      into(stewards).insertOnConflictUpdate(row);

  /// Append-on-replace: mark the active row at `(vaultId, shareIndex)` as
  /// left at `leftAt`, then insert `replacement` (which must have the same
  /// `vaultId` / `shareIndex` and `leftAt = null`). Atomic so the partial
  /// unique index is never violated mid-flight.
  Future<void> replaceAtPosition({
    required String vaultId,
    required int shareIndex,
    required int leftAt,
    required String? removalReason,
    required StewardsCompanion replacement,
  }) async {
    await transaction(() async {
      await (update(stewards)
            ..where((s) =>
                s.vaultId.equals(vaultId) &
                s.shareIndex.equals(shareIndex) &
                s.leftAt.isNull()))
          .write(StewardsCompanion(
        leftAt: Value(leftAt),
        removalReason: Value(removalReason),
      ));
      await into(stewards).insert(replacement);
    });
  }

  Future<int> countActive(String vaultId) async {
    final query = selectOnly(stewards)
      ..addColumns([stewards.id.count()])
      ..where(stewards.vaultId.equals(vaultId) & stewards.leftAt.isNull());
    final row = await query.getSingle();
    return row.read(stewards.id.count()) ?? 0;
  }
}
