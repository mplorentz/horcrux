import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntcdcrypto/ntcdcrypto.dart';
import '../models/backup_config.dart';
import '../models/steward.dart';
import '../models/share.dart';
import '../models/backup_status.dart';
import '../models/steward_status.dart';
import '../models/vault.dart';
import '../models/vault_detail.dart';
import '../providers/vault_provider.dart';
import '../providers/vault_detail_repository.dart';
import '../providers/key_provider.dart';
import 'login_service.dart';
import 'share_distribution_service.dart';
import 'relay_scan_service.dart';
import '../services/logger.dart';

/// Provider for BackupService.
///
/// Watches the repositories and downstream services so that an
/// [appDatabaseProvider] invalidation rebuilds BackupService against the
/// fresh repositories instead of holding the previous (closed) database.
final Provider<BackupService> backupServiceProvider = Provider<BackupService>((
  ref,
) {
  return BackupService(
    ref.watch(vaultRepositoryProvider),
    ref.watch(vaultDetailRepositoryProvider),
    ref.watch(shareDistributionServiceProvider),
    ref.watch(loginServiceProvider),
    ref.watch(relayScanServiceProvider),
  );
});

/// Reset stewards so a new shard distribution can replace keys / shard metadata.
///
/// Invited rows (no pubkey) are unchanged. Everyone else with a pubkey moves to
/// [StewardStatus.awaitingNewKey] or [StewardStatus.awaitingKey] and drops ack state.
List<Steward> _stewardsResetForRedistribution(List<Steward> stewards) {
  return stewards.map((steward) {
    if (steward.pubkey != null && steward.status != StewardStatus.invited) {
      final newStatus = steward.status == StewardStatus.holdingKey
          ? StewardStatus.awaitingNewKey
          : StewardStatus.awaitingKey;
      return steward.copyWith(
        status: newStatus,
        acknowledgedAt: null,
        acknowledgmentEventId: null,
        acknowledgedDistributionVersion: null,
        keyShare: null,
        giftWrapEventId: null,
      );
    }
    return steward;
  }).toList();
}

/// [config] with [BackupConfig.distributionVersion] incremented and stewards
/// reset. Phase 1 stops tracking `lastContentChange` / `lastUpdated` —
/// callers that need "content has changed since last distribution" should
/// drive that off [BackupConfig.distributionVersion] and the steward statuses
/// reset by this call.
BackupConfig _backupConfigWithBumpedDistribution(BackupConfig config) {
  return config.copyWith(
    stewards: _stewardsResetForRedistribution(config.stewards),
    distributionVersion: config.distributionVersion + 1,
  );
}

/// Service for managing distributed backup using Shamir's Secret Sharing
class BackupService {
  final VaultRepository _repository;
  final VaultDetailRepository _vaultDetailRepository;
  final ShareDistributionService _shareDistributionService;
  final LoginService _loginService;
  final RelayScanService _relayScanService;

  BackupService(
    this._repository,
    this._vaultDetailRepository,
    this._shareDistributionService,
    this._loginService,
    this._relayScanService,
  );

  /// Create a new backup configuration
  Future<BackupConfig> createBackupConfiguration({
    required String vaultId,
    required int threshold,
    required int totalKeys,
    required List<Steward> stewards,
    required List<String> relays,
    String? instructions,
  }) async {
    // Validate inputs
    if (threshold < VaultBackupConstraints.minThreshold || threshold > totalKeys) {
      throw ArgumentError(
        'Threshold must be >= ${VaultBackupConstraints.minThreshold} and <= totalKeys',
      );
    }
    if (totalKeys < threshold || totalKeys > VaultBackupConstraints.maxTotalKeys) {
      throw ArgumentError(
        'TotalKeys must be >= threshold and <= ${VaultBackupConstraints.maxTotalKeys}',
      );
    }
    if (stewards.length != totalKeys) {
      throw ArgumentError('Stewards length must equal totalKeys');
    }
    if (relays.isEmpty) {
      throw ArgumentError('At least one relay must be provided');
    }

    // Create backup configuration
    final config = createBackupConfig(
      vaultId: vaultId,
      threshold: threshold,
      totalKeys: totalKeys,
      stewards: stewards,
      relays: relays,
      instructions: instructions,
    );

    // Store the configuration in the vault via repository
    await _repository.updateBackupConfig(vaultId, config);

    Log.info('Created backup configuration for vault $vaultId');
    return config;
  }

