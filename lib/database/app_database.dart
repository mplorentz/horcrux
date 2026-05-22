import 'package:drift/drift.dart';

import 'connection.dart';
import 'daos/app_state_dao.dart';
import 'daos/distribution_dao.dart';
import 'daos/held_share_dao.dart';
import 'daos/invitation_dao.dart';
import 'daos/outbox_dao.dart';
import 'daos/owned_vault_dao.dart';
import 'daos/recovery_dao.dart';
import 'daos/steward_dao.dart';
import 'daos/vault_dao.dart';
import 'daos/vault_relay_dao.dart';
import 'db_key.dart';
import 'tables/distribution_shares.dart';
import 'tables/distributions.dart';
import 'tables/held_shares.dart';
import 'tables/invitations.dart';
import 'tables/kv.dart';
import 'tables/outbox.dart';
import 'tables/outbox_relays.dart';
import 'tables/owned_vaults.dart';
import 'tables/recovery_request_participants.dart';
import 'tables/recovery_requests.dart';
import 'tables/recovery_responses.dart';
import 'tables/stewards.dart';
import 'tables/synced_consents.dart';
import 'tables/vault_relays.dart';
import 'tables/vaults.dart';
import 'tables/viewed_notifications.dart';

part 'app_database.g.dart';

/// Schema version 7 — corresponds to `drift_schemas/drift_schema_v7.json`.
///
/// **v2**: Adds `held_shares` (and indexes) on upgrade for databases that were
/// created at v1 before the Phase 2a table landed; those files kept
/// `user_version = 1` without the new table, so `onCreate` never re-ran.
///
/// **v3**: Phase 3 HVC — `invitations`, `recovery_requests`,
/// `recovery_request_participants`, `recovery_responses`, `outbox`,
/// `outbox_relays`, plus indexes.
///
/// **v4**: `invitations` gains `vault_id` and nullable `steward_id` for
/// invitee-side rows and vault-scoped listing.
///
/// **v5**: Adds app-state tables (`kv`, `viewed_notifications`,
/// `synced_consents`) used to move remaining SharedPreferences-backed runtime
/// state into SQLCipher.
///
/// **v6**: `stewards.invite_code` stores the pending invite code for a slot so
/// invitation acceptance can hydrate stewards without relying on a local
/// [Invitations] row on every owner device.
///
/// **v7**: `held_shares.aead_blob` — base64url ChaCha20-Poly1305 bundle that
/// carries the AEAD-encrypted vault content. In `gf256_v1` the share payload
/// is a share of the content-encryption key, not the vault content; the
/// blob is what gets decrypted with the reconstructed key. Nullable so
/// legacy / manifest-shaped rows continue to round-trip; recovery enforces
/// presence on the read path. The bare column name `blob` collides with
/// drift's [Table.blob] binary-column constructor.
///
/// Any further change to any [Table] that affects the SQL schema MUST bump
/// [schemaVersion], add a step in [MigrationStrategy.onUpgrade], dump a new
/// `drift_schemas/drift_schema_v<n>.json`, and add a migration test. The
/// `schema_parity_test.dart` CI gate enforces that the dumped schema matches
/// what the code generates.
@DriftDatabase(
  tables: [
    Vaults,
    VaultRelays,
    OwnedVaults,
    Stewards,
    Invitations,
    Distributions,
    DistributionShares,
    HeldShares,
    RecoveryRequests,
    RecoveryRequestParticipants,
    RecoveryResponses,
    Outbox,
    OutboxRelays,
    Kv,
    ViewedNotifications,
    SyncedConsents,
  ],
  daos: [
    VaultDao,
    VaultRelayDao,
    OwnedVaultDao,
    StewardDao,
    InvitationDao,
    DistributionDao,
    HeldShareDao,
    RecoveryDao,
    OutboxDao,
    AppStateDao,
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
  int get schemaVersion => 7;

  Future<void> _createPhase3Indexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS invitations_steward_id_idx ON invitations(steward_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS invitations_expires_at_idx '
      'ON invitations(expires_at) WHERE expires_at IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS recovery_requests_vault_idx ON recovery_requests(vault_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS recovery_requests_expires_idx '
      'ON recovery_requests(expires_at) '
      "WHERE status IN ('pending','sent','inProgress')",
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS recovery_responses_request_idx '
      'ON recovery_responses(request_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS recovery_responses_event_unique '
      'ON recovery_responses(nostr_event_id) WHERE nostr_event_id IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS outbox_vault_created_idx '
      'ON outbox(vault_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS outbox_next_attempt_partial_idx '
      'ON outbox(next_attempt_at) WHERE next_attempt_at IS NOT NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS outbox_event_id_unique ON outbox(event_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS outbox_relays_outbox_idx ON outbox_relays(outbox_id)',
    );
  }

  Future<void> _createPhase4InvitationIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS invitations_vault_id_idx ON invitations(vault_id)',
    );
  }

  Future<void> _createHeldSharesIndexes() async {
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
  }

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
          await _createHeldSharesIndexes();
          await _createPhase3Indexes();
          await _createPhase4InvitationIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            final heldSharesExists = await customSelect(
              "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'held_shares' LIMIT 1",
            ).get();
            if (heldSharesExists.isEmpty) {
              await m.createTable(heldShares);
            }
            await _createHeldSharesIndexes();
          }
          if (from < 3) {
            Future<void> createIfMissing(String tableName, Future<void> Function() create) async {
              final exists = await customSelect(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = '$tableName' LIMIT 1",
              ).get();
              if (exists.isEmpty) {
                await create();
              }
            }

            await createIfMissing('invitations', () => m.createTable(invitations));
            await createIfMissing('recovery_requests', () => m.createTable(recoveryRequests));
            await createIfMissing(
              'recovery_request_participants',
              () => m.createTable(recoveryRequestParticipants),
            );
            await createIfMissing('recovery_responses', () => m.createTable(recoveryResponses));
            await createIfMissing('outbox', () => m.createTable(outbox));
            await createIfMissing('outbox_relays', () => m.createTable(outboxRelays));
            await _createPhase3Indexes();
          }
          if (from < 4) {
            final invitationsTable = await customSelect(
              "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'invitations' LIMIT 1",
            ).get();
            if (invitationsTable.isEmpty) {
              await m.createTable(invitations);
            } else {
              final cols = await customSelect('PRAGMA table_info(invitations)').get();
              final hasVaultId = cols.any((c) => c.data['name'] == 'vault_id');
              if (!hasVaultId) {
                await customStatement('ALTER TABLE invitations RENAME TO invitations_old');
                await m.createTable(invitations);
                await customStatement(
                  'INSERT INTO invitations (code, vault_id, steward_id, payload, created_at, '
                  'expires_at, accepted_at, accepted_by_pubkey, revoked_at) '
                  'SELECT i.code, s.vault_id, i.steward_id, i.payload, i.created_at, '
                  'i.expires_at, i.accepted_at, i.accepted_by_pubkey, i.revoked_at '
                  'FROM invitations_old AS i '
                  'INNER JOIN stewards AS s ON s.id = i.steward_id',
                );
                await customStatement('DROP TABLE invitations_old');
              }
            }
            // v3 invitation indexes can be dropped when the table is recreated
            // during the v4 migration, so ensure both v3 and v4 invitation
            // indexes exist after this block.
            await _createPhase3Indexes();
            await _createPhase4InvitationIndexes();
          }
          if (from < 5) {
            Future<void> createIfMissing(
              String tableName,
              Future<void> Function() create,
            ) async {
              final exists = await customSelect(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = '$tableName' LIMIT 1",
              ).get();
              if (exists.isEmpty) {
                await create();
              }
            }

            await createIfMissing('kv', () => m.createTable(kv));
            await createIfMissing(
              'viewed_notifications',
              () => m.createTable(viewedNotifications),
            );
            await createIfMissing(
              'synced_consents',
              () => m.createTable(syncedConsents),
            );
          }
          if (from < 6) {
            final cols = await customSelect('PRAGMA table_info(stewards)').get();
            final hasInviteCode = cols.any((c) => c.data['name'] == 'invite_code');
            if (!hasInviteCode) {
              await customStatement('ALTER TABLE stewards ADD COLUMN invite_code TEXT');
              await customStatement('''
UPDATE stewards
SET invite_code = (
  SELECT i.code
  FROM invitations AS i
  WHERE i.steward_id = stewards.id
    AND i.revoked_at IS NULL
  LIMIT 1
)
WHERE EXISTS (
  SELECT 1
  FROM invitations AS i2
  WHERE i2.steward_id = stewards.id
    AND i2.revoked_at IS NULL
)
''');
            }
          }
          if (from < 7) {
            // gf256_v1 + AEAD layer: held_shares.aead_blob carries the
            // ChaCha20-Poly1305 ciphertext bundle. Nullable so we don't have
            // to backfill any pre-existing rows — they predate gf256_v1 in
            // practice (pre-beta, no shipped users), and recovery already
            // rejects shares missing the blob. Column name is `aead_blob`
            // (not `blob`) because drift's [Table.blob] reserves the bare
            // identifier for binary-column constructors.
            final cols = await customSelect('PRAGMA table_info(held_shares)').get();
            final hasAeadBlob = cols.any((c) => c.data['name'] == 'aead_blob');
            if (!hasAeadBlob) {
              await customStatement('ALTER TABLE held_shares ADD COLUMN aead_blob TEXT');
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Best-effort WAL truncation after large recovery-session deletes.
  Future<void> walCheckpointTruncate() async {
    await customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
  }
}
