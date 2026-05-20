import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../models/invitation_link.dart';
import '../models/share.dart';
import '../models/vault.dart';
import '../models/nostr_kinds.dart';
import '../providers/vault_provider.dart';
import 'horcrux_notification_service.dart';
import 'logger.dart';
import 'ndk_service.dart';
import 'push_notification_receiver.dart';
import 'relay_scan_service.dart';

/// Resolves the Shamir slot (0-based) for an embedded steward entry.
///
/// Prefer explicit [shard_index] from the owner payload (matches
/// [BackupConfig.stewards] ordering used at distribution). Legacy payloads
/// without it fall back to this device's [Share.shareIndex] when the entry is
/// for the recipient, then to [filteredEnumerationIndex] (enumerating only
/// pubkey-known stewards in wire order).
int _shardSlotZeroBasedFromEmbedded({
  required Map<String, String> steward,
  required int filteredEnumerationIndex,
  required Share share,
  required String? recipientPubkeyHex,
}) {
  final raw = steward['shard_index'];
  if (raw != null && raw.isNotEmpty) {
    final parsed = int.tryParse(raw);
    if (parsed != null && parsed >= 0) return parsed;
  }
  final pk = steward['pubkey'];
  if (recipientPubkeyHex != null && pk == recipientPubkeyHex) {
    // Manifest shares use shareIndex -1 (no Shamir slot); never propagate -1
    // into steward slot derivation.
    if (share.isManifest) return filteredEnumerationIndex;
    return share.shareIndex;
  }
  return filteredEnumerationIndex;
}

String _resolvedEmbeddedStewardRowId({
  required String vaultId,
  required Map<String, String> steward,
  required int slotZeroBased,
}) {
  final id = steward['id'];
  if (id != null && id.isNotEmpty) return id;
  final pubkey = steward['pubkey'] ?? '';
  return 'wire_${vaultId}_${slotZeroBased}_$pubkey';
}

/// Provider for VaultShareService
final vaultShareServiceProvider = Provider<VaultShareService>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  return VaultShareService(
    repository,
    () => ref.read(ndkServiceProvider),
    () => ref.read(horcruxNotificationServiceProvider),
    () => ref.read(pushNotificationReceiverProvider),
    () => ref.read(relayScanServiceProvider),
  );
});

/// Service for managing vault shares (steward-side) and related Nostr flows.
///
/// Steward-side held shares live in the `held_shares` drift table via
/// [VaultRepository]. Collected recovery shards are stored in
/// `recovery_responses` through [RecoveryService] / [VaultRepository], not here.
class VaultShareService {
  final VaultRepository repository;
  final NdkService Function() _getNdkService;
  final HorcruxNotificationService Function() _getNotificationService;
  final PushNotificationReceiver Function() _getPushReceiver;
  final RelayScanService Function() _getRelayScanService;

  VaultShareService(
    this.repository,
    this._getNdkService,
    this._getNotificationService,
    this._getPushReceiver,
    this._getRelayScanService,
  );

  // ── Steward-side share management (backed by `held_shares` table) ──

  /// Get all shares for a vault from the DB.
  Future<List<Share>> getVaultShares(String vaultId) async {
    return repository.getSharesForVault(vaultId);
  }

  /// Get the most recent share for a vault, or null if none exist.
  Future<Share?> getVaultShare(String vaultId) async {
    return latestShare(await repository.getSharesForVault(vaultId));
  }

  /// Add or update share data for a vault.
  ///
  /// Writes to the `held_shares` drift table via [VaultRepository].
  /// Also upserts the `vaults` row and self-steward row on the steward side
  /// when [VaultRepository.isOwnedVaultForCurrentUser] is false (subject to the
  /// version gate inside [_upsertStewardVaultAndSelf]).
  Future<void> addVaultShare(String vaultId, Share share) async {
    if (!share.isValid) throw ArgumentError('Invalid shard data');
    if (share.isManifest) {
      throw ArgumentError('Manifest shares must use processVaultShare');
    }

    final ownedByThisDevice = await repository.isOwnedVaultForCurrentUser(vaultId);

    if (!ownedByThisDevice) {
      // Steward-side: upsert vault and self-steward (version-gated).
      await _upsertStewardVaultAndSelf(vaultId, share);
    }

    await repository.addShareToVault(vaultId, share);
    Log.info(
      'addVaultShare: stored share for vault $vaultId '
      '(shareIndex=${share.shareIndex}, version=${share.distributionVersion})',
    );
  }