  /// Get backup configuration for a vault
  Future<BackupConfig?> getBackupConfig(String vaultId) async {
    return await _repository.getBackupConfig(vaultId);
  }

  /// Get all backup configurations
  Future<List<BackupConfig>> getAllBackupConfigs() async {
    final vaults = await _repository.getAllVaults();
    return vaults
        .where((vault) => vault.backupConfig != null)
        .map((vault) => vault.backupConfig!)
        .toList();
  }

  /// Update backup configuration
  Future<void> updateBackupConfig(BackupConfig config) async {
    await _repository.updateBackupConfig(config.vaultId, config);
    Log.info('Updated backup configuration for vault ${config.vaultId}');
  }

  /// Delete backup configuration
  Future<void> deleteBackupConfig(String vaultId) async {
    // Set backup config to null in the vault
    final vault = await _repository.getVault(vaultId);
    if (vault != null) {
      await _repository.saveVault(vault.copyWith(backupConfig: null));
    }
    Log.info('Deleted backup configuration for vault $vaultId');
  }

  /// Generate Shamir shares for vault content
  Future<List<Share>> generateShamirShares({
    required String content,
    required int threshold,
    required int totalShards,
    required String creatorPubkey,
    required String vaultId,
    required String vaultName,
    required List<Map<String, String>> stewards,
    String? ownerName,
    String? instructions,
    bool? pushEnabled,
  }) async {
    try {
      // Validate inputs
      if (threshold < VaultBackupConstraints.minThreshold) {
        throw ArgumentError(
          'Threshold must be at least ${VaultBackupConstraints.minThreshold}',
        );
      }
      if (threshold > totalShards) {
        throw ArgumentError('Threshold cannot exceed total shards');
      }
      if (content.isEmpty) {
        throw ArgumentError('Content cannot be empty');
      }

      // Create SSS instance
      final sss = SSS();

      // Generate shares using Base64Url encoding (isBase64 = true)
      // The ntcdcrypto library returns shares as Base64Url-encoded strings
      final shareStrings = sss.create(threshold, totalShards, content, true);

      // The prime modulus is fixed in ntcdcrypto, convert to base64url for storage
      // This matches the format expected by skb.py
      final primeModHex = sss.prime.toRadixString(16);
      final primeMod = base64Url.encode(utf8.encode(primeModHex));

      // Convert to Share objects
      final shardDataList = <Share>[];
      for (int i = 0; i < totalShards; i++) {
        final shardData = createShare(
          payload: shareStrings[i],
          threshold: threshold,
          shareIndex: i,
          totalShares: totalShards,
          primeMod: primeMod,
          creatorPubkey: creatorPubkey,
          vaultId: vaultId,
          vaultName: vaultName,
          stewards: stewards,
          ownerName: ownerName,
          instructions: instructions,
          pushEnabled: pushEnabled,
        );
        Log.debug(shardData.toString());
        shardDataList.add(shardData);
      }

      Log.info(
        'Generated $totalShards Shamir shares with threshold $threshold',
      );
      return shardDataList;
    } catch (e) {
      Log.error('Error generating Shamir shares', e);
      throw Exception('Failed to generate Shamir shares: $e');
    }
  }

