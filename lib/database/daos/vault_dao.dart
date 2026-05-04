import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/vaults.dart';

part 'vault_dao.g.dart';

@DriftAccessor(tables: [Vaults])
class VaultDao extends DatabaseAccessor<AppDatabase> with _$VaultDaoMixin {
  VaultDao(super.db);

  Future<List<VaultRow>> getAll() => select(vaults).get();

  Future<VaultRow?> getById(String id) =>
      (select(vaults)..where((v) => v.id.equals(id))).getSingleOrNull();

  Stream<List<VaultRow>> watchAll() => select(vaults).watch();

  Stream<VaultRow?> watchById(String id) =>
      (select(vaults)..where((v) => v.id.equals(id))).watchSingleOrNull();

  Future<void> upsert(VaultsCompanion row) async {
    await into(vaults).insertOnConflictUpdate(row);
  }

  Future<void> deleteById(String id) async {
    await (delete(vaults)..where((v) => v.id.equals(id))).go();
  }
}