  /// Process a received vault share (invitation flow).
  ///
  /// Full flow for a normal shard:
  /// 1. Dedup check — skip if we already have this nostrEventId.
  /// 2. [addVaultShare] — upsert vault/steward rows + write held_share.
  /// 3. Opt into push if the owner has push enabled.
  /// 4. Send share confirmation event to owner.
  ///
  /// **Manifest-only** shares ([Share.isManifest]): metadata-only 713 for
  /// owner rehydration — skips `held_shares`, confirmation (718), and
  /// phantom self-steward upsert; may insert an `owned_vaults` shell when the
  /// ingesting pubkey is the vault owner on a fresh device.
  ///
  /// When the vault row already reflects a **newer** distribution (from prior
  /// manifests or held shares), a **stale** manifest (lower or equal
  /// [Share.distributionVersion]) is ignored so relays cannot roll back
  /// metadata.
  Future<void> processVaultShare(String vaultId, Share shardData) async {
    if (!shardData.isValid) throw ArgumentError('Invalid shard data');

    // Dedup by nostrEventId. If the vault doesn't exist yet, skip the check
    // and let addVaultShare create it.
    if (shardData.nostrEventId != null) {
      try {
        final existingShares = await repository.getSharesForVault(vaultId);
        final hasDuplicate = existingShares.any(
          (s) => s.nostrEventId != null && s.nostrEventId == shardData.nostrEventId,
        );
        if (hasDuplicate) {
          Log.info(
            'processVaultShare: share ${shardData.nostrEventId} already stored '
            'for vault $vaultId — skipping',
          );
          return;
        }
      } on ArgumentError {
        // Vault not found — first time seeing this vault; proceed to create it.
      }
    }

    if (shardData.isManifest) {
      final vault = await repository.getVault(vaultId);
      if (vault != null) {
        final maxHeldDist = await repository.maxHeldShareDistributionVersion(vaultId);
        final vaultRowDist = vault.backupConfig?.distributionVersion ?? -1;
        final storedHighWater = maxHeldDist > vaultRowDist ? maxHeldDist : vaultRowDist;
        final incoming = shardData.distributionVersion ?? 0;
        if (incoming <= storedHighWater) {
          Log.info(
            'processVaultShare: ignored stale manifest for vault $vaultId '
            '(incoming distributionVersion=$incoming, storedHighWater=$storedHighWater)',
          );
          // Same-version replay can arrive after reinstall: `vaults` already
          // reflects this distribution but `owned_vaults` is missing. Still
          // materialize the owner shell when the ingesting key is the creator.
          final pkStale = await _getNdkService().getCurrentPubkey();
          if (pkStale != null && pkStale == shardData.creatorPubkey) {
            await repository.ensureOwnedVaultShell(vaultId);
          }
          return;
        }
      }

      final ownedBefore = await repository.isOwnedVaultForCurrentUser(vaultId);
      await _upsertStewardVaultAndSelf(vaultId, shardData);
      final pk = await _getNdkService().getCurrentPubkey();
      if (!ownedBefore && pk != null && pk == shardData.creatorPubkey) {
        await repository.ensureOwnedVaultShell(vaultId);
      }
      Log.info(
        'processVaultShare: applied manifest metadata for vault $vaultId '
        '(distributionVersion=${shardData.distributionVersion})',
      );

      // Sync relay URLs so the steward subscribes to the updated relay set
      if (shardData.relayUrls != null && shardData.relayUrls!.isNotEmpty) {
        await _getRelayScanService().syncRelaysFromUrls(shardData.relayUrls!);
      }

      return;
    }

    await addVaultShare(vaultId, shardData);

    if (shardData.pushEnabled == true && PushNotificationReceiver.isSupported) {
      try {
        final receiver = _getPushReceiver();
        if (!await receiver.isOptedIn()) await receiver.optIn();
      } catch (e, st) {
        Log.warning('Steward push opt-in after share delivery failed', e, st);
      }
    }

    try {
      if (shardData.relayUrls != null && shardData.relayUrls!.isNotEmpty) {
        // Sync the share's relay URLs so the steward subscribes to them
        await _getRelayScanService().syncRelaysFromUrls(shardData.relayUrls!);

        final eventId = await sendShareConfirmationEvent(
          vaultId: vaultId,
          shareIndex: shardData.shareIndex,
          ownerPubkey: shardData.creatorPubkey,
          relayUrls: shardData.relayUrls!,
          distributionVersion: shardData.distributionVersion,
        );
        if (eventId != null) {
          Log.info(
            'processVaultShare: sent confirmation $eventId for vault $vaultId '
            'share ${shardData.shareIndex}',
          );
        } else {
          Log.warning(
            'processVaultShare: failed to send confirmation for vault $vaultId '
            'share ${shardData.shareIndex}',
          );
        }
      } else {
        Log.warning(
          'processVaultShare: no relay URLs in share for vault $vaultId — '
          'cannot send confirmation',
        );
      }
    } catch (e) {
      Log.error(
        'processVaultShare: error sending confirmation for vault $vaultId',
        e,
      );
    }
  }