  /// Reconstruct content from Shamir shares
  Future<String> reconstructFromShares({
    required List<Share> shares,
  }) async {
    try {
      if (shares.isEmpty) {
        throw ArgumentError('At least one share is required');
      }

      // Validate that all shares have the same threshold and totalShards
      final threshold = shares.first.threshold;
      final totalSharesCount = shares.first.totalShares;
      final primeMod = shares.first.primeMod;
      final creatorPubkey = shares.first.creatorPubkey;

      for (final share in shares) {
        if (share.threshold != threshold ||
            share.totalShares != totalSharesCount ||
            share.primeMod != primeMod ||
            share.creatorPubkey != creatorPubkey) {
          throw ArgumentError('All shares must have the same parameters');
        }
      }

      if (shares.length < threshold) {
        throw ArgumentError(
          'At least $threshold shares are required, got ${shares.length}',
        );
      }

      // Create SSS instance
      final sss = SSS();

      // Verify that the prime modulus matches the one ntcdcrypto uses
      final expectedPrimeModHex = sss.prime.toRadixString(16);
      final expectedPrimeMod = base64Url.encode(
        utf8.encode(expectedPrimeModHex),
      );

      if (primeMod != expectedPrimeMod) {
        throw ArgumentError(
          'Invalid prime modulus: shares were created with a different prime than ntcdcrypto uses',
        );
      }

      // Extract the share strings from Share objects
      final shareStrings = shares.map((s) => s.payload).toList();

      // Combine shares using Base64Url encoding (isBase64 = true)
      // This will reconstruct the original secret
      final content = sss.combine(shareStrings, true);

      Log.info(
        'Successfully reconstructed content from ${shares.length} shares',
      );
      return content;
    } on ArgumentError catch (e) {
      Log.error('Error reconstructing from shares', e);
      rethrow;
    } catch (e) {
      Log.error('Error reconstructing from shares', e);
      throw Exception('Failed to reconstruct content from shares: $e');
    }
  }

  /// Previously updated a persisted [BackupStatus] enum on the config.
  /// `status` is no longer stored — it is derived from steward statuses and
  /// distribution timestamps. Retained as a no-op to keep call sites compiling
  /// during the data-layer refactor; remove in a follow-up cleanup pass.
  Future<void> updateBackupStatus(String vaultId, BackupStatus status) async {
    Log.info(
      'updateBackupStatus($vaultId, $status) is a no-op: status is derived',
    );
  }

  /// Update steward status
  Future<void> updateStewardStatus({
    required String vaultId,
    required String pubkey, // Hex format
    required StewardStatus status,
    DateTime? acknowledgedAt,
    String? acknowledgmentEventId,
    String? giftWrapEventId,
  }) async {
    final config = await _repository.getBackupConfig(vaultId);
    if (config == null) {
      throw ArgumentError('Backup configuration not found for vault $vaultId');
    }

    // Find and update the steward
    final updatedStewards = config.stewards.map((steward) {
      if (steward.pubkey != null && steward.pubkey == pubkey) {
        return steward.copyWith(
          status: status,
          acknowledgedAt: acknowledgedAt,
          acknowledgmentEventId: acknowledgmentEventId,
          giftWrapEventId: giftWrapEventId ?? steward.giftWrapEventId,
          // Preserve contactInfo when updating steward status
        );
      }
      return steward;
    }).toList();

    final updatedConfig = config.copyWith(stewards: updatedStewards);

    await _repository.updateBackupConfig(vaultId, updatedConfig);

    Log.info('Updated steward $pubkey status to $status');
  }

  /// Check if backup is ready (all required stewards have acknowledged)
  Future<bool> isBackupReady(String vaultId) async {
    final config = await _repository.getBackupConfig(vaultId);
    if (config == null) return false;

    return config.acknowledgedStewardsCount >= config.threshold;
  }

