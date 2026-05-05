import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/distribution_shares.dart';
import '../tables/distributions.dart';

part 'distribution_dao.g.dart';

@DriftAccessor(tables: [Distributions, DistributionShares])
class DistributionDao extends DatabaseAccessor<AppDatabase> with _$DistributionDaoMixin {
  DistributionDao(super.db);

  Future<List<DistributionRow>> forVault(String vaultId) => (select(distributions)
        ..where((d) => d.vaultId.equals(vaultId))
        ..orderBy([(d) => OrderingTerm.desc(d.version)]))
      .get();

  Future<DistributionRow?> latestForVault(String vaultId) => (select(distributions)
        ..where((d) => d.vaultId.equals(vaultId))
        ..orderBy([(d) => OrderingTerm.desc(d.version)])
        ..limit(1))
      .getSingleOrNull();

  Future<void> insertDistribution(DistributionsCompanion row) => into(distributions).insert(row);

  Future<List<DistributionShareRow>> sharesFor(String distributionId) =>
      (select(distributionShares)..where((s) => s.distributionId.equals(distributionId))).get();

  Future<void> insertShare(DistributionSharesCompanion row) => into(distributionShares).insert(row);

  Future<void> updateShare(
    String id,
    DistributionSharesCompanion patch,
  ) =>
      (update(distributionShares)..where((s) => s.id.equals(id))).write(patch);
}