  /// Creates and publishes a share confirmation event (kind 718).
  Future<String?> sendShareConfirmationEvent({
    required String vaultId,
    required int shareIndex,
    required String ownerPubkey,
    required List<String> relayUrls,
    int? distributionVersion,
  }) async {
    try {
      final ndkService = _getNdkService();
      final currentPubkey = await ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        Log.error('sendShareConfirmationEvent: no key pair available');
        return null;
      }

      final tags = [
        ['vault_id', vaultId],
        ['share_index', shareIndex.toString()],
        ['confirmed_at', DateTime.now().toIso8601String()],
        if (distributionVersion != null) ['distribution_version', distributionVersion.toString()],
      ];

      final publishedEvent = await ndkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.shareConfirmation.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: tags,
      );

      if (publishedEvent != null) {
        final vault = await repository.getVault(vaultId);
        if (vault != null) {
          await _getNotificationService().tryPushForEvent(
            event: publishedEvent,
            kind: NostrKind.shareConfirmation,
            vault: vault,
            relayHints: relayUrls,
          );
        }
      }

      return publishedEvent?.id;
    } catch (e) {
      Log.error('sendShareConfirmationEvent: error', e);
      return null;
    }
  }

  /// Check if user is a steward for a vault.
  Future<bool> isKeyHolderForVault(String vaultId) async {
    return repository.isKeyHolderForVault(vaultId);
  }

  /// Get share count for a vault.
  Future<int> getShardCount(String vaultId) async {
    final shares = await repository.getSharesForVault(vaultId);
    return shares.length;
  }

  /// Remove all shares for a vault.
  Future<void> removeVaultShare(String vaultId) async {
    await repository.clearSharesForVault(vaultId);
    Log.info('removeVaultShare: removed all held_shares for vault $vaultId');
  }

  /// Process a steward removal event (kind keyHolderRemoved).
  ///
  /// Archives the vault and deletes its held share.
  Future<void> processKeyHolderRemoval({required Nip01Event event}) async {
    try {
      if (event.kind != NostrKind.keyHolderRemoved.value) {
        throw ArgumentError(
          'Invalid event kind: expected ${NostrKind.keyHolderRemoved.value}, '
          'got ${event.kind}',
        );
      }

      // New canonical format: read vault_id from tags, owner from event.pubKey
      final vaultId = _extractTagValue(event.tags, 'vault_id');
      if (vaultId == null || vaultId.isEmpty) {
        throw ArgumentError('Missing vault_id tag in steward removed event');
      }

      Log.info(
        'processKeyHolderRemoval: vault ${vaultId.substring(0, 8)}...',
      );

      final vault = await repository.getVault(vaultId);
      if (vault == null) {
        Log.warning(
          'processKeyHolderRemoval: vault $vaultId not found — may already be deleted',
        );
        return;
      }

      await repository.saveVault(
        vault.copyWith(
          archivedAt: DateTime.now(),
          archivedReason: 'Removed by owner',
        ),
      );
      Log.info('processKeyHolderRemoval: archived vault $vaultId');

      await removeVaultShare(vaultId);
      Log.info('processKeyHolderRemoval: removed share for vault $vaultId');
    } catch (e) {
      Log.error('processKeyHolderRemoval: error processing event ${event.id}', e);
      rethrow;
    }
  }

  // ── Private helpers ──

  /// Upsert the `vaults` row and self-steward row from [share] on the steward
  /// side. Version-gated: only applies if the incoming
  /// [Share.distributionVersion] is **greater than** the higher of (a) the max
  /// version on held shares and (b) the vault row's current distribution
  /// version (see [Vault.backupConfig.distributionVersion] when hydrated).
  ///
  /// Ownership check (skip if this device owns the vault) is done by the
  /// caller before invoking this helper.
  Future<void> _upsertStewardVaultAndSelf(String vaultId, Share share) async {
    final existing = await repository.getVault(vaultId);
    final incomingVersion = share.distributionVersion ?? 0;

    if (existing == null) {
      // First time we see this vault — create the vault row.
      final vault = Vault(
        id: vaultId,
        name: share.vaultName ?? defaultVaultName,
        createdAt: DateTime.fromMillisecondsSinceEpoch(share.createdAt * 1000),
        ownerPubkey: share.creatorPubkey,
        ownerName: share.ownerName,
        pushEnabled: share.pushEnabled ?? false,
      );
      await repository.addVault(vault);
      Log.info('_upsertStewardVaultAndSelf: created vault record $vaultId');
    } else {
      // Version-gate: only update vault metadata if incoming version is newer.
      // Held shares drive the steward case; manifest-only 713 never writes
      // `held_shares`, so also compare to the vault row's current distribution
      // (hydrated as [Vault.backupConfig.distributionVersion]) so a late stale
      // manifest cannot roll back [Vault.name] / owner display fields.
      final maxHeldDist = await repository.maxHeldShareDistributionVersion(vaultId);
      final vaultRowDist = existing.backupConfig?.distributionVersion ?? -1;
      final storedVersion = maxHeldDist > vaultRowDist ? maxHeldDist : vaultRowDist;
      if (incomingVersion > storedVersion) {
        var updated = existing;
        if (share.vaultName != null && share.vaultName != existing.name) {
          updated = updated.copyWith(name: share.vaultName!);
        }
        if (share.ownerName != null && share.ownerName != existing.ownerName) {
          updated = updated.copyWith(ownerName: share.ownerName);
        }
        if (share.pushEnabled != null && share.pushEnabled != existing.pushEnabled) {
          updated = updated.copyWith(pushEnabled: share.pushEnabled!);
        }
        if (!identical(updated, existing)) {
          await repository.saveVault(updated);
          Log.info(
            '_upsertStewardVaultAndSelf: updated vault $vaultId metadata '
            '(version $incomingVersion)',
          );
        }
      }
    }

    final currentPubkey = await _getNdkService().getCurrentPubkey();

    // Upsert every steward advertised by the wire payload into normalized
    // `stewards` rows so UI/read paths no longer depend on Share.stewards.
    // Prefer embedded UUID `id` when present; otherwise derive a deterministic
    // `wire_<vaultId>_<slot>_<pubkey>` row id so peers are not silently skipped.
    final embeddedStewards = share.stewards;
    if (embeddedStewards != null && embeddedStewards.isNotEmpty) {
      for (var i = 0; i < embeddedStewards.length; i++) {
        final steward = embeddedStewards[i];
        final pubkey = steward['pubkey'];
        final name = steward['name'];
        if (pubkey == null || pubkey.isEmpty || name == null || name.isEmpty) {
          continue;
        }
        final slotZeroBased = _shardSlotZeroBasedFromEmbedded(
          steward: steward,
          filteredEnumerationIndex: i,
          share: share,
          recipientPubkeyHex: currentPubkey,
        );
        final stewardRowId = _resolvedEmbeddedStewardRowId(
          vaultId: vaultId,
          steward: steward,
          slotZeroBased: slotZeroBased,
        );
        await repository.upsertStewardRow(
          id: stewardRowId,
          vaultId: vaultId,
          shareIndex: slotZeroBased + 1, // 1-based in DB
          pubkey: pubkey,
          name: name,
          contactInfo: steward['contactInfo'],
          isOwner: pubkey == share.creatorPubkey,
        );
      }
    }

    // Ensure the recipient's own steward row exists.
    var selfShareIndex = share.shareIndex + 1; // 1-based in DB
    String? selfName;
    String? selfResolvedId;
    if (currentPubkey != null && currentPubkey.isNotEmpty && embeddedStewards != null) {
      for (var i = 0; i < embeddedStewards.length; i++) {
        final row = embeddedStewards[i];
        if ((row['pubkey'] ?? '') == currentPubkey) {
          final slotZeroBased = _shardSlotZeroBasedFromEmbedded(
            steward: row,
            filteredEnumerationIndex: i,
            share: share,
            recipientPubkeyHex: currentPubkey,
          );
          selfShareIndex = slotZeroBased + 1;
          selfName = row['name'];
          selfResolvedId = _resolvedEmbeddedStewardRowId(
            vaultId: vaultId,
            steward: row,
            slotZeroBased: slotZeroBased,
          );
          break;
        }
      }
    }

    if (!share.isManifest && currentPubkey != null && currentPubkey.isNotEmpty) {
      final fallbackSlot = share.shareIndex;
      final idForSelf = selfResolvedId ??
          _resolvedEmbeddedStewardRowId(
            vaultId: vaultId,
            steward: {'pubkey': currentPubkey},
            slotZeroBased: fallbackSlot,
          );
      await repository.upsertStewardRow(
        id: idForSelf,
        vaultId: vaultId,
        shareIndex: selfShareIndex,
        pubkey: currentPubkey,
        name: selfName ?? 'Unknown',
        isOwner: currentPubkey == share.creatorPubkey,
      );
      Log.debug(
        '_upsertStewardVaultAndSelf: upserted self-steward for vault $vaultId '
        'shareIndex=$selfShareIndex',
      );
    }

    // Persist Shamir params from the wire share onto `vaults`. Without this,
    // steward bootstrap rows stay at threshold/total_shares = 0 (no
    // BackupConfig), and hydrated Vault.shares fail Share.isValid.
    await repository.mergeVaultRowFromIncomingShare(vaultId, share);
    await _inferOwnerSelfStewardAckIfEmbeddedListsOwner(vaultId, share);
  }

  /// When the wire payload lists the vault owner as an embedded steward,
  /// treat them as acknowledged for [Share.distributionVersion] without a
  /// separate ack event id ([acknowledgmentEventId] stays null). Uses a
  /// synthetic non-empty `giftWrapEventId` so `distribution_shares` rows (NOT
  /// NULL `gift_wrap_event_id`) can be written for the owner.
  ///
  /// Skips when [mergeVaultRowFromIncomingShare] left the vault on a newer
  /// distribution version than this share (stale ingest).
  Future<void> _inferOwnerSelfStewardAckIfEmbeddedListsOwner(
    String vaultId,
    Share share,
  ) async {
    const syntheticPrefix = 'owner-self-steward-inferred';
    final ownerPk = share.creatorPubkey;
    final embedded = share.stewards;
    if (embedded == null || embedded.isEmpty) return;

    final ownerListed = embedded.any((m) => (m['pubkey'] ?? '') == ownerPk);
    if (!ownerListed) return;

    final shareDist = share.distributionVersion ?? 0;
    final vault = await repository.getVault(vaultId);
    final vaultDist = vault?.backupConfig?.distributionVersion;
    if (vault == null || vaultDist == null) return;
    if (shareDist != vaultDist) return;

    final syntheticGiftWrapId = '$syntheticPrefix:$vaultId:v$shareDist';

    try {
      await repository.updateStewardStatus(
        vaultId: vaultId,
        pubkey: ownerPk,
        acknowledgedAt: DateTime.now(),
        acknowledgmentEventId: null,
        acknowledgedDistributionVersion: shareDist,
        giftWrapEventId: syntheticGiftWrapId,
      );
    } catch (e, st) {
      Log.warning(
        '_inferOwnerSelfStewardAckIfEmbeddedListsOwner failed for vault $vaultId',
        e,
        st,
      );
    }
  }

  /// Helper: extract first value of a named tag from event tags.
  String? _extractTagValue(List<List<String>> tags, String name) {
    for (final tag in tags) {
      if (tag.isNotEmpty && tag[0] == name && tag.length >= 2) return tag[1];
    }
    return null;
  }
}