  /// Merge backup configuration changes with existing config
  ///
  /// This method intelligently merges new configuration data with existing data:
  /// - Key holders: Adds new ones, updates existing ones, preserves status/acknowledgments
  /// - Threshold/relays/instructions: Updates if provided
  /// - Increments distributionVersion if config params changed
  /// - Preserves lastRedistribution timestamp
  Future<BackupConfig> mergeBackupConfig({
    required String vaultId,
    int? threshold,
    List<Steward>? stewards,
    List<String>? relays,
    String? instructions,
  }) async {
    // Load existing config
    final existingConfig = await _repository.getBackupConfig(vaultId);

    if (existingConfig == null) {
      throw ArgumentError(
        'No existing backup configuration found for vault $vaultId',
      );
    }

    // Track if config parameters changed (requires redistribution)
    bool configParamsChanged = false;

    // Merge threshold
    final newThreshold = threshold ?? existingConfig.threshold;
    if (newThreshold != existingConfig.threshold) {
      configParamsChanged = true;
    }

    // Merge relays
    final newRelays = relays ?? existingConfig.relays;
    if (relays != null && !_areRelaysEqual(relays, existingConfig.relays)) {
      configParamsChanged = true;
    }

    // Merge instructions
    final newInstructions = instructions ?? existingConfig.instructions;
    if (instructions != null && instructions != existingConfig.instructions) {
      configParamsChanged = true;
    }

    // Merge stewards (more complex)
    List<Steward> mergedStewards;
    if (stewards != null) {
      mergedStewards = _mergeStewards(existingConfig.stewards, stewards);
      // If steward list changed (additions/removals), it requires redistribution
      // Check by comparing steward IDs, not just length
      final existingIds = existingConfig.stewards.map((s) => s.id).toSet();
      final mergedIds = mergedStewards.map((s) => s.id).toSet();
      if (existingIds.length != mergedIds.length ||
          !existingIds.containsAll(mergedIds) ||
          !mergedIds.containsAll(existingIds)) {
        configParamsChanged = true;
      } else {
        // Check if steward properties changed (name or pubkey/contact info)
        // This requires redistribution because the shard metadata includes steward info
        for (final mergedSteward in mergedStewards) {
          final existingSteward =
              existingConfig.stewards.where((s) => s.id == mergedSteward.id).firstOrNull;
          if (existingSteward != null) {
            // Check if name, pubkey, or contactInfo changed
            // This requires redistribution because the shard metadata includes steward info
            if (existingSteward.name != mergedSteward.name ||
                existingSteward.pubkey != mergedSteward.pubkey ||
                existingSteward.contactInfo != mergedSteward.contactInfo) {
              configParamsChanged = true;
              break;
            }
          }
        }
      }
    } else {
      mergedStewards = existingConfig.stewards;
    }

    // Increment distribution version if config changed
    final newDistributionVersion = configParamsChanged
        ? existingConfig.distributionVersion + 1
        : existingConfig.distributionVersion;

    // If distribution version incremented, reset stewards for redistribution
    final finalStewards = newDistributionVersion > existingConfig.distributionVersion
        ? _stewardsResetForRedistribution(mergedStewards)
        : mergedStewards;

    // Create merged config
    final mergedConfig = existingConfig.copyWith(
      threshold: newThreshold,
      stewards: finalStewards,
      relays: newRelays,
      instructions: newInstructions,
      distributionVersion: newDistributionVersion,
    );

    // Save merged config
    await _repository.updateBackupConfig(vaultId, mergedConfig);

    // Sync relays to RelayScanService
    try {
      await _relayScanService.syncRelaysFromUrls(newRelays);
      await _relayScanService.ensureScanningStarted();
      Log.info('Synced ${newRelays.length} relay(s) to RelayScanService');
    } catch (e) {
      Log.error('Error syncing relays to RelayScanService', e);
    }

    Log.info(
      'Merged backup configuration for vault $vaultId (version: $newDistributionVersion)',
    );
    return mergedConfig;
  }

  /// Handle vault content change by incrementing distributionVersion
  ///
  /// When vault contents change, we need to increment the distribution version
  /// and reset all stewards with pubkeys to awaitingKey status.
  /// This ensures that new shards will be distributed on the next distribution.
  Future<void> handleContentChange(String vaultId) async {
    final config = await _repository.getBackupConfig(vaultId);
    if (config == null) {
      // No backup config exists, nothing to do
      return;
    }

    final updatedConfig = _backupConfigWithBumpedDistribution(config);

    await _repository.updateBackupConfig(vaultId, updatedConfig);
    Log.info(
      'Incremented distributionVersion to ${updatedConfig.distributionVersion} '
      'for vault $vaultId due to content change',
    );
  }

