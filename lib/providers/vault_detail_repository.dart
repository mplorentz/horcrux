import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../database/app_database.dart';
import '../database/recovery_request_hydration.dart';
import '../models/backup_config.dart';
import '../models/recovery_request.dart';
import '../models/share.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../models/vault_detail.dart';
import '../services/logger.dart';
import '../services/login_service.dart';

/// Reactive read model for [VaultDetail] backed by the drift database.
///
/// [OwnedVaultDetail] is emitted when an `owned_vaults` row exists **and**
/// either [LoginService] was omitted (tests: legacy rule) or the logged-in hex
/// pubkey matches [VaultRow.ownerPubkey]. Otherwise a leftover `owned_vaults`
/// row is ignored and [StewardedVaultDetail] is used so UI role gates stay
/// consistent with [VaultDetail.isVaultOwner].
///
/// Recovery rows are read from `recovery_requests` (participants and
/// responses included) when building each [VaultDetail].
class VaultDetailRepository {
  final AppDatabase _db;
  final LoginService? _loginService;

  final StreamController<List<VaultDetail>> _listController =
      StreamController<List<VaultDetail>>.broadcast();
  List<VaultDetail>? _latestList;
  final Completer<List<VaultDetail>> _initialCompleter = Completer<List<VaultDetail>>();
  StreamSubscription<List<VaultDetail>>? _vaultRowsSubscription;

  /// Construct a repository backed by [db].
  ///
  /// Production injects [db] and [loginService] via [vaultDetailRepositoryProvider].
  /// Tests may omit [loginService] (any `owned_vaults` row ⇒ owner).
  VaultDetailRepository({AppDatabase? db, LoginService? loginService})
      : _db = db ?? AppDatabase(NativeDatabase.memory()),
        _loginService = loginService {
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
    // Re-hydrate when the vault row changes, when steward / held_share rows
    // change, and when recovery request rows change — otherwise the detail
    // screen can show a stale "Initiate Recovery" vs "Manage Recovery" label
    // until an unrelated write.
    return Stream<VaultDetail?>.multi((controller) {
      var closed = false;

      Future<void> emit() async {
        if (closed) return;
        try {
          final row = await _db.vaultDao.getById(vaultId);
          if (closed) return;
          controller.add(row == null ? null : await _hydrateDetail(row));
        } catch (e, st) {
          if (!closed) controller.addError(e, st);
        }
      }

      final subs = <StreamSubscription<dynamic>>[
        _db.vaultDao.watchById(vaultId).listen((_) => emit()),
        _db.stewardDao.watchActiveForVault(vaultId).listen((_) => emit()),
        _db.heldShareDao.watchForVault(vaultId).listen((_) => emit()),
        _db.recoveryDao.watchForVault(vaultId).listen((_) => emit()),
      ];

      controller.onCancel = () {
        closed = true;
        for (final s in subs) {
          s.cancel();
        }
      };

      emit();
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

  Future<bool> _deviceTreatsOwnedRowAsVaultOwner({
    required VaultRow row,
    required OwnedVaultRow? ownedRow,
  }) async {
    if (ownedRow == null) return false;
    final svc = _loginService;
    if (svc == null) return true;
    final localPubkey = await svc.getCurrentPublicKey();
    if (localPubkey != null && localPubkey != row.ownerPubkey) {
      Log.warning(
        'Ignoring stale owned_vaults for vault ${row.id}: '
        'logged-in pubkey does not match vault owner pubkey.',
      );
      return false;
    }
    return true;
  }

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
    final recoveryRows = await _db.recoveryDao.forVault(row.id);
    final recoveryRequests = <RecoveryRequest>[];
    for (final rr in recoveryRows) {
      recoveryRequests.add(await recoveryRequestFromRow(_db, rr));
    }

    final stewards = stewardRows
        .map(
          (s) => _stewardFromRow(
            s,
            currentDistributionVersion: row.currentDistributionVersion,
            distributionShareRow: distributionSharesByStewardId[s.id],
            inviteCode: inviteCodeByStewardId[s.id] ?? s.inviteCode,
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

    final deviceIsVaultOwner = await _deviceTreatsOwnedRowAsVaultOwner(
      row: row,
      ownedRow: ownedRow,
    );

    final createdAt = DateTime.fromMillisecondsSinceEpoch(row.createdAt);
    final archivedAt =
        row.archivedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!);

    if (deviceIsVaultOwner && ownedRow != null) {
      // This device owns the vault (see [_deviceTreatsOwnedRowAsVaultOwner]).
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
        recoveryRequests: recoveryRequests,
        pushEnabled: row.pushEnabled,
        createdAt: createdAt,
        archivedAt: archivedAt,
        archivedReason: row.archivedReason,
        backupConfig: backupConfig,
        content: ownedRow.content,
        selfHeldShare: selfHeldShare,
      );
    }

    // Steward (or awaiting-share) case — includes stale `owned_vaults`.
    final latestShare = heldShareRows.isNotEmpty ? _shareFromRow(heldShareRows.first, row) : null;
    return StewardedVaultDetail(
      id: row.id,
      name: row.name,
      ownerPubkey: row.ownerPubkey,
      ownerName: row.ownerName,
      threshold: row.threshold,
      totalShares: row.totalShares,
      stewards: stewards,
      recoveryRequests: recoveryRequests,
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
    final byId = await (_db.select(
      _db.distributions,
    )..where((d) => d.id.equals(distributionId)))
        .getSingleOrNull();
    final distribution = byId ??
        await (_db.select(_db.distributions)
              ..where(
                (d) => d.vaultId.equals(vaultId) & d.version.equals(distributionVersion),
              ))
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

    final status = isInvited
        ? StewardStatus.invited
        : stewardStatusFromDistributionAck(
            acknowledgedDistributionVersion: acknowledgedVersion,
            currentDistributionVersion: currentDistributionVersion,
          );
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
