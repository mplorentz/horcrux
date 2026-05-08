import 'package:drift/drift.dart';

import 'connection.dart';
import 'daos/distribution_dao.dart';
import 'daos/held_share_dao.dart';
import 'daos/owned_vault_dao.dart';
import 'daos/steward_dao.dart';
import 'daos/vault_dao.dart';
import 'daos/vault_relay_dao.dart';
import 'db_key.dart';
import 'tables/distribution_shares.dart';
import 'tables/distributions.dart';
import 'tables/held_shares.dart';
import 'tables/owned_vaults.dart';
import 'tables/stewards.dart';
import 'tables/vault_relays.dart';
import 'tables/vaults.dart';

part 'app_database.g.dart';

/// Schema version 1 — corresponds to `drift_schemas/drift_schema_v1.json`.
/// Any change to any [Table] in this database that affects the SQL schema MUST
/// bump [schemaVersion], add a step in [MigrationStrategy.onUpgrade], dump a
/// new `drift_schemas/drift_schema_v<n>.json`, and add a migration test. The
/// `schema_parity_test.dart` CI gate enforces that the dumped schema matches
/// what the code generates.
@DriftDatabase(
  tables: [
    Vaults,
    VaultRelays,
    OwnedVaults,
    Stewards,
    Distributions,
    DistributionShares,
    HeldShares,
  ],
  daos: [
    VaultDao,
    VaultRelayDao,
    OwnedVaultDao,
    StewardDao,
    DistributionDao,
    HeldShareDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Production constructor. Opens the SQLCipher-encrypted file at
  /// `<applicationSupportDirectory>/horcrux.db`.
  factory AppDatabase.openDefault({DbKeyDerivation? keyDerivation}) {
    return AppDatabase(openSqlCipherConnection(keyDerivation: keyDerivation));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Indexes that drift's DSL doesn't express as cleanly as raw SQL,
          // including the partial unique index on active stewards.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS stewards_vault_active '
            'ON stewards(vault_id, left_at)',
          );
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS stewards_vault_position_active '
            'ON stewards(vault_id, share_index) WHERE left_at IS NULL',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS vault_relays_vault '
            'ON vault_relays(vault_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS vault_relays_url '
            'ON vault_relays(url)',
          );
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS distributions_vault_version '
            'ON distributions(vault_id, version)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS distribution_shares_distribution '
            'ON distribution_shares(distribution_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS distribution_shares_steward '
            'ON distribution_shares(steward_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS held_shares_vault '
            'ON held_shares(vault_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS held_shares_vault_version '
            'ON held_shares(vault_id, distribution_version DESC)',
          );
          // Dedup: same share event for the same (vault, version) is a no-op.
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS held_shares_vault_version_event '
            'ON held_shares(vault_id, distribution_version, nostr_event_id) '
            'WHERE nostr_event_id IS NOT NULL',
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