  /// Bumps [BackupConfig.distributionVersion], resets steward ack state so
  /// previously holding-key stewards move to [StewardStatus.awaitingNewKey],
  /// then runs [createAndDistributeBackup] with the new version.
  ///
  /// Used by the owner-initiated "Redistribute Keys" action and by paths that
  /// must force a fresh distribution (e.g. push-preference change).
  ///
  /// No-ops when there is no config or [BackupConfig.canDistribute] is false.
  Future<void> redistributeKeys({required String vaultId}) async {
    final config = await _repository.getBackupConfig(vaultId);
    if (config == null) {
      Log.info('BackupService: skip redistribution (no backup config)');
      return;
    }
    if (!config.canDistribute) {
      Log.info(
        'BackupService: skip redistribution (not all stewards have pubkeys yet)',
      );
      return;
    }

    final updatedConfig = _backupConfigWithBumpedDistribution(config);

    await _repository.updateBackupConfig(vaultId, updatedConfig);
    Log.info(
      'BackupService: incremented distributionVersion to ${updatedConfig.distributionVersion} '
      'for vault $vaultId (redistribute)',
    );

    await createAndDistributeBackup(vaultId: vaultId);
  }

  /// Owner changed [Vault.pushEnabled] without other backup-config edits.
  ///
  /// Stewards learn `push_enabled` from shard payloads; without a new
  /// distribution they would keep a stale value and could still trigger
  /// recovery pushes.
  Future<void> redistributeForPushPreferenceChange({
    required String vaultId,
  }) =>
      redistributeKeys(vaultId: vaultId);

  /// Check if keys should be auto-distributed and distribute if necessary
  ///
  /// This handles the case where all stewards have accepted invitations and are
  /// ready for key distribution. Checks if:
  /// - Backup config exists and can distribute (all stewards have pubkeys)
  /// - Vault exists and has content
  /// - All stewards with pubkeys are awaitingKey or awaitingNewKey (ready for distribution)
  ///
  /// If all conditions are met, automatically distributes keys.
  /// Errors are logged but not thrown to avoid disrupting the calling flow.
  Future<void> distributeKeysIfNecessary(String vaultId) async {
    try {
      final backupConfig = await _repository.getBackupConfig(vaultId);
      final vaultDetail = await _vaultDetailRepository.getVaultDetail(vaultId);

      if (backupConfig != null && vaultDetail is OwnedVaultDetail) {
        // Check if all stewards now have pubkeys (can distribute)
        if (backupConfig.canDistribute) {
          // Check if all stewards with pubkeys are awaitingKey or awaitingNewKey (ready for distribution)
          // awaitingNewKey means they have an old shard but need an updated one (e.g., after a new steward joins)
          final stewardsWithPubkeys = backupConfig.stewards.where((s) => s.pubkey != null).toList();
          final allReadyForDistribution = stewardsWithPubkeys.isNotEmpty &&
              stewardsWithPubkeys.every(
                (s) =>
                    s.status == StewardStatus.awaitingKey ||
                    s.status == StewardStatus.awaitingNewKey,
              );

          if (allReadyForDistribution) {
            Log.info(
              'All stewards are ready for distribution (awaitingKey or awaitingNewKey) - triggering auto-distribution for vault $vaultId',
            );
            try {
              await createAndDistributeBackup(vaultId: vaultId);
              Log.info('Auto-distributed keys after steward acceptance');
            } catch (e) {
              Log.error(
                'Failed to auto-distribute keys after steward acceptance',
                e,
              );
              // Don't fail if auto-distribution fails
            }
          }
        }
      }
    } catch (e) {
      Log.warning('Error checking for auto-distribution: $e');
      // Don't fail if auto-distribution check fails
    }
  }

