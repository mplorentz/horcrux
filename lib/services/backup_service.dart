import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntcdcrypto/ntcdcrypto.dart';
import '../models/backup_config.dart';
import '../models/steward.dart';
import '../models/shard_data.dart';
import '../models/backup_status.dart';
import '../models/steward_status.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import 'login_service.dart';
import 'shard_distribution_service.dart';
import 'relay_scan_service.dart';
import '../services/logger.dart';

/// Provider for BackupService
final Provider<BackupService> backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.read(vaultRepositoryProvider),
    ref.read(shardDistributionServiceProvider),
    ref.read(loginServiceProvider),
    ref.read(relayScanServiceProvider),
  );
});

/// Service for managing distributed backup using Shamir's Secret Sharing
class BackupService {
  final VaultRepository _repository;
  final ShardDistributionService _shardDistributionService;
  final LoginService _loginService;
  final RelayScanService _relayScanService;

  BackupService(
    this._repository,
    this._shardDistributionService,
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
    String? contentHash,
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
      contentHash: contentHash,
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
  Future<List<ShardData>> generateShamirShares({
    required String content,
    required int threshold,
    required int totalShards,
    required String creatorPubkey,
    required String vaultId,
    required String vaultName,
    required List<Map<String, String>> peers,
    String? ownerName,
    String? instructions,
  }) async {
    try {
      // Validate inputs
      if (threshold < VaultBackupConstraints.minThreshold) {
        throw ArgumentError('Threshold must be at least ${VaultBackupConstraints.minThreshold}');
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
      Log.debug('Share Strings: $shareStrings');

      // The prime modulus is fixed in ntcdcrypto, convert to base64url for storage
      // This matches the format expected by skb.py
      final primeModHex = sss.prime.toRadixString(16);
      final primeMod = base64Url.encode(utf8.encode(primeModHex));

      // Convert to ShardData objects
      final shardDataList = <ShardData>[];
      for (int i = 0; i < totalShards; i++) {
        final shardData = createShardData(
          shard: shareStrings[i],
          threshold: threshold,
          shardIndex: i,
          totalShards: totalShards,
          primeMod: primeMod,
          creatorPubkey: creatorPubkey,
          vaultId: vaultId,
          vaultName: vaultName,
          peers: peers,
          ownerName: ownerName,
          instructions: instructions,
        );
        Log.debug(shardData.toString());
        shardDataList.add(shardData);
      }

      Log.info('Generated $totalShards Shamir shares with threshold $threshold');
      return shardDataList;
    } catch (e) {
      Log.error('Error generating Shamir shares', e);
      throw Exception('Failed to generate Shamir shares: $e');
    }
  }

  /// Reconstruct content from Shamir shares
  Future<String> reconstructFromShares({required List<ShardData> shares}) async {
    try {
      if (shares.isEmpty) {
        throw ArgumentError('At least one share is required');
      }

      // Validate that all shares have the same threshold and totalShards
      final threshold = shares.first.threshold;
      final totalShards = shares.first.totalShards;
      final primeMod = shares.first.primeMod;
      final creatorPubkey = shares.first.creatorPubkey;

      for (final share in shares) {
        if (share.threshold != threshold ||
            share.totalShards != totalShards ||
            share.primeMod != primeMod ||
            share.creatorPubkey != creatorPubkey) {
          throw ArgumentError('All shares must have the same parameters');
        }
      }

      if (shares.length < threshold) {
        throw ArgumentError('At least $threshold shares are required, got ${shares.length}');
      }

      // Create SSS instance
      final sss = SSS();

      // Verify that the prime modulus matches the one ntcdcrypto uses
      final expectedPrimeModHex = sss.prime.toRadixString(16);
      final expectedPrimeMod = base64Url.encode(utf8.encode(expectedPrimeModHex));

      if (primeMod != expectedPrimeMod) {
        throw ArgumentError(
          'Invalid prime modulus: shares were created with a different prime than ntcdcrypto uses',
        );
      }

      // Extract the share strings from ShardData objects
      final shareStrings = shares.map((s) => s.shard).toList();

      // Combine shares using Base64Url encoding (isBase64 = true)
      // This will reconstruct the original secret
      final content = sss.combine(shareStrings, true);

      Log.info('Successfully reconstructed content from ${shares.length} shares');
      return content;
    } on ArgumentError catch (e) {
      Log.error('Error reconstructing from shares', e);
      rethrow;
    } catch (e) {
      Log.error('Error reconstructing from shares', e);
      throw Exception('Failed to reconstruct content from shares: $e');
    }
  }

  /// Update backup status
  Future<void> updateBackupStatus(String vaultId, BackupStatus status) async {
    final config = await _repository.getBackupConfig(vaultId);
    if (config == null) {
      throw ArgumentError('Backup configuration not found for vault $vaultId');
    }

    final updatedConfig = copyBackupConfig(config, status: status, lastUpdated: DateTime.now());
    await _repository.updateBackupConfig(vaultId, updatedConfig);

    Log.info('Updated backup status for vault $vaultId to $status');
  }

  /// Update steward status
  Future<void> updateStewardStatus({
    required String vaultId,
    required String pubkey, // Hex format
    required StewardStatus status,
    DateTime? acknowledgedAt,
    String? acknowledgmentEventId,
  }) async {
    final config = await _repository.getBackupConfig(vaultId);
    if (config == null) {
      throw ArgumentError('Backup configuration not found for vault $vaultId');
    }

    // Find and update the steward
    final updatedStewards = config.stewards.map((steward) {
      if (steward.pubkey != null && steward.pubkey == pubkey) {
        return copySteward(
          steward,
          status: status,
          acknowledgedAt: acknowledgedAt,
          acknowledgmentEventId: acknowledgmentEventId,
        );
      }
      return steward;
    }).toList();

    final updatedConfig = copyBackupConfig(
      config,
      stewards: updatedStewards,
      lastUpdated: DateTime.now(),
    );

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
      throw ArgumentError('No existing backup configuration found for vault $vaultId');
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
      // If steward list changed, it requires redistribution
      if (mergedStewards.length != existingConfig.stewards.length) {
        configParamsChanged = true;
      }
    } else {
      mergedStewards = existingConfig.stewards;
    }

    // Calculate new total keys based on merged stewards
    final newTotalKeys = mergedStewards.length;

    // Increment distribution version if config changed
    final newDistributionVersion = configParamsChanged
        ? existingConfig.distributionVersion + 1
        : existingConfig.distributionVersion;

    // If distribution version incremented, reset all stewards with pubkeys to awaitingNewKey
    // (preserve invited stewards without pubkeys)
    final finalStewards = newDistributionVersion > existingConfig.distributionVersion
        ? mergedStewards.map((steward) {
            // Reset to awaitingNewKey if they have a pubkey and were holding a key
            // Keep as awaitingKey if they were already awaiting (never received a key)
            if (steward.pubkey != null && steward.status != StewardStatus.invited) {
              final newStatus = steward.status == StewardStatus.holdingKey
                  ? StewardStatus.awaitingNewKey
                  : StewardStatus.awaitingKey;
              return copySteward(
                steward,
                status: newStatus,
                acknowledgedAt: null,
                acknowledgmentEventId: null,
                acknowledgedDistributionVersion: null,
                keyShare: null,
                giftWrapEventId: null,
              );
            }
            return steward;
          }).toList()
        : mergedStewards;

    // Create merged config
    final mergedConfig = copyBackupConfig(
      existingConfig,
      threshold: newThreshold,
      totalKeys: newTotalKeys,
      stewards: finalStewards,
      relays: newRelays,
      instructions: newInstructions,
      lastUpdated: DateTime.now(),
      distributionVersion: newDistributionVersion,
      // Preserve lastRedistribution - only updated when distribution succeeds
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

    Log.info('Merged backup configuration for vault $vaultId (version: $newDistributionVersion)');
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

    // Increment distribution version
    final newDistributionVersion = config.distributionVersion + 1;

    // Reset all stewards with pubkeys to awaitingNewKey (if they were holding) or awaitingKey
    final updatedStewards = config.stewards.map((steward) {
      // Reset to awaitingNewKey if they have a pubkey and were holding a key
      // Keep as awaitingKey if they were already awaiting (never received a key)
      if (steward.pubkey != null && steward.status != StewardStatus.invited) {
        final newStatus = steward.status == StewardStatus.holdingKey
            ? StewardStatus.awaitingNewKey
            : StewardStatus.awaitingKey;
        return copySteward(
          steward,
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

    // Update config with new version and reset stewards
    final updatedConfig = copyBackupConfig(
      config,
      stewards: updatedStewards,
      distributionVersion: newDistributionVersion,
      lastUpdated: DateTime.now(),
      lastContentChange: DateTime.now(),
    );

    await _repository.updateBackupConfig(vaultId, updatedConfig);
    Log.info(
      'Incremented distributionVersion to $newDistributionVersion for vault $vaultId due to content change',
    );
  }

  /// Helper to merge steward lists
  List<Steward> _mergeStewards(List<Steward> existing, List<Steward> updated) {
    final merged = <Steward>[];

    // Add all updated stewards, preserving acknowledgments from existing
    for (final updatedSteward in updated) {
      // Find matching steward in existing list by id
      final existingSteward = existing.where((h) => h.id == updatedSteward.id).firstOrNull;

      if (existingSteward != null) {
        // Preserve important fields from existing (status, acknowledgments, etc)
        merged.add(
          copySteward(
            updatedSteward,
            status: existingSteward.status,
            acknowledgedAt: existingSteward.acknowledgedAt,
            acknowledgmentEventId: existingSteward.acknowledgmentEventId,
            acknowledgedDistributionVersion: existingSteward.acknowledgedDistributionVersion,
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
  Future<BackupConfig> createAndDistributeBackup({required String vaultId}) async {
    try {
      // Step 1: Load vault content
      final vault = await _repository.getVault(vaultId);
      if (vault == null) {
        throw Exception('Vault not found: $vaultId');
      }
      final content = vault.content;
      if (content == null) {
        throw Exception('Cannot backup encrypted vault - content is not available');
      }
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

      // Step 3: Get creator's Nostr key pair
      final creatorKeyPair = await _loginService.getStoredNostrKey();
      final creatorPubkey = creatorKeyPair?.publicKey;
      final creatorPrivkey = creatorKeyPair?.privateKey;
      if (creatorPubkey == null || creatorPrivkey == null) {
        throw Exception('No Nostr key available for backup creation');
      }
      Log.info('Retrieved creator key pair');

      // Step 4: Validate all stewards are ready for distribution
      if (!config.canDistribute) {
        final names = config.stewards
            .where((kh) => kh.pubkey == null)
            .map((kh) => kh.name ?? kh.id)
            .join(', ');
        throw StateError(
          'Cannot distribute: ${config.pendingInvitationsCount} steward(s) '
          'haven\'t accepted invitations yet: $names',
        );
      }

      // Step 5: Generate Shamir shares
      // Note: peers list excludes the creator - recipients need to know OTHER stewards
      // Build peers list with name and pubkey maps
      final peers = config.stewards
          .where((kh) => kh.pubkey != null && kh.pubkey != creatorPubkey)
          .map((kh) => {'name': kh.name ?? 'Unknown', 'pubkey': kh.pubkey!})
          .toList();
      final shards = await generateShamirShares(
        content: content,
        threshold: config.threshold,
        totalShards: config.totalKeys,
        creatorPubkey: creatorPubkey,
        vaultId: vault.id,
        vaultName: vault.name,
        peers: peers,
        ownerName: vault.ownerName,
        instructions: config.instructions,
      );
      Log.info('Generated ${shards.length} Shamir shares');

      // Step 6: Distribute shards using injected service
      await _shardDistributionService.distributeShards(
        ownerPubkey: creatorPubkey,
        config: config,
        shards: shards,
      );
      Log.info('Successfully distributed all shards');

      // Step 7: Update backup config with distribution timestamp and status
      final now = DateTime.now();
      final updatedConfig = copyBackupConfig(
        config,
        lastRedistribution: now,
        lastUpdated: now,
        status: BackupStatus.active,
      );
      await _repository.updateBackupConfig(vaultId, updatedConfig);
      Log.info('Updated backup config with redistribution timestamp');

      return updatedConfig;
    } catch (e) {
      Log.error('Failed to create and distribute backup', e);
      rethrow;
    }
  }
}
