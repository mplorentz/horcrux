import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/vault_relays.dart';

part 'vault_relay_dao.g.dart';

@DriftAccessor(tables: [VaultRelays])
class VaultRelayDao extends DatabaseAccessor<AppDatabase> with _$VaultRelayDaoMixin {
  VaultRelayDao(super.db);

  Future<List<VaultRelayRow>> forVault(String vaultId) =>
      (select(vaultRelays)..where((r) => r.vaultId.equals(vaultId))).get();

  Future<List<VaultRelayRow>> forVaultByRole(String vaultId, String role) =>
      (select(vaultRelays)..where((r) => r.vaultId.equals(vaultId) & r.role.equals(role))).get();

  Stream<List<VaultRelayRow>> watchForVault(String vaultId) =>
      (select(vaultRelays)..where((r) => r.vaultId.equals(vaultId))).watch();

  /// Replace the relay set for `vaultId` from a single role's perspective.
  /// Owner-side and steward-side rows live in the same table tagged by
  /// `role`; this method only touches rows matching the given role so the
  /// other role's view is preserved.
  Future<void> replaceForVault({
    required String vaultId,
    required String role,
    required List<VaultRelaysCompanion> rows,
  }) async {
    await transaction(() async {
      await (delete(vaultRelays)..where((r) => r.vaultId.equals(vaultId) & r.role.equals(role)))
          .go();
      if (rows.isNotEmpty) {
        await batch((b) => b.insertAll(vaultRelays, rows));
      }
    });
  }

  Future<List<VaultRelayRow>> findByUrl(String url) =>
      (select(vaultRelays)..where((r) => r.url.equals(url))).get();
}