  /// Helper to merge steward lists
  List<Steward> _mergeStewards(List<Steward> existing, List<Steward> updated) {
    final merged = <Steward>[];

    // Add all updated stewards, preserving acknowledgments from existing
    for (final updatedSteward in updated) {
      // Find matching steward in existing list by id
      final existingSteward = existing.where((h) => h.id == updatedSteward.id).firstOrNull;

      if (existingSteward != null) {
        // Preserve important fields from existing (status, acknowledgments, pubkey, etc)
        // Preserve pubkey from existing if it exists (should never be removed once set)
        // Preserve contactInfo from updated if provided, otherwise keep existing
        merged.add(
          updatedSteward.copyWith(
            status: existingSteward.status,
            pubkey: existingSteward.pubkey ?? updatedSteward.pubkey,
            acknowledgedAt: existingSteward.acknowledgedAt,
            acknowledgmentEventId: existingSteward.acknowledgmentEventId,
            acknowledgedDistributionVersion: existingSteward.acknowledgedDistributionVersion,
            contactInfo: updatedSteward.contactInfo ?? existingSteward.contactInfo,
          ),
        );
      } else {
        // New steward
        merged.add(updatedSteward);
      }
    }

    return merged;
  }

  /// Helper to compare relay lists
  bool _areRelaysEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    final set1 = Set<String>.from(list1);
    final set2 = Set<String>.from(list2);
    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  /// Create or update backup configuration without distributing shares
  ///
  /// This allows saving the backup configuration before all stewards
  /// have accepted their invitations. Shares can be distributed later
  /// using createAndDistributeBackup or a separate distribution method.
  Future<BackupConfig> saveBackupConfig({
    required String vaultId,
    required int threshold,
    required int totalKeys,
    required List<Steward> stewards,
    required List<String> relays,
    String? instructions,
  }) async {
    // Delete existing config if present (allows overwrite)
    final existingConfig = await _repository.getBackupConfig(vaultId);
    if (existingConfig != null) {
      await deleteBackupConfig(vaultId);
      Log.info('Deleted existing backup configuration for overwrite');
    }

    // Create backup configuration
    final config = await createBackupConfiguration(
      vaultId: vaultId,
      threshold: threshold,
      totalKeys: totalKeys,
      stewards: stewards,
      relays: relays,
      instructions: instructions,
    );

    // Sync relays to RelayScanService and ensure scanning is started
    try {
      await _relayScanService.syncRelaysFromUrls(relays);
      await _relayScanService.ensureScanningStarted();
      Log.info('Synced ${relays.length} relay(s) to RelayScanService');
    } catch (e) {
      Log.error('Error syncing relays to RelayScanService', e);
      // Don't fail backup config save if relay sync fails
    }

    Log.info('Created backup configuration for vault $vaultId');
    return config;
  }

