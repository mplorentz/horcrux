import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../models/backup_config.dart';
import '../models/recovery_request.dart';
import '../models/share.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../models/vault.dart';
import '../services/login_service.dart';
import '../services/logger.dart';
import 'key_provider.dart';

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
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final repository = VaultRepository(
    ref.read(loginServiceProvider),
    db: ref.read(appDatabaseProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
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
/// **Still Phase 1 / stub behavior**:
///
/// - `Vault.recoveryRequests` always hydrates to `[]`. The
///   `recovery_requests` / `recovery_responses` tables land in Phase 3; until
///   then [addRecoveryRequestToVault] and [updateRecoveryRequestInVault]
///   throw [UnimplementedError].
/// - `BackupConfig` is hydrated from `vaults` + `owned_vaults` + active
///   `stewards` (`StewardDao.activeForVault`). [updateBackupConfig] writes
///   the same triple back atomically.
class VaultRepository {
  final AppDatabase _db;
  // Held for parity with the legacy API; encryption is handled by SQLCipher
  // at the DB layer rather than by per-row NIP-44 (except for
  // `owned_vaults.content`, which `BackupService` already encrypts).
  // ignore: unused_field
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

  /// Update the textual fields of an existing vault.
  Future<void> updateVault(String id, String name, String content) async {
    final existing = await getVault(id);
    if (existing == null) {
      throw ArgumentError('Vault not found: $id');
    }
    await _persistVault(existing.copyWith(name: name, content: content));
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
      await _db.delete(_db.distributionShares).go();
      await _db.delete(_db.distributions).go();
      await _db.delete(_db.stewards).go();
      await _db.delete(_db.ownedVaults).go();
      await _db.delete(_db.vaultRelays).go();
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
    Log.info('Updated steward $pubkey status to $status in vault $vaultId');
  }

  // ========== Share management (`held_shares` table) ==========

  /// True when this device owns [vaultId] (an `owned_vaults` row exists).
  Future<bool> isOwnedVault(String vaultId) async {
    final row = await _db.ownedVaultDao.getByVaultId(vaultId);
    return row != null;
  }

  /// Write [share] into the `held_shares` table and prune old versions.
  ///
  /// Also bumps `vaults.last_synced_at` so the reactive vault stream
  /// re-emits and callers see the updated [Vault.shares].
  Future<void> addShareToVault(String vaultId, Share share) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '${vaultId}_${share.shareIndex}_${share.distributionVersion ?? 0}_$now';

    await _db.transaction(() async {
      await _db.heldShareDao.insertIfNew(HeldSharesCompanion.insert(
        id: id,
        vaultId: vaultId,
        shareIndex: share.shareIndex,
        sharePayload: share.payload,
        distributionVersion: share.distributionVersion ?? 0,
        receivedAt: now,
        nostrEventId: Value(share.nostrEventId),
        lastSeenRelay: Value(share.relayUrls?.isNotEmpty == true ? share.relayUrls!.first : null),
        pushEnabled: Value(share.pushEnabled ?? true),
      ));
      await _db.heldShareDao.pruneOldVersions(vaultId);
      // Touch last_synced_at so the vaults watchAll() stream re-emits and
      // _hydrateAll picks up the new held_shares row.
      await (_db.update(_db.vaults)..where((v) => v.id.equals(vaultId))).write(
        VaultsCompanion(lastSyncedAt: Value(now)),
      );
    });
    Log.info(
      'addShareToVault: wrote held_share for vault $vaultId '
      '(shareIndex=${share.shareIndex}, version=${share.distributionVersion})',
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
  Future<void> upsertStewardRow({
    required String id,
    required String vaultId,
    required int shareIndex,
    String? pubkey,
    String? name,
    bool isOwner = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.stewardDao.upsert(
      StewardsCompanion.insert(
        id: id,
        vaultId: vaultId,
        shareIndex: shareIndex,
        pubkey: Value(pubkey),
        name: Value(name),
        isOwner: Value(isOwner),
        joinedAt: now,
      ).copyWith(leftAt: const Value(null)),
    );
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

  Future<void> deleteVaultContent(String vaultId) async {
    final existing = await getVault(vaultId);
    if (existing == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    await _persistVault(existing.copyWithContentDeleted());
    Log.info('Deleted content for vault $vaultId');
  }

  Future<bool> isKeyHolderForVault(String vaultId) async {
    final vault = await getVault(vaultId);
    if (vault == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    return vault.isSteward;
  }

  // ========== Recovery Request Management (Phase 3) ==========

  Future<void> addRecoveryRequestToVault(
    String vaultId,
    RecoveryRequest request,
  ) {
    throw UnimplementedError(
      'addRecoveryRequestToVault: recovery_requests is restored in Phase 3.',
    );
  }

  Future<void> updateRecoveryRequestInVault(
    String vaultId,
    String requestId,
    RecoveryRequest updatedRequest,
  ) {
    throw UnimplementedError(
      'updateRecoveryRequestInVault: recovery_requests is restored in Phase 3.',
    );
  }

  Future<List<RecoveryRequest>> getRecoveryRequestsForVault(
    String vaultId,
  ) async {
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

  Future<Vault> _hydrate(VaultRow row) async {
    final ownedRow = await _db.ownedVaultDao.getByVaultId(row.id);
    final stewardRows = await _db.stewardDao.activeForVault(row.id);
    final relayRows = await _db.vaultRelayDao.forVault(row.id);
    final heldShareRows = await _db.heldShareDao.forVault(row.id);

    final dbStewards = stewardRows.map(_stewardFromRow).toList();
    BackupConfig? backupConfig;
    if (dbStewards.isNotEmpty || row.threshold > 0) {
      final overlay = _backupConfigOverlay[row.id];
      final stewards = overlay == null
          ? dbStewards
          : [
              for (final s in dbStewards)
                overlay.stewards.firstWhere(
                  (cached) => cached.id == s.id,
                  orElse: () => s,
                ),
            ];
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

    // Back-compat shim (Phase 2a): populate Vault.shares from held_shares.
    // Phases 2b/2c will introduce the sealed VaultDetail read model and
    // eventually drop this field.
    final shares = heldShareRows.map((r) => _shareFromHeldShareRow(r, row)).toList();

    return Vault(
      id: row.id,
      name: row.name,
      content: ownedRow?.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      ownerPubkey: row.ownerPubkey,
      ownerName: row.ownerName,
      shares: shares,
      recoveryRequests: const [],
      backupConfig: backupConfig,
      archivedAt:
          row.archivedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      archivedReason: row.archivedReason,
      pushEnabled: row.pushEnabled,
    );
  }

  /// Build a [Share] from a [HeldShareRow] supplemented with vault-level
  /// metadata from [vaultRow]. Used both in [_hydrate] and [getSharesForVault].
  ///
  /// Not all [Share] fields are stored in `held_shares` (e.g. stewards list,
  /// ownerName, instructions, relayUrls). Those remain null in the hydrated
  /// Share — sufficient for UI that reads [Vault.shares]. The full wire
  /// payload is not re-persisted after the gift-wrap is unwrapped.
  ///
  /// [VaultRow.createdAt] is milliseconds since epoch ([_persistVault]); [Share.createdAt]
  /// and Nostr `created_at` are Unix seconds — convert here so [Share.ageInSeconds],
  /// [Share.isRecent], and [shareToJson] stay correct.
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

  Steward _stewardFromRow(StewardRow row) {
    return Steward(
      id: row.id,
      pubkey: row.pubkey,
      name: row.name,
      contactInfo: row.contactInfo,
      isOwner: row.isOwner,
      // Phase 1 placeholder: status is not stored yet (lands in Phase 2/3
      // alongside `distribution_shares` ack timestamps). Default to a safe
      // value; the in-memory copy held by callers between writes already
      // carries the precise status.
      status: row.pubkey == null ? StewardStatus.invited : StewardStatus.awaitingKey,
    );
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
              currentDistributionVersion: Value(
                config?.distributionVersion ?? 0,
              ),
              instructions: Value(config?.instructions),
              pushEnabled: Value(vault.pushEnabled),
              archivedAt: Value(archivedAtMs),
              archivedReason: Value(archivedReason),
              createdAt: createdAtMs,
            ),
          );

      if (vault.content != null) {
        await _db.into(_db.ownedVaults).insertOnConflictUpdate(
              OwnedVaultsCompanion.insert(
                vaultId: vault.id,
                content: vault.content!,
                contentHmac: _placeholderHmac(vault.content!),
                createdBySelfAt: createdAtMs,
              ),
            );
      } else {
        await (_db.delete(
          _db.ownedVaults,
        )..where((v) => v.vaultId.equals(vault.id)))
            .go();
      }

      // Reconcile stewards from the in-memory backupConfig. Phase 1 writes
      // active stewards out as plain rows; the append-on-replace history
      // bookkeeping lands in later phases. We replace-by-id for now: insert
      // any new ids, leave existing rows in place, and soft-retire ones
      // missing from the config.
      if (config != null) {
        final keptIds = config.stewards.map((s) => s.id).toSet();
        final existing = await (_db.select(
          _db.stewards,
        )..where((s) => s.vaultId.equals(vault.id) & s.leftAt.isNull()))
            .get();
        for (final existingRow in existing) {
          if (!keptIds.contains(existingRow.id)) {
            await (_db.update(
              _db.stewards,
            )..where((s) => s.id.equals(existingRow.id)))
                .write(
              StewardsCompanion(
                leftAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
          }
        }

        for (var i = 0; i < config.stewards.length; i++) {
          final s = config.stewards[i];
          await _db.into(_db.stewards).insertOnConflictUpdate(
                StewardsCompanion.insert(
                  id: s.id,
                  vaultId: vault.id,
                  shareIndex: i + 1,
                  pubkey: Value(s.pubkey),
                  name: Value(s.name),
                  contactInfo: Value(s.contactInfo),
                  isOwner: Value(s.isOwner),
                  joinedAt: createdAtMs,
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
          await (_db.update(
            _db.stewards,
          )..where((s) => s.id.equals(existingRow.id)))
              .write(
            StewardsCompanion(
              leftAt: Value(nowMs),
            ),
          );
        }
        await _db.vaultRelayDao.replaceForVault(
          vaultId: vault.id,
          role: 'owner',
          rows: [],
        );
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
