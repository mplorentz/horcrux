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
import '../models/shard_data.dart';
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
/// `stewards`).
///
/// **Phase 1 behavior** — see `docs/data_layer_refactor_plan.md`:
///
/// - `Vault.shards` always hydrates to `[]`. The `held_shares` table lands in
///   Phase 2; until then [addShardToVault], [getShardsForVault], and
///   [clearShardsForVault] throw [UnimplementedError]. Mocks should match.
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

  final StreamController<List<Vault>> _vaultsController =
      StreamController<List<Vault>>.broadcast();
  List<Vault> _latest = const [];
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
    _vaultRowsSubscription = _db.vaultDao
        .watchAll()
        .asyncMap(_hydrateAll)
        .listen(
          (vaults) {
            _latest = vaults;
            _vaultsController.add(vaults);
          },
          onError: (Object e, StackTrace s) {
            Log.error('vaultsStream hydration failed', e);
            _vaultsController.addError(e, s);
          },
        );
  }

  /// Stream that replays the most recent hydrated vault list to new
  /// subscribers, then emits subsequent updates.
  Stream<List<Vault>> get vaultsStream async* {
    yield _latest;
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

  // ========== Shard Management (Phase 2 — `held_shares` table) ==========

  Future<void> addShardToVault(String vaultId, ShardData shard) {
    throw UnimplementedError(
      'addShardToVault: held_shares is restored in Phase 2 of the data layer '
      'refactor. See docs/data_layer_refactor_plan.md.',
    );
  }

  Future<List<ShardData>> getShardsForVault(String vaultId) async {
    final vault = await getVault(vaultId);
    if (vault == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }
    return List.unmodifiable(vault.shards);
  }

  Future<void> clearShardsForVault(String vaultId) {
    throw UnimplementedError(
      'clearShardsForVault: held_shares is restored in Phase 2.',
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

    return Vault(
      id: row.id,
      name: row.name,
      content: ownedRow?.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      ownerPubkey: row.ownerPubkey,
      ownerName: row.ownerName,
      shards: const [],
      recoveryRequests: const [],
      backupConfig: backupConfig,
      isArchived: row.archivedAt != null,
      archivedAt: row.archivedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      archivedReason: row.archivedReason,
      pushEnabled: row.pushEnabled,
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
      status: row.pubkey == null
          ? StewardStatus.invited
          : StewardStatus.awaitingKey,
    );
  }

  Future<void> _persistVault(Vault vault) async {
    final createdAtMs = vault.createdAt.millisecondsSinceEpoch;
    final config = vault.backupConfig;
    if (config != null) {
      _backupConfigOverlay[vault.id] = config;
    }
    await _db.transaction(() async {
      await _db
          .into(_db.vaults)
          .insertOnConflictUpdate(
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
              archivedAt: Value(vault.archivedAt?.millisecondsSinceEpoch),
              archivedReason: Value(vault.archivedReason),
              createdAt: createdAtMs,
            ),
          );

      if (vault.content != null) {
        await _db
            .into(_db.ownedVaults)
            .insertOnConflictUpdate(
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
        )..where((v) => v.vaultId.equals(vault.id))).go();
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
        )..where((s) => s.vaultId.equals(vault.id) & s.leftAt.isNull())).get();
        for (final existingRow in existing) {
          if (!keptIds.contains(existingRow.id)) {
            await (_db.update(
              _db.stewards,
            )..where((s) => s.id.equals(existingRow.id))).write(
              StewardsCompanion(
                leftAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
          }
        }

        for (var i = 0; i < config.stewards.length; i++) {
          final s = config.stewards[i];
          await _db
              .into(_db.stewards)
              .insertOnConflictUpdate(
                StewardsCompanion.insert(
                  id: s.id,
                  vaultId: vault.id,
                  shareIndex: i + 1,
                  pubkey: Value(s.pubkey),
                  name: Value(s.name),
                  contactInfo: Value(s.contactInfo),
                  isOwner: Value(s.isOwner),
                  joinedAt: createdAtMs,
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
