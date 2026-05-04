import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/owned_vaults.dart';

part 'owned_vault_dao.g.dart';

@DriftAccessor(tables: [OwnedVaults])
class OwnedVaultDao extends DatabaseAccessor<AppDatabase>
    with _$OwnedVaultDaoMixin {
  OwnedVaultDao(super.db);

  Future<OwnedVaultRow?> getByVaultId(String vaultId) =>
      (select(ownedVaults)..where((v) => v.vaultId.equals(vaultId)))
          .getSingleOrNull();

  Stream<OwnedVaultRow?> watchByVaultId(String vaultId) =>
      (select(ownedVaults)..where((v) => v.vaultId.equals(vaultId)))
          .watchSingleOrNull();

  Future<void> upsert(OwnedVaultsCompanion row) =>
      into(ownedVaults).insertOnConflictUpdate(row);
}