  /// High-level method to create and distribute a backup
  ///
  /// This orchestrates the entire backup creation flow:
  /// 1. Loads vault and backup configuration
  /// 2. Generates Shamir shares
  /// 3. Distributes shares to stewards via Nostr
  ///
  /// Throws exception if any step fails
  Future<BackupConfig> createAndDistributeBackup({
    required String vaultId,
  }) async {
    try {
      // Step 1: Load vault content (requires owned vault).
      final vaultDetail = await _vaultDetailRepository.getVaultDetail(vaultId);
      if (vaultDetail == null) {
        throw Exception('Vault not found: $vaultId');
      }
      if (vaultDetail is! OwnedVaultDetail) {
        throw Exception('Cannot backup vault — this device is not the owner');
      }
      final content = vaultDetail.content;
      Log.info('Loaded vault content for backup: $vaultId');

      // Step 2: Load backup configuration
      final config = await _repository.getBackupConfig(vaultId);
      if (config == null) {
        throw Exception('Backup configuration not found for vault: $vaultId');
      }
      if (config.stewards.isEmpty) {
        throw Exception('No stewards configured in backup configuration');
      }
      Log.info('Loaded backup configuration');
      var configToDistribute = config;
      if (!config.hasBeenDistributed) {
        configToDistribute = _backupConfigWithBumpedDistribution(config);
        await _repository.updateBackupConfig(vaultId, configToDistribute);
        Log.info(
          'Initialized first distribution version to ${configToDistribute.distributionVersion} for vault $vaultId',
        );
      }

      // Step 3: Get creator's Nostr key pair
      final creatorKeyPair = await _loginService.getStoredNostrKey();
      final creatorPubkey = creatorKeyPair?.publicKey;
      final creatorPrivkey = creatorKeyPair?.privateKey;
      if (creatorPubkey == null || creatorPrivkey == null) {
        throw Exception('No Nostr key available for backup creation');
      }
      Log.info('Retrieved creator key pair');

      // Step 4: Validate all stewards are ready for distribution
      if (!configToDistribute.canDistribute) {
        final names = configToDistribute.stewards
            .where((kh) => kh.pubkey == null)
            .map((kh) => kh.name ?? kh.id)
            .join(', ');
        throw StateError(
          'Cannot distribute: ${configToDistribute.pendingInvitationsCount} steward(s) '
          'haven\'t accepted invitations yet: $names',
        );
      }

      // Step 5: Generate Shamir shares
      // Build stewards list with id, name, pubkey, and contactInfo maps.
      // Including the steward id lets the receiving device use the owner's
      // authoritative steward UUID instead of a synthetic positional one,
      // which avoids UNIQUE-constraint collisions on the stewards table.
      // Including shard_index (0-based Shamir slot in BackupConfig.steward order)
      // ensures steward-side upserts match distributeShares indexing even when
      // invitees without pubkeys are omitted from this list.
      final stewards = <Map<String, String>>[];
      for (var idx = 0; idx < configToDistribute.stewards.length; idx++) {
        final kh = configToDistribute.stewards[idx];
        if (kh.pubkey == null) continue;
        final stewardMap = <String, String>{
          'id': kh.id,
          'name': kh.name ?? 'Unknown',
          'pubkey': kh.pubkey!,
          'shard_index': '$idx',
        };
        if (kh.contactInfo != null && kh.contactInfo!.isNotEmpty) {
          stewardMap['contactInfo'] = kh.contactInfo!;
        }
        stewards.add(stewardMap);
      }

      final shards = await generateShamirShares(
        content: content,
        threshold: configToDistribute.threshold,
        totalShards: configToDistribute.totalKeys,
        creatorPubkey: creatorPubkey,
        vaultId: vaultDetail.id,
        vaultName: vaultDetail.name,
        stewards: stewards,
        ownerName: vaultDetail.ownerName,
        instructions: configToDistribute.instructions,
        // Advertise the owner's current push preference so stewards learn
        // (or re-learn, on redistribution) whether this vault uses push.
        pushEnabled: vaultDetail.pushEnabled,
      );
      Log.info('Generated ${shards.length} Shamir shares');

      // Step 6: Distribute shards using injected service
      await _shareDistributionService.distributeShares(
        ownerPubkey: creatorPubkey,
        config: configToDistribute,
        shares: shards,
      );
      Log.info('Successfully distributed all shards');

      // Step 7: Update backup config with distribution timestamp and status
      // IMPORTANT: Reload config to preserve any steward status updates that happened during distribution
      // (e.g., owner's immediate acknowledgment)
      final currentConfig = await _repository.getBackupConfig(vaultId);
      if (currentConfig == null) {
        throw Exception('Backup configuration not found after distribution');
      }
      // Phase 1: distribution success is no longer materialized into a
      // dedicated `lastRedistribution` / `status` column on `BackupConfig`.
      // The successful publish surface comes from steward acks (which raise
      // each steward's status to `holdingKey`) and the bumped
      // `distributionVersion`. Persist the current config so the latest
      // steward state from step 6 is durable.
      await _repository.updateBackupConfig(vaultId, currentConfig);
      Log.info('Updated backup config after redistribution');

      return currentConfig;
    } catch (e) {
      Log.error('Failed to create and distribute backup', e);
      rethrow;
    }
  }
}
