import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../database/recovery_request_hydration.dart';
import '../models/backup_config.dart';
import '../models/recovery_request.dart';
import '../models/share.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../models/vault.dart';
import '../models/vault_detail.dart';
import '../services/login_service.dart';
import '../services/logger.dart';
import '../services/notification_recency.dart';
import 'key_provider.dart';
import 'vault_detail_repository.dart';

/// Stream provider that automatically subscribes to vault changes
final vaultListProvider = StreamProvider.autoDispose<List<Vault>>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  return repository.vaultsStream;
});

/// Provider for a specific vault by ID
final vaultProvider = StreamProvider.family<Vault?, String>((ref, vaultId) {
  final repository = ref.watch(vaultRepositoryProvider);
  return repository.watchVault(vaultId);
});

/// Provider for vault repository operations.
///
/// Uses `ref.watch(appDatabaseProvider)` so that invalidating the database
/// (e.g. on logout) automatically rebuilds this repository against the new
/// [AppDatabase]. Holding the DB via `ref.read` would leak the closed
/// instance into the next session and crash subsequent reads.
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final repository = VaultRepository(
    ref.watch(loginServiceProvider),
    db: ref.watch(appDatabaseProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// Provider for [VaultDetailRepository].
///
/// See [vaultRepositoryProvider] for why the database dependency is watched.
final vaultDetailRepositoryProvider = Provider<VaultDetailRepository>((ref) {
  final repository = VaultDetailRepository(
    db: ref.watch(appDatabaseProvider),
    loginService: ref.watch(loginServiceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// Stream provider for the role-typed [VaultDetail] of a specific vault.
///
/// Emits null when the vault does not exist. Emits [OwnedVaultDetail] when
/// this device owns the vault, or [StewardedVaultDetail] otherwise.
final vaultDetailProvider = StreamProvider.family<VaultDetail?, String>((ref, vaultId) {
  final repository = ref.watch(vaultDetailRepositoryProvider);
  return repository.watchVaultDetail(vaultId);
});

/// Stream provider for the list of all [VaultDetail] entries.
final vaultDetailListProvider = StreamProvider.autoDispose<List<VaultDetail>>((ref) {
  final repository = ref.watch(vaultDetailRepositoryProvider);
  return repository.vaultListStream;
});

/// Repository for vaults backed by drift DAOs (`vaults`, `owned_vaults`,
/// `stewards`, `held_shares`).
///
/// **Phase 2a additions** — see `docs/data_layer_refactor_plan.md`:
///
/// - `Vault.shares` is now hydrated from the `held_shares` table.
///   [addShareToVault] writes a row and prunes old versions.
///   [clearSharesForVault] deletes all rows for the vault.
/// - Inserting a `held_shares` row also updates `vaults.last_synced_at` so
///   the reactive vault stream re-emits and callers see the updated shares.
///
/// - `Vault.recoveryRequests` hydrates from `recovery_requests`,
///   `recovery_request_participants`, and `recovery_responses` via
///   [recovery_request_hydration.dart]. [addRecoveryRequestToVault] and
///   [updateRecoveryRequestInVault] persist to those tables.
/// - `BackupConfig` is hydrated from `vaults` + `owned_vaults` + active
///   `stewards` (`StewardDao.activeForVault`). [updateBackupConfig] writes
///   the same triple back atomically.
class VaultRepository {
  final AppDatabase _db;
  final LoginService _loginService;

  final StreamController<List<Vault>> _vaultsController = StreamController<List<Vault>>.broadcast();
  List<Vault>? _latest;
  final Completer<List<Vault>> _initialVaultsCompleter = Completer<List<Vault>>();
  StreamSubscription<List<Vault>>? _vaultRowsSubscription;

  /// **Phase 1 carryover cache.** The drift schema does not yet track
  /// `Steward.status`, `acknowledgedAt`, `acknowledgmentEventId`, or
  /// `acknowledgedDistributionVersion` (those land alongside
  /// `distribution_shares` in Phase 2/3). To keep existing service behavior
  /// intact without re-encoding that state into JSON, we cache the
  /// last-written `BackupConfig` in memory keyed by vault id and merge its
  /// stewards onto rows hydrated from the DB. The cache is intentionally a
  /// soft layer: a fresh process restart drops it, which is acceptable until
  /// the missing columns land in later phases.
  final Map<String, BackupConfig> _backupConfigOverlay = {};

  /// Construct a repository.
  ///
  /// Production code should pass an explicit [db] (the app injects one via
  /// [vaultRepositoryProvider]). When [db] is omitted we open an in-memory
  /// `NativeDatabase` — primarily a convenience for unit tests that
  /// previously instantiated `VaultRepository(loginService)` against the
  /// SharedPreferences-backed implementation. Production should always
  /// pass `db: ref.read(appDatabaseProvider)`.
  VaultRepository(LoginService loginService, {AppDatabase? db})
      : _db = db ?? AppDatabase(NativeDatabase.memory()),
        _loginService = loginService {
    _vaultRowsSubscription = _db.vaultDao.watchAll().asyncMap(_hydrateAll).listen(
      (vaults) {
        _latest = vaults;
        if (!_initialVaultsCompleter.isCompleted) {
          _initialVaultsCompleter.complete(vaults);
        }
        _vaultsController.add(vaults);
      },
      onError: (Object e, StackTrace s) {
        Log.error('vaultsStream hydration failed', e);
        if (!_initialVaultsCompleter.isCompleted) {
          _initialVaultsCompleter.completeError(e, s);
        }
        _vaultsController.addError(e, s);
      },
    );
  }

  /// Stream that replays the most recent hydrated vault list to new
  /// subscribers, then emits subsequent updates.
  Stream<List<Vault>> get vaultsStream async* {
    final latest = _latest;
    if (latest == null) {
      yield await _initialVaultsCompleter.future;
    } else {
      yield latest;
    }
    yield* _vaultsController.stream;
  }

  Future<void> initialize() async {
    // The drift connection opens lazily; nothing else to do.
  }

  /// Watch a specific vault by id. Emits `null` when the vault is missing
  /// (e.g. deleted).
  Stream<Vault?> watchVault(String id) {
    return _db.vaultDao.watchById(id).asyncMap((row) async {
      if (row == null) return null;
      return _hydrate(row);
    });
  }

  Future<List<Vault>> getAllVaults() async {
    final rows = await _db.vaultDao.getAll();
    return _hydrateAll(rows);
  }

  Future<Vault?> getVault(String id) async {
    final row = await _db.vaultDao.getById(id);
    if (row == null) return null;
    return _hydrate(row);
  }

  Future<void> saveVault(Vault vault) => _persistVault(vault);

  Future<void> addVault(Vault vault) => _persistVault(vault);

  /// Update the textual fields and content of an existing owned vault.
  Future<void> updateVault(String id, String name, String content) async {
    final existing = await getVault(id);
    if (existing == null) {
      throw ArgumentError('Vault not found: $id');
    }
    await _persistVault(existing.copyWith(name: name));
    await saveOwnedVaultContent(id, content);
  }

  Future<void> setPushEnabled(String vaultId, bool enabled) async {
    final existing = await getVault(vaultId);
    if (existing == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    if (existing.pushEnabled == enabled) return;
    await _persistVault(existing.copyWith(pushEnabled: enabled));
    Log.info('Updated pushEnabled=$enabled for vault $vaultId');
  }

  Future<void> deleteVault(String id) async {
    _backupConfigOverlay.remove(id);
    await _db.vaultDao.deleteById(id);
  }

  Future<void> clearAll() async {
    _backupConfigOverlay.clear();
    await _db.transaction(() async {
      await _db.delete(_db.outboxRelays).go();
      await _db.delete(_db.outbox).go();
      await _db.delete(_db.recoveryResponses).go();
      await _db.delete(_db.recoveryRequestParticipants).go();
      await _db.delete(_db.recoveryRequests).go();
      await _db.delete(_db.invitations).go();
      await _db.delete(_db.distributionShares).go();
      await _db.delete(_db.distributions).go();
      await _db.delete(_db.stewards).go();
      await _db.delete(_db.ownedVaults).go();
      await _db.delete(_db.vaultRelays).go();
      await _db.delete(_db.heldShares).go();
      await _db.delete(_db.vaults).go();
    });
  }

  Future<void> refresh() async {
    final all = await getAllVaults();
    _latest = all;
    if (!_initialVaultsCompleter.isCompleted) {
      _initialVaultsCompleter.complete(all);
    }
    _vaultsController.add(all);
  }

  // ========== Backup Config Operations ==========

  Future<void> updateBackupConfig(String vaultId, BackupConfig config) async {
    final existing = await getVault(vaultId);
    if (existing == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    await _persistVault(existing.copyWith(backupConfig: config));
    Log.info('Updated backup configuration for vault $vaultId');
  }

  Future<BackupConfig?> getBackupConfig(String vaultId) async {
    final vault = await getVault(vaultId);
    if (vault == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    return vault.backupConfig;
  }

  Future<void> updateStewardStatus({
    required String vaultId,
    required String pubkey,
    required StewardStatus status,
    DateTime? acknowledgedAt,
    String? acknowledgmentEventId,
    int? acknowledgedDistributionVersion,
    String? giftWrapEventId,
  }) async {
    final vault = await getVault(vaultId);
    if (vault == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    final config = vault.backupConfig;
    if (config == null) {
      throw ArgumentError('Vault $vaultId has no backup configuration');
    }
    final stewardIndex = config.stewards.indexWhere((h) => h.pubkey == pubkey);
    if (stewardIndex == -1) {
      throw ArgumentError('Steward $pubkey not found in vault $vaultId');
    }
    final updatedStewards = List<Steward>.from(config.stewards);
    final prior = updatedStewards[stewardIndex];
    updatedStewards[stewardIndex] = prior.copyWith(
      status: status,
      acknowledgedAt: acknowledgedAt,
      acknowledgmentEventId: acknowledgmentEventId,
      acknowledgedDistributionVersion: acknowledgedDistributionVersion,
      giftWrapEventId: giftWrapEventId ?? prior.giftWrapEventId,
    );
    final updated = config.copyWith(stewards: updatedStewards);
    await updateBackupConfig(vaultId, updated);
    await _upsertDistributionShareState(
      vaultId: vaultId,
      stewardId: prior.id,
      stewardGiftWrapEventId: prior.giftWrapEventId,
      status: status,
      giftWrapEventId: giftWrapEventId,
      acknowledgedAt: acknowledgedAt,
      acknowledgmentEventId: acknowledgmentEventId,
      acknowledgedDistributionVersion: acknowledgedDistributionVersion,
      currentDistributionVersion: updated.distributionVersion,
    );
    Log.info('Updated steward $pubkey status to $status in vault $vaultId');
  }

  // ========== Share management (`held_shares` table) ==========

  /// True when this device owns [vaultId] (an `owned_vaults` row exists).
  Future<bool> isOwnedVault(String vaultId) async {
    final row = await _db.ownedVaultDao.getByVaultId(vaultId);
    return row != null;
  }

  /// True when share ingestion should use **owner** precedence (skip steward-side
  /// vault/steward normalization from wire shares).
  ///
  /// Matches [VaultDetailRepository] role logic: an `owned_vaults` row alone is
  /// not sufficient — when a logged-in pubkey exists it must match
  /// [VaultsRow.ownerPubkey], otherwise the row is stale and steward ingest runs.
  Future<bool> isOwnedVaultForCurrentUser(String vaultId) async {
    final ownedRow = await _db.ownedVaultDao.getByVaultId(vaultId);
    if (ownedRow == null) return false;

    final vaultRow = await _db.vaultDao.getById(vaultId);
    if (vaultRow == null) return false;

    final localPubkey = await _loginService.getCurrentPublicKey();
    if (localPubkey != null && localPubkey != vaultRow.ownerPubkey) {
      Log.warning(
        'Stale owned_vaults row for vault $vaultId during share ingest: '
        'logged-in pubkey does not match vault owner pubkey.',
      );
      return false;
    }
    return true;
  }

  /// Write [share] into the `held_shares` table and prune old versions.
  ///
  /// Also bumps `vaults.last_synced_at` so the reactive vault stream re-emits.
  ///
  /// **Slot replace:** before insert, deletes any existing row for the same
  /// `(vaultId, shareIndex, distributionVersion)`. Relay replays or republished
  /// gift-wraps can carry a **new** Nostr id for the same steward slot and
  /// version; the partial unique index on `(vault_id, distribution_version,
  /// nostr_event_id)` does not include `share_index`, so without this delete
  /// those inserts would accumulate duplicate slots.
  Future<void> addShareToVault(String vaultId, Share share) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dist = share.distributionVersion ?? 0;
    final id = '${vaultId}_${share.shareIndex}_${dist}_$now';

    await _db.transaction(() async {
      await (_db.delete(_db.heldShares)
            ..where(
              (h) =>
                  h.vaultId.equals(vaultId) &
                  h.shareIndex.equals(share.shareIndex) &
                  h.distributionVersion.equals(dist),
            ))
          .go();

      await _db.heldShareDao.insertIfNew(
        HeldSharesCompanion.insert(
          id: id,
          vaultId: vaultId,
          shareIndex: share.shareIndex,
          sharePayload: share.payload,
          distributionVersion: dist,
          receivedAt: now,
          nostrEventId: Value(share.nostrEventId),
          lastSeenRelay: Value(share.relayUrls?.isNotEmpty == true ? share.relayUrls!.first : null),
          pushEnabled: Value(share.pushEnabled ?? true),
        ),
      );
      await _db.heldShareDao.pruneOldVersions(vaultId);
      // Write primeMod to the vault row when provided so that
      // _shareFromHeldShareRow can hydrate valid Share objects. For owned
      // vaults, _persistVault doesn't write primeMod (BackupConfig doesn't
      // carry it); persisting it here fills that gap. For steward vaults
      // mergeVaultRowFromIncomingShare already set it, so this is idempotent.
      final vaultsUpdate = share.primeMod.isNotEmpty
          ? VaultsCompanion(primeMod: Value(share.primeMod), lastSyncedAt: Value(now))
          : VaultsCompanion(lastSyncedAt: Value(now));
      await (_db.update(_db.vaults)..where((v) => v.id.equals(vaultId))).write(vaultsUpdate);
    });
    Log.info(
      'addShareToVault: wrote held_share for vault $vaultId '
      '(shareIndex=${share.shareIndex}, version=$dist)',
    );
  }

  /// All shares held for [vaultId], most-recent version first.
  ///
  /// Reads from the `held_shares` table directly so it is always consistent
  /// with what [_hydrate] returns via [Vault.shares].
  Future<List<Share>> getSharesForVault(String vaultId) async {
    final vaultRow = await _db.vaultDao.getById(vaultId);
    if (vaultRow == null) throw ArgumentError('Vault not found: $vaultId');
    final rows = await _db.heldShareDao.forVault(vaultId);
    return rows.map((r) => _shareFromHeldShareRow(r, vaultRow)).toList();
  }

  /// Highest [HeldShareRow.distributionVersion] among `held_shares` for
  /// [vaultId], or `-1` when none exist.
  ///
  /// Implemented as [HeldShareDao.mostRecentForVault] (version desc, then
  /// [HeldShareRow.receivedAt] desc): the first row carries the max version.
  Future<int> maxHeldShareDistributionVersion(String vaultId) async {
    final row = await _db.heldShareDao.mostRecentForVault(vaultId);
    if (row == null) return -1;
    return row.distributionVersion;
  }

  /// Delete all `held_shares` rows for [vaultId].
  Future<void> clearSharesForVault(String vaultId) async {
    await _db.heldShareDao.deleteForVault(vaultId);
    Log.info('clearSharesForVault: removed all held_shares for vault $vaultId');
  }

  /// Insert or update a steward row identified by [id].
  ///
  /// Used by [VaultShareService] during steward-side ingestion to upsert the
  /// self-steward entry for a received share. The `left_at` column is cleared
  /// so a previously soft-retired self-steward becomes active again on
  /// redistribution.
  ///
  /// The partial unique index `stewards_vault_position_active` enforces one
  /// active row per `(vault_id, share_index)`. If an active row with a
  /// *different* id already occupies this position (e.g. an old invited-steward
  /// UUID from the owner's config), it is soft-retired before the new row is
  /// inserted so the constraint is never violated.
  Future<void> upsertStewardRow({
    required String id,
    required String vaultId,
    required int shareIndex,
    String? pubkey,
    String? name,
    String? contactInfo,
    bool isOwner = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      // Retire any incumbent active steward at this position whose id differs.
      final incumbents = await (_db.select(_db.stewards)
            ..where(
              (s) =>
                  s.vaultId.equals(vaultId) &
                  s.shareIndex.equals(shareIndex) &
                  s.leftAt.isNull() &
                  s.id.isNotValue(id),
            ))
          .get();
      for (final row in incumbents) {
        await (_db.update(
          _db.stewards,
        )..where((s) => s.id.equals(row.id)))
            .write(StewardsCompanion(leftAt: Value(now)));
      }

      await _db.stewardDao.upsert(
        StewardsCompanion.insert(
          id: id,
          vaultId: vaultId,
          shareIndex: shareIndex,
          pubkey: Value(pubkey),
          name: Value(name),
          contactInfo: Value(contactInfo),
          isOwner: Value(isOwner),
          joinedAt: now,
        ).copyWith(leftAt: const Value(null)),
      );
    });
  }

  /// Copies Shamir parameters and relay hints from [share] onto the `vaults`
  /// row for steward-side ingestion.
  ///
  /// Without this, [_persistVault] paths that lack [BackupConfig] leave
  /// `threshold` / `total_shares` / `prime_mod` at defaults; [_shareFromHeldShareRow]
  /// would then hydrate invalid [Share] objects.
  ///
  /// No-op when [Share.distributionVersion] (null → 0) is **strictly less** than
  /// the stored `vaults.current_distribution_version` so stale shares cannot
  /// roll back metadata.
  Future<void> mergeVaultRowFromIncomingShare(String vaultId, Share share) async {
    final row = await _db.vaultDao.getById(vaultId);
    if (row == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    final incomingDist = share.distributionVersion ?? 0;
    if (incomingDist < row.currentDistributionVersion) {
      return;
    }

    await _db.transaction(() async {
      await (_db.update(_db.vaults)..where((v) => v.id.equals(vaultId))).write(
        VaultsCompanion(
          threshold: Value(share.threshold),
          totalShares: Value(share.totalShares),
          primeMod: Value(share.primeMod),
          currentDistributionVersion: Value(
            incomingDist > row.currentDistributionVersion
                ? incomingDist
                : row.currentDistributionVersion,
          ),
          instructions:
              share.instructions != null ? Value(share.instructions) : const Value.absent(),
        ),
      );

      final relays = share.relayUrls;
      if (relays != null && relays.isNotEmpty) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await _db.vaultRelayDao.replaceForVault(
          vaultId: vaultId,
          role: 'steward',
          rows: [
            for (var i = 0; i < relays.length; i++)
              VaultRelaysCompanion.insert(
                id: '$vaultId-steward-${relays[i]}-$i',
                vaultId: vaultId,
                url: relays[i],
                role: 'steward',
                addedAt: nowMs,
              ),
          ],
        );
      }
    });
    Log.debug(
      'mergeVaultRowFromIncomingShare: vault $vaultId '
      '(threshold=${share.threshold}, totalShares=${share.totalShares})',
    );
  }

  /// Ensures an `owned_vaults` row exists for [vaultId] (empty encrypted shell).
  ///
  /// Used when the vault owner (same device pubkey as [vaults.owner_pubkey])
  /// ingests a manifest-only 1337 on a fresh install so [isOwnedVault] and
  /// owner UI gates activate while [saveOwnedVaultContent] has not run yet.
  Future<void> ensureOwnedVaultShell(String vaultId) async {
    final existing = await _db.ownedVaultDao.getByVaultId(vaultId);
    if (existing != null) return;
    await saveOwnedVaultContent(vaultId, '');
    Log.info('ensureOwnedVaultShell: inserted owned placeholder for vault $vaultId');
  }

  /// Write or replace the NIP-44 [content] ciphertext for an owned vault.
  ///
  /// Creates the `owned_vaults` row on first call; subsequent calls update it
  /// in-place. This is the only path that touches `owned_vaults.content` after
  /// Phase 2c (where [Vault.content] was removed).
  ///
  /// Bumps `vaults.last_synced_at` in the same transaction so that
  /// [vaultDao.watchAll] / [vaultDao.watchById] re-emit *after* the
  /// `owned_vaults` row is committed. Without this touch, callers that do
  /// `addVault` then `saveOwnedVaultContent` (create-new-vault) or
  /// `_persistVault` then `saveOwnedVaultContent` (updateVault) expose a race:
  /// the first vaults-table write fires a re-emission that may hydrate
  /// [OwnedVaultDetail] before the `owned_vaults` row exists, permanently
  /// classifying the vault as [StewardedVaultDetail] until the next
  /// unrelated vaults write.
  Future<void> saveOwnedVaultContent(String vaultId, String content) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final createdAtMs = (await _db.vaultDao.getById(vaultId))?.createdAt ?? now;
    await _db.transaction(() async {
      await _db.into(_db.ownedVaults).insertOnConflictUpdate(
            OwnedVaultsCompanion.insert(
              vaultId: vaultId,
              content: content,
              contentHmac: _placeholderHmac(content),
              createdBySelfAt: createdAtMs,
            ),
          );
      await (_db.update(
        _db.vaults,
      )..where((v) => v.id.equals(vaultId)))
          .write(VaultsCompanion(lastSyncedAt: Value(now)));
    });
    Log.info('saveOwnedVaultContent: wrote content for vault $vaultId');
  }

  /// Delete the NIP-44 content for [vaultId] (removes the `owned_vaults` row).
  ///
  /// Also bumps `vaults.last_synced_at` in the same transaction so that
  /// [vaultDao.watchAll] / [vaultDao.watchById] re-emit and both
  /// [VaultRepository] and [VaultDetailRepository] reactive streams reflect
  /// the change immediately. Without this touch the streams only observe
  /// changes to the `vaults` table, so Travel Mode and exitRecoveryMode would
  /// delete content but the UI would continue showing a stale
  /// [OwnedVaultDetail] until something else modified the vault row.
  Future<void> deleteVaultContent(String vaultId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.delete(_db.ownedVaults)..where((v) => v.vaultId.equals(vaultId))).go();
      await (_db.update(
        _db.vaults,
      )..where((v) => v.id.equals(vaultId)))
          .write(VaultsCompanion(lastSyncedAt: Value(now)));
    });
    Log.info('deleteVaultContent: removed owned_vaults row for vault $vaultId');
  }

  /// True when at least one `held_shares` row exists for [vaultId].
  Future<bool> isKeyHolderForVault(String vaultId) async {
    final row = await _db.heldShareDao.mostRecentForVault(vaultId);
    return row != null;
  }

  // ========== Recovery Request Management (Phase 3) ==========

  Future<void> addRecoveryRequestToVault(String vaultId, RecoveryRequest request) async {
    final eventTime = request.eventCreationTime;
    if (eventTime != null) {
      final currentPubkey = await _loginService.getCurrentPublicKey();
      if (currentPubkey != null && request.initiatorPubkey == currentPubkey) {
        final firstOpen = await getFirstAppOpenUtc(database: _db);
        if (eventTime.isBefore(firstOpen)) {
          Log.info(
            'addRecoveryRequestToVault: ignored stale self-initiated request '
            '${request.id} for vault $vaultId '
            '(eventCreationTime=$eventTime < firstOpen=$firstOpen)',
          );
          return;
        }
      }
    }

    final vaultRow = await _db.vaultDao.getById(vaultId);
    if (vaultRow == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    await _db.transaction(() async {
      await _db.into(_db.recoveryRequests).insert(
            RecoveryRequestsCompanion.insert(
              id: request.id,
              vaultId: vaultId,
              requestEventId: Value(request.nostrEventId),
              initiatorPubkey: request.initiatorPubkey,
              startedAt: request.requestedAt.millisecondsSinceEpoch,
              expiresAt: Value(request.expiresAt?.millisecondsSinceEpoch),
              cancelledAt: const Value.absent(),
              completedAt: const Value.absent(),
              distributionVersionAtStart: vaultRow.currentDistributionVersion,
              thresholdAtStart: request.threshold,
              status: request.status.name,
              isPractice: Value(request.isPractice),
              errorMessage: Value(request.errorMessage),
              eventCreationTimeMs: Value(request.eventCreationTime?.millisecondsSinceEpoch),
            ),
          );
      await _db.batch((b) {
        for (final pubkey in request.stewardPubkeys) {
          b.insert(
            _db.recoveryRequestParticipants,
            RecoveryRequestParticipantsCompanion.insert(requestId: request.id, pubkey: pubkey),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
    });
    await _bumpVaultSync(vaultId);
  }

  Future<void> updateRecoveryRequestInVault(
    String vaultId,
    String requestId,
    RecoveryRequest updatedRequest,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.update(_db.recoveryRequests)..where((r) => r.id.equals(requestId))).write(
        RecoveryRequestsCompanion(
          requestEventId: Value(updatedRequest.nostrEventId),
          status: Value(updatedRequest.status.name),
          errorMessage: Value(updatedRequest.errorMessage),
          expiresAt: Value(updatedRequest.expiresAt?.millisecondsSinceEpoch),
          eventCreationTimeMs: Value(updatedRequest.eventCreationTime?.millisecondsSinceEpoch),
          cancelledAt: updatedRequest.status == RecoveryRequestStatus.cancelled
              ? Value(now)
              : const Value.absent(),
          completedAt: (updatedRequest.status == RecoveryRequestStatus.completed ||
                  updatedRequest.status == RecoveryRequestStatus.archived)
              ? Value(now)
              : const Value.absent(),
        ),
      );

      for (final resp in updatedRequest.responses) {
        if (!resp.status.isResolved && resp.errorMessage == null) {
          continue;
        }
        final dist = resp.share?.distributionVersion ?? 0;
        await _db.into(_db.recoveryResponses).insertOnConflictUpdate(
              RecoveryResponsesCompanion.insert(
                id: '${requestId}_${resp.pubkey}',
                requestId: requestId,
                stewardId: const Value.absent(),
                responderPubkey: resp.pubkey,
                sharePayload: resp.share != null ? jsonEncode(shareToJson(resp.share!)) : '',
                shareDistributionVersion: dist,
                receivedAt: resp.respondedAt?.millisecondsSinceEpoch ?? now,
                nostrEventId: Value(resp.nostrEventId),
                replyingToEventId: const Value.absent(),
                approved: resp.approved,
                respondedAtMs: Value(resp.respondedAt?.millisecondsSinceEpoch),
                errorMessage: Value(resp.errorMessage),
              ),
            );
      }
    });
    await _bumpVaultSync(vaultId);
  }

  /// Clears [recovery_responses.sharePayload] for [requestId] (e.g. cancelled recovery).
  ///
  /// Keeps rows so approve/deny metadata remains for audit.
  Future<void> deleteRecoveryResponseSharesForRequest({
    required String vaultId,
    required String requestId,
  }) async {
    await _db.recoveryDao.clearSharePayloadsForRequest(requestId);
    await _bumpVaultSync(vaultId);
  }

  /// Deletes all [recovery_responses] rows for [requestId] (e.g. after successful recovery).
  Future<void> deleteRecoveryResponsesForRequest({
    required String vaultId,
    required String requestId,
  }) async {
    await _db.recoveryDao.deleteResponsesForRequest(requestId);
    await _bumpVaultSync(vaultId);
  }

  /// Marks expired in-flight recovery sessions failed and prunes their responses.
  Future<void> cleanupExpiredRecoverySessions() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final candidates = await _db.recoveryDao.requestsNeedingExpiryCheck();
    var touched = false;
    for (final r in candidates) {
      if (r.expiresAt == null || r.expiresAt! >= now) {
        continue;
      }
      await _db.transaction(() async {
        await (_db.update(_db.recoveryRequests)..where((x) => x.id.equals(r.id))).write(
          RecoveryRequestsCompanion(
            status: const Value('failed'),
            errorMessage: const Value('Recovery session expired'),
            completedAt: Value(now),
          ),
        );
        await _db.recoveryDao.deleteResponsesForRequest(r.id);
      });
      touched = true;
    }
    if (touched) {
      await _db.walCheckpointTruncate();
      await refresh();
    }
  }

  Future<List<RecoveryRequest>> getRecoveryRequestsForVault(String vaultId) async {
    final vault = await getVault(vaultId);
    if (vault == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    return List.unmodifiable(vault.recoveryRequests);
  }

  Future<RecoveryRequest?> getActiveRecoveryRequest(String vaultId) async {
    final vault = await getVault(vaultId);
    if (vault == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    return vault.activeRecoveryRequest;
  }

  Future<List<RecoveryRequest>> getAllRecoveryRequests() async {
    final vaults = await getAllVaults();
    return [for (final v in vaults) ...v.recoveryRequests];
  }

  void dispose() {
    _vaultRowsSubscription?.cancel();
    _vaultsController.close();
  }

  // ========== Hydration helpers ==========

  Future<List<Vault>> _hydrateAll(List<VaultRow> rows) async {
    final result = <Vault>[];
    for (final row in rows) {
      result.add(await _hydrate(row));
    }
    return result;
  }

  Steward _mergeDbStewardWithBackupOverlay(Steward dbSteward, BackupConfig overlay) {
    final cached = overlay.stewards.firstWhere(
      (c) => c.id == dbSteward.id,
      orElse: () => dbSteward,
    );
    // Prefer invite code from the invitations table when present; otherwise keep the overlay
    // value (e.g. stewards not yet written through InvitationService).
    return cached.copyWith(inviteCode: dbSteward.inviteCode ?? cached.inviteCode);
  }

  Future<Vault> _hydrate(VaultRow row) async {
    final stewardRows = await _db.stewardDao.activeForVault(row.id);
    final relayRows = await _db.vaultRelayDao.forVault(row.id);
    final distributionSharesByStewardId = await _distributionSharesByStewardForVersion(
      vaultId: row.id,
      distributionVersion: row.currentDistributionVersion,
    );
    final inviteCodeByStewardId = await _inviteCodesByStewardId(row.id);

    final dbStewards = stewardRows
        .map(
          (s) => _stewardFromRow(
            s,
            currentDistributionVersion: row.currentDistributionVersion,
            distributionShareRow: distributionSharesByStewardId[s.id],
            inviteCode: inviteCodeByStewardId[s.id] ?? s.inviteCode,
          ),
        )
        .toList();
    BackupConfig? backupConfig;
    if (dbStewards.isNotEmpty || row.threshold > 0) {
      final overlay = _backupConfigOverlay[row.id];
      final stewards = overlay == null
          ? dbStewards
          : [for (final s in dbStewards) _mergeDbStewardWithBackupOverlay(s, overlay)];
      backupConfig = BackupConfig(
        vaultId: row.id,
        threshold: row.threshold,
        stewards: stewards,
        relays: relayRows.map((r) => r.url).toSet().toList(),
        instructions: row.instructions,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        distributionVersion: row.currentDistributionVersion,
      );
    }

    final recoveryRows = await _db.recoveryDao.forVault(row.id);
    final recoveryRequests = <RecoveryRequest>[];
    for (final rr in recoveryRows) {
      recoveryRequests.add(await recoveryRequestFromRow(_db, rr));
    }

    return Vault(
      id: row.id,
      name: row.name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      ownerPubkey: row.ownerPubkey,
      ownerName: row.ownerName,
      recoveryRequests: recoveryRequests,
      backupConfig: backupConfig,
      archivedAt:
          row.archivedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      archivedReason: row.archivedReason,
      pushEnabled: row.pushEnabled,
    );
  }

  /// Build a [Share] from a [HeldShareRow] supplemented with vault-level
  /// metadata from [vaultRow]. Used by [getSharesForVault].
  ///
  /// Not all [Share] fields are stored in `held_shares` (e.g. stewards list,
  /// ownerName, instructions, relayUrls). Those remain null in the hydrated
  /// Share. The full wire payload is not re-persisted after the gift-wrap is
  /// unwrapped.
  ///
  /// [VaultRow.createdAt] is milliseconds since epoch; [Share.createdAt] and
  /// Nostr `created_at` are Unix seconds — convert here.
  Share _shareFromHeldShareRow(HeldShareRow r, VaultRow vaultRow) {
    return Share(
      payload: r.sharePayload,
      threshold: vaultRow.threshold,
      shareIndex: r.shareIndex,
      totalShares: vaultRow.totalShares,
      primeMod: vaultRow.primeMod ?? '',
      creatorPubkey: vaultRow.ownerPubkey,
      createdAt: vaultRow.createdAt ~/ 1000,
      vaultId: r.vaultId,
      vaultName: vaultRow.name,
      nostrEventId: r.nostrEventId,
      distributionVersion: r.distributionVersion,
      pushEnabled: r.pushEnabled,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(r.receivedAt),
    );
  }

  /// Returns a map of steward id → invite code for non-revoked invitations on [vaultId].
  ///
  /// Includes redeemed invitations so hydrates still expose [Steward.inviteCode] after
  /// acceptance (matching persisted backup-config semantics).
  Future<Map<String, String>> _inviteCodesByStewardId(String vaultId) async {
    final rows = await _db.invitationDao.forVault(vaultId);
    return {
      for (final r in rows)
        if (r.stewardId != null && r.revokedAt == null) r.stewardId!: r.code,
    };
  }

  Steward _stewardFromRow(
    StewardRow row, {
    required int currentDistributionVersion,
    DistributionShareRow? distributionShareRow,
    String? inviteCode,
  }) {
    final isInvited = row.pubkey == null;
    final acknowledgedAtMs = distributionShareRow?.acknowledgedAt;
    final acknowledgedAt =
        acknowledgedAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(acknowledgedAtMs);
    final acknowledgedVersion = distributionShareRow?.acknowledgmentDistributionVersion;
    final isCurrentAck =
        acknowledgedVersion != null && acknowledgedVersion == currentDistributionVersion;

    final status = isInvited
        ? StewardStatus.invited
        : isCurrentAck
            ? StewardStatus.holdingKey
            : acknowledgedVersion != null && acknowledgedVersion < currentDistributionVersion
                ? StewardStatus.awaitingNewKey
                : StewardStatus.awaitingKey;

    final giftWrapEventId = distributionShareRow?.giftWrapEventId;
    return Steward(
      id: row.id,
      pubkey: row.pubkey,
      name: row.name,
      contactInfo: row.contactInfo,
      isOwner: row.isOwner,
      inviteCode: inviteCode,
      status: status,
      giftWrapEventId:
          (giftWrapEventId == null || giftWrapEventId.isEmpty) ? null : giftWrapEventId,
      acknowledgedAt: acknowledgedAt,
      acknowledgmentEventId: distributionShareRow?.acknowledgmentEventId,
      acknowledgedDistributionVersion: acknowledgedVersion,
    );
  }

  Future<Map<String, DistributionShareRow>> _distributionSharesByStewardForVersion({
    required String vaultId,
    required int distributionVersion,
  }) async {
    if (distributionVersion < 0) {
      return const {};
    }

    final distributionId = _distributionId(vaultId, distributionVersion);
    final byId = await (_db.select(
      _db.distributions,
    )..where((d) => d.id.equals(distributionId)))
        .getSingleOrNull();
    final distribution = byId ??
        await (_db.select(_db.distributions)
              ..where((d) => d.vaultId.equals(vaultId) & d.version.equals(distributionVersion)))
            .getSingleOrNull();
    if (distribution == null) {
      return const {};
    }

    final shareRows = await _db.distributionDao.sharesFor(distribution.id);
    return {for (final row in shareRows) row.stewardId: row};
  }

  Future<void> _upsertDistributionShareState({
    required String vaultId,
    required String stewardId,
    required String? stewardGiftWrapEventId,
    required StewardStatus status,
    required String? giftWrapEventId,
    required DateTime? acknowledgedAt,
    required String? acknowledgmentEventId,
    required int? acknowledgedDistributionVersion,
    required int currentDistributionVersion,
  }) async {
    final distributionVersion = acknowledgedDistributionVersion ?? currentDistributionVersion;
    final distributionId = _distributionId(vaultId, distributionVersion);
    final shareId = '${distributionId}_$stewardId';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.distributions).insertOnConflictUpdate(
          DistributionsCompanion.insert(
            id: distributionId,
            vaultId: vaultId,
            version: distributionVersion,
            createdAt: nowMs,
            contentHmac: _placeholderHmac('$vaultId:$distributionVersion'),
          ),
        );

    final existing = await (_db.select(
      _db.distributionShares,
    )..where((s) => s.id.equals(shareId)))
        .getSingleOrNull();
    final persistedGiftWrapEventId = giftWrapEventId ??
        existing?.giftWrapEventId ??
        stewardGiftWrapEventId ??
        acknowledgmentEventId;
    if (persistedGiftWrapEventId == null || persistedGiftWrapEventId.isEmpty) {
      return;
    }

    final sentAtMs =
        giftWrapEventId != null && giftWrapEventId.isNotEmpty ? nowMs : existing?.sentAt;
    final acknowledgedAtMs = status == StewardStatus.holdingKey
        ? (acknowledgedAt ?? DateTime.now()).millisecondsSinceEpoch
        : existing?.acknowledgedAt;
    final ackEvent = status == StewardStatus.holdingKey
        ? (acknowledgmentEventId ?? existing?.acknowledgmentEventId)
        : existing?.acknowledgmentEventId;
    final ackVersion = status == StewardStatus.holdingKey
        ? (acknowledgedDistributionVersion ?? distributionVersion)
        : existing?.acknowledgmentDistributionVersion;

    await _db.into(_db.distributionShares).insertOnConflictUpdate(
          DistributionSharesCompanion(
            id: Value(shareId),
            distributionId: Value(distributionId),
            stewardId: Value(stewardId),
            giftWrapEventId: Value(persistedGiftWrapEventId),
            sentAt: Value(sentAtMs),
            acknowledgedAt: Value(acknowledgedAtMs),
            acknowledgmentEventId: Value(ackEvent),
            acknowledgmentDistributionVersion: Value(ackVersion),
            acknowledgmentCreatedAt: Value(existing?.acknowledgmentCreatedAt),
          ),
        );
  }

  String _distributionId(String vaultId, int version) => '${vaultId}_v$version';

  Future<void> _bumpVaultSync(String vaultId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(
      _db.vaults,
    )..where((v) => v.id.equals(vaultId)))
        .write(VaultsCompanion(lastSyncedAt: Value(now)));
  }

  Future<void> _persistVault(Vault vault) async {
    final createdAtMs = vault.createdAt.millisecondsSinceEpoch;
    final config = vault.backupConfig;
    if (config != null) {
      _backupConfigOverlay[vault.id] = config;
    } else {
      _backupConfigOverlay.remove(vault.id);
    }
    final archivedAtMs = vault.archivedAt?.millisecondsSinceEpoch;
    final archivedReason = vault.archivedAt == null ? null : vault.archivedReason;
    await _db.transaction(() async {
      await _db.into(_db.vaults).insertOnConflictUpdate(
            VaultsCompanion.insert(
              id: vault.id,
              name: vault.name,
              ownerPubkey: vault.ownerPubkey,
              ownerName: Value(vault.ownerName),
              threshold: config?.threshold ?? 0,
              totalShares: config?.totalKeys ?? 0,
              currentDistributionVersion: Value(config?.distributionVersion ?? 0),
              instructions: Value(config?.instructions),
              pushEnabled: Value(vault.pushEnabled),
              archivedAt: Value(archivedAtMs),
              archivedReason: Value(archivedReason),
              createdAt: createdAtMs,
            ),
          );

      // Reconcile stewards from the in-memory backupConfig. Retire all
      // currently active stewards first, then reinsert the authoritative set.
      // Retiring up-front avoids UNIQUE-constraint violations on the partial
      // index (vault_id, share_index) WHERE left_at IS NULL when stewards are
      // reassigned to different positions (e.g. owner added at index 1 while
      // an existing steward also held index 1).
      if (config != null) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final keptIds = config.stewards.map((s) => s.id).toSet();
        final existing = await (_db.select(
          _db.stewards,
        )..where((s) => s.vaultId.equals(vault.id) & s.leftAt.isNull()))
            .get();
        final shareIndexByStewardId = {for (final row in existing) row.id: row.shareIndex};
        final incomingStewardIds = config.stewards.map((s) => s.id).toSet();
        // Preserve historical Shamir slots for stable ingest-side writes when the
        // steward set is unchanged (ack/metadata-only paths). When the backed-up
        // roster introduces any steward id the DB has never seen, treat backup
        // config ordering as authoritative and assign contiguous indices again so
        // owners can insert rows ahead of existing stewards.
        final hasNewStewardId = incomingStewardIds.any(
          (id) => !shareIndexByStewardId.containsKey(id),
        );

        for (final existingRow in existing) {
          // Retire rows removed from the config permanently, and rows that ARE
          // being kept but need a clean re-insert (to avoid position conflicts).
          // Kept rows are immediately re-activated below with left_at = null.
          final willReinsert = keptIds.contains(existingRow.id);
          final idxInConfig = config.stewards.indexWhere((s) => s.id == existingRow.id);
          final int targetShareIndex;
          if (hasNewStewardId) {
            targetShareIndex = idxInConfig >= 0 ? idxInConfig + 1 : existingRow.shareIndex;
          } else {
            targetShareIndex = shareIndexByStewardId[existingRow.id] ??
                (idxInConfig >= 0 ? idxInConfig + 1 : existingRow.shareIndex);
          }
          final conflictsOnPosition = willReinsert && targetShareIndex != existingRow.shareIndex;
          if (!willReinsert || conflictsOnPosition) {
            await (_db.update(_db.stewards)..where((s) => s.id.equals(existingRow.id))).write(
              StewardsCompanion(leftAt: Value(nowMs)),
            );
          }
        }

        for (var i = 0; i < config.stewards.length; i++) {
          final s = config.stewards[i];
          final shareIndex = hasNewStewardId ? (i + 1) : (shareIndexByStewardId[s.id] ?? (i + 1));
          await _db.into(_db.stewards).insertOnConflictUpdate(
                StewardsCompanion.insert(
                  id: s.id,
                  vaultId: vault.id,
                  shareIndex: shareIndex,
                  pubkey: Value(s.pubkey),
                  name: Value(s.name),
                  contactInfo: Value(s.contactInfo),
                  isOwner: Value(s.isOwner),
                  joinedAt: createdAtMs,
                  inviteCode: Value(s.inviteCode),
                ).copyWith(
                  // Clear leftAt so a re-added steward (same ID, previously
                  // soft-retired) becomes visible to activeForVault queries again.
                  leftAt: const Value(null),
                ),
              );
        }

        await _db.vaultRelayDao.replaceForVault(
          vaultId: vault.id,
          role: 'owner',
          rows: [
            for (final url in config.relays)
              VaultRelaysCompanion.insert(
                id: '${vault.id}-$url',
                vaultId: vault.id,
                url: url,
                role: 'owner',
                addedAt: DateTime.now().millisecondsSinceEpoch,
              ),
          ],
        );
      } else {
        // Removing backup config must clear steward and relay rows; otherwise
        // _hydrate would rebuild BackupConfig from stale DB state
        // (dbStewards.isNotEmpty || row.threshold > 0).
        final existing = await (_db.select(
          _db.stewards,
        )..where((s) => s.vaultId.equals(vault.id) & s.leftAt.isNull()))
            .get();
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        for (final existingRow in existing) {
          await (_db.update(_db.stewards)..where((s) => s.id.equals(existingRow.id))).write(
            StewardsCompanion(leftAt: Value(nowMs)),
          );
        }
        await _db.vaultRelayDao.replaceForVault(vaultId: vault.id, role: 'owner', rows: []);
      }
    });
  }

  Uint8List _placeholderHmac(String content) {
    // Phase 1: drift schema requires a non-null `content_hmac`. The keyed
    // HMAC contract (HMAC-SHA-256 under the DB key) lands when the
    // owner-side distribution flow moves into the database; until then we
    // store a deterministic SHA-256 of the content so duplicate writes are
    // stable. Documented in docs/data_layer_refactor_plan.md.
    final digest = sha256.convert(utf8.encode(content));
    return Uint8List.fromList(digest.bytes);
  }
}
