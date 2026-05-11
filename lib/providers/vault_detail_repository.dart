import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../database/app_database.dart';
import '../models/backup_config.dart';
import '../models/share.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../models/vault_detail.dart';
import '../services/logger.dart';

/// Reactive read model for [VaultDetail] backed by the drift database.
///
/// Determines the current device's role for each vault by checking whether
/// an `owned_vaults` row exists (owner) or a `held_shares` row exists
/// (steward). Returns [OwnedVaultDetail] or [StewardedVaultDetail]
/// accordingly.
///
/// **Phase 3 note**: [recoveryRequests] is always empty until the
/// `recovery_requests` table lands. At that point this repository's hydration
/// will include those rows.
class VaultDetailRepository {
  final AppDatabase _db;

  final StreamController<List<VaultDetail>> _listController =
      StreamController<List<VaultDetail>>.broadcast();
  List<VaultDetail>? _latestList;
  final Completer<List<VaultDetail>> _initialCompleter = Completer<List<VaultDetail>>();
  StreamSubscription<List<VaultDetail>>? _vaultRowsSubscription;

  /// Construct a repository backed by [db].
  ///
  /// Production code injects [db] via [vaultDetailRepositoryProvider]. Tests
  /// may omit it to get an in-memory [AppDatabase].
  VaultDetailRepository({AppDatabase? db}) : _db = db ?? AppDatabase(NativeDatabase.memory()) {
    _vaultRowsSubscription = _db.vaultDao.watchAll().asyncMap(_hydrateAll).listen(
      (details) {
        _latestList = details;
        if (!_initialCompleter.isCompleted) {
          _initialCompleter.complete(details);
        }
        _listController.add(details);
      },
      onError: (Object e, StackTrace s) {
        Log.error('VaultDetailRepository hydration failed', e);
        if (!_initialCompleter.isCompleted) {
          _initialCompleter.completeError(e, s);
        }
        _listController.addError(e, s);
      },
    );
  }

  /// Stream of all vault details, seeded with the most recent list.
  Stream<List<VaultDetail>> get vaultListStream async* {
    final latest = _latestList;
    if (latest == null) {
      yield await _initialCompleter.future;
    } else {
      yield latest;
    }
    yield* _listController.stream;
  }

  /// Reactive stream for a single vault. Emits null when the vault is not
  /// found or has been deleted.
  Stream<VaultDetail?> watchVaultDetail(String vaultId) {
    return _db.vaultDao.watchById(vaultId).asyncMap((row) async {
      if (row == null) return null;
      return _hydrateDetail(row);
    });
  }

  /// Fetch a single vault detail by id. Returns null when not found.
  Future<VaultDetail?> getVaultDetail(String vaultId) async {
    final row = await _db.vaultDao.getById(vaultId);
    if (row == null) return null;
    return _hydrateDetail(row);
  }

  void dispose() {
    _vaultRowsSubscription?.cancel();
    _listController.close();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<List<VaultDetail>> _hydrateAll(List<VaultRow> rows) async {
    final result = <VaultDetail>[];
    for (final row in rows) {
      result.add(await _hydrateDetail(row));
    }
    return result;
  }

  Future<VaultDetail> _hydrateDetail(VaultRow row) async {
    final ownedRow = await _db.ownedVaultDao.getByVaultId(row.id);
    final stewardRows = await _db.stewardDao.activeForVault(row.id);
    final relayRows = await _db.vaultRelayDao.forVault(row.id);
    final heldShareRows = await _db.heldShareDao.forVault(row.id);
    final distributionSharesByStewardId = await _distributionSharesByStewardForVersion(
      vaultId: row.id,
      distributionVersion: row.currentDistributionVersion,
    );
    final inviteCodeByStewardId = await _inviteCodesByStewardId(row.id);

    final stewards = stewardRows
        .map(
          (s) => _stewardFromRow(
            s,
            currentDistributionVersion: row.currentDistributionVersion,
            distributionShareRow: distributionSharesByStewardId[s.id],
            inviteCode: inviteCodeByStewardId[s.id],
          ),
        )
        .toList();

    final backupConfig = stewards.isNotEmpty || row.threshold > 0
        ? BackupConfig(
            vaultId: row.id,
            threshold: row.threshold,
            stewards: stewards,
            relays: relayRows.map((r) => r.url).toSet().toList(),
            instructions: row.instructions,
            createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
            distributionVersion: row.currentDistributionVersion,
          )
        : null;

    final createdAt = DateTime.fromMillisecondsSinceEpoch(row.createdAt);
    final archivedAt =
        row.archivedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!);

    if (ownedRow != null) {
      // This device owns the vault.
      Share? selfHeldShare;
      if (heldShareRows.isNotEmpty) {
        selfHeldShare = _shareFromRow(heldShareRows.first, row);
      }
      return OwnedVaultDetail(
        id: row.id,
        name: row.name,
        ownerPubkey: row.ownerPubkey,
        ownerName: row.ownerName,
        threshold: row.threshold,
        totalShares: row.totalShares,
        stewards: stewards,
        recoveryRequests: const [],
        pushEnabled: row.pushEnabled,
        createdAt: createdAt,
        archivedAt: archivedAt,
        archivedReason: row.archivedReason,
        backupConfig: backupConfig,
        content: ownedRow.content,
        selfHeldShare: selfHeldShare,
      );
    }

    // Steward (or awaiting-share) case.
    final latestShare = heldShareRows.isNotEmpty ? _shareFromRow(heldShareRows.first, row) : null;
    return StewardedVaultDetail(
      id: row.id,
      name: row.name,
      ownerPubkey: row.ownerPubkey,
      ownerName: row.ownerName,
      threshold: row.threshold,
      totalShares: row.totalShares,
      stewards: stewards,
      recoveryRequests: const [],
      pushEnabled: row.pushEnabled,
      createdAt: createdAt,
      archivedAt: archivedAt,
      archivedReason: row.archivedReason,
      backupConfig: backupConfig,
      latestShare: latestShare,
    );
  }

  Share _shareFromRow(HeldShareRow r, VaultRow vaultRow) {
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

  Future<Map<String, DistributionShareRow>> _distributionSharesByStewardForVersion({
    required String vaultId,
    required int distributionVersion,
  }) async {
    if (distributionVersion < 0) {
      return const {};
    }

    final distributionId = _distributionId(vaultId, distributionVersion);
    final byId = await (_db.select(_db.distributions)..where((d) => d.id.equals(distributionId)))
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

  Future<Map<String, String>> _inviteCodesByStewardId(String vaultId) async {
    final rows = await _db.invitationDao.forVault(vaultId);
    return {
      for (final r in rows)
        if (r.stewardId != null && r.acceptedAt == null && r.revokedAt == null)
          r.stewardId!: r.code,
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

  String _distributionId(String vaultId, int version) => '${vaultId}_v$version';
}
