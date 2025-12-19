import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault.dart';
import '../models/shard_data.dart';
import '../models/recovery_request.dart';
import '../models/backup_config.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../services/login_service.dart';
import '../services/logger.dart';
import 'key_provider.dart';

/// Stream provider that automatically subscribes to vault changes
/// This will emit a new list whenever vaults are added, updated, or deleted
final vaultListProvider = StreamProvider.autoDispose<List<Vault>>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);

  // Return the stream directly and let Riverpod handle the subscription
  return Stream.multi((controller) async {
    // First, load and emit initial data
    try {
      final initialVaults = await repository.getAllVaults();
      controller.add(initialVaults);
    } catch (e) {
      Log.error('Error loading initial vaults', e);
      controller.addError(e);
    }

    // Then listen to the repository stream for updates
    final subscription = repository.vaultsStream.listen(
      (vaults) {
        controller.add(vaults);
      },
      onError: (error) {
        Log.error('Error in vaultsStream', error);
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
    );

    // Clean up when the provider is disposed
    controller.onCancel = () {
      subscription.cancel();
    };
  });
});

/// Provider for a specific vault by ID
/// This will automatically update when the vault changes
final vaultProvider = StreamProvider.family<Vault?, String>((ref, vaultId) {
  final repository = ref.watch(vaultRepositoryProvider);

  // Return a stream that:
  // 1. Loads initial data
  // 2. Subscribes to updates from the repository stream
  return Stream.multi((controller) async {
    // First, load and emit initial vault
    try {
      final initialVault = await repository.getVault(vaultId);
      controller.add(initialVault);
    } catch (e) {
      Log.error('Error loading initial vault', e);
      controller.addError(e);
    }

    // Then listen to the repository stream for updates
    final subscription = repository.vaultsStream.listen(
      (vaults) {
        try {
          final vault = vaults.firstWhere((box) => box.id == vaultId);
          controller.add(vault);
        } catch (e) {
          // Vault not found in the list (might have been deleted)
          controller.add(null);
        }
      },
      onError: (error) {
        Log.error('Error in vaultsStream for $vaultId', error);
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
    );

    // Clean up when the provider is disposed
    controller.onCancel = () {
      subscription.cancel();
    };
  });
});

/// Provider for vault repository operations
/// Riverpod automatically ensures this is a singleton - only one instance exists
/// per ProviderScope. The instance is kept alive for the lifetime of the app.
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final repository = VaultRepository(ref.read(loginServiceProvider));

  // Properly clean up when the app is disposed
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});

/// Repository class to handle vault operations
/// This provides a clean API layer between the UI and the service
class VaultRepository {
  final LoginService _loginService;
  static const String _vaultsKey = 'encrypted_vaults';
  List<Vault>? _cachedVaults;
  bool _isInitialized = false;

  // Stream controller for notifying listeners when vaults change
  final StreamController<List<Vault>> _vaultsController = StreamController<List<Vault>>.broadcast();

  // Regular constructor - Riverpod manages the singleton behavior
  VaultRepository(this._loginService);

  /// Stream that emits the updated list of vaults whenever they change
  Stream<List<Vault>> get vaultsStream => _vaultsController.stream;

  /// Initialize the storage and load existing vaults
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadVaults();
      _isInitialized = true;
    } catch (e) {
      Log.error('Error initializing VaultRepository', e);
      _cachedVaults = [];
      _isInitialized = true;
    }
  }

  /// Load vaults from SharedPreferences and decrypt them
  Future<void> _loadVaults() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_vaultsKey);
    Log.info('Loading encrypted vaults from SharedPreferences');

    if (encryptedData == null || encryptedData.isEmpty) {
      _cachedVaults = [];
      Log.info('No encrypted vaults found in SharedPreferences');
      return;
    }

    try {
      // Decrypt the data using our Nostr key
      final decryptedJson = await _loginService.decryptText(encryptedData);
      final List<dynamic> jsonList = json.decode(decryptedJson);
      Log.info('Decrypted ${jsonList.length} vaults');

      _cachedVaults = jsonList.map((json) => Vault.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      Log.error('Error decrypting vaults', e);
      _cachedVaults = [];
    }
  }

  /// Save vaults to SharedPreferences with encryption
  Future<void> _saveVaults() async {
    // #region agent log
    try {
      final logFile = File('/Users/matt/work/horcrux/horcrux_app/.cursor/debug.log');
      await logFile.writeAsString('', mode: FileMode.append);
      await logFile.writeAsString(
          '${json.encode({
                "sessionId": "debug-session",
                "runId": "run1",
                "hypothesisId": "A",
                "location": "vault_provider.dart:168",
                "message": "_saveVaults entry",
                "data": {
                  "cachedVaultsIsNull": _cachedVaults == null,
                  "cachedVaultsLength": _cachedVaults?.length ?? -1
                },
                "timestamp": DateTime.now().millisecondsSinceEpoch
              })}\n',
          mode: FileMode.append);
    } catch (_) {}
    // #endregion
    if (_cachedVaults == null) return;

    try {
      Log.debug('Starting to save ${_cachedVaults!.length} vaults');

      // Convert to JSON with detailed error tracking
      final jsonList = <Map<String, dynamic>>[];
      // #region agent log
      try {
        final logFile = File('/Users/matt/work/horcrux/horcrux_app/.cursor/debug.log');
        await logFile.writeAsString(
            '${json.encode({
                  "sessionId": "debug-session",
                  "runId": "run1",
                  "hypothesisId": "D",
                  "location": "vault_provider.dart:175",
                  "message": "Before JSON conversion loop",
                  "data": {"vaultsCount": _cachedVaults!.length},
                  "timestamp": DateTime.now().millisecondsSinceEpoch
                })}\n',
            mode: FileMode.append);
      } catch (_) {}
      // #endregion
      for (var i = 0; i < _cachedVaults!.length; i++) {
        final vault = _cachedVaults![i];
        Log.debug('Converting vault $i (id: ${vault.id}) to JSON');
        Log.debug('  - Name: ${vault.name}');
        Log.debug('  - Owner: ${vault.ownerPubkey}');
        Log.debug('  - Shards count: ${vault.shards.length}');
        Log.debug(
          '  - Recovery requests count: ${vault.recoveryRequests.length}',
        );
        // #region agent log
        try {
          final logFile = File('/Users/matt/work/horcrux/horcrux_app/.cursor/debug.log');
          await logFile.writeAsString(
              '${json.encode({
                    "sessionId": "debug-session",
                    "runId": "run1",
                    "hypothesisId": "D",
                    "location": "vault_provider.dart:187",
                    "message": "Vault before toJson",
                    "data": {
                      "vaultId": vault.id,
                      "vaultName": vault.name,
                      "contentIsNull": vault.content == null,
                      "contentLength": vault.content?.length ?? -1
                    },
                    "timestamp": DateTime.now().millisecondsSinceEpoch
                  })}\n',
              mode: FileMode.append);
        } catch (_) {}
        // #endregion

        try {
          final vaultJson = vault.toJson();
          jsonList.add(vaultJson);
          Log.debug('  ✓ Vault $i converted successfully');
        } catch (e) {
          Log.error('  ✗ Error converting vault $i to JSON', e);

          // Try to identify which recovery request is causing the issue
          for (var j = 0; j < vault.recoveryRequests.length; j++) {
            final request = vault.recoveryRequests[j];
            Log.debug(
              '    - Recovery request $j: id=${request.id}, status=${request.status.name}',
            );
            Log.debug(
              '      stewardResponses count: ${request.stewardResponses.length}',
            );

            // Check each response
            for (var entry in request.stewardResponses.entries) {
              final pubkey = entry.key;
              final response = entry.value;
              Log.debug(
                '        Response from ${pubkey.substring(0, 8)}: approved=${response.approved}, shardData=${response.shardData != null ? "present" : "null"}',
              );

              if (response.shardData != null) {
                final shard = response.shardData!;
                Log.debug('          ShardData details:');
                Log.debug('            shard type: ${shard.shard.runtimeType}');
                Log.debug(
                  '            threshold type: ${shard.threshold.runtimeType}',
                );
                Log.debug(
                  '            shardIndex type: ${shard.shardIndex.runtimeType}',
                );
                Log.debug(
                  '            totalShards type: ${shard.totalShards.runtimeType}',
                );
                Log.debug(
                  '            primeMod type: ${shard.primeMod.runtimeType}',
                );
                Log.debug(
                  '            creatorPubkey type: ${shard.creatorPubkey.runtimeType}',
                );
                Log.debug(
                  '            createdAt type: ${shard.createdAt.runtimeType}',
                );
                Log.debug(
                  '            vaultId: ${shard.vaultId} (type: ${shard.vaultId?.runtimeType})',
                );
                Log.debug(
                  '            vaultName: ${shard.vaultName} (type: ${shard.vaultName?.runtimeType})',
                );
                Log.debug(
                  '            peers: ${shard.peers} (type: ${shard.peers?.runtimeType})',
                );
                Log.debug(
                  '            recipientPubkey: ${shard.recipientPubkey} (type: ${shard.recipientPubkey?.runtimeType})',
                );
                Log.debug(
                  '            nostrEventId: ${shard.nostrEventId} (type: ${shard.nostrEventId?.runtimeType})',
                );
              }
            }
          }
          rethrow;
        }
      }

      Log.debug('All vaults converted to JSON, encoding...');
      // #region agent log
      Log.error('DEBUG: jsonList.length = ${jsonList.length}');
      Log.error('DEBUG: _cachedVaults!.length = ${_cachedVaults!.length}');
      // Calculate size breakdown
      int totalShards = 0;
      int totalShardBytes = 0;
      for (var vault in _cachedVaults!) {
        totalShards += vault.shards.length;
        for (var shard in vault.shards) {
          final shardJson = shardDataToJson(shard);
          final shardJsonString = json.encode(shardJson);
          totalShardBytes += shardJsonString.length;
          if (vault.shards.length > 10) {
            Log.error('DEBUG: Vault ${vault.id} has ${vault.shards.length} shards');
            Log.error('DEBUG: First shard JSON size: ${shardJsonString.length} chars');
            Log.error(
                'DEBUG: Shard fields: shard=${shard.shard.length}, primeMod=${shard.primeMod.length}, peers=${shard.peers?.length ?? 0}');
          }
        }
      }
      Log.error('DEBUG: Total shards across all vaults: $totalShards');
      Log.error('DEBUG: Total shard JSON bytes: $totalShardBytes');
      // #endregion
      final jsonString = json.encode(jsonList);
      Log.debug('JSON encoded successfully (${jsonString.length} characters)');
      // #region agent log
      Log.error('DEBUG: jsonString.length = ${jsonString.length}');
      Log.error(
          'DEBUG: Shards account for ${(totalShardBytes / jsonString.length * 100).toStringAsFixed(1)}% of total size');
      // #endregion

      // Encrypt the JSON data using our Nostr key
      final encryptedData = await _loginService.encryptText(jsonString);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_vaultsKey, encryptedData);
      Log.info(
        'Saved ${jsonList.length} encrypted vaults to SharedPreferences',
      );

      // Notify listeners that vaults have changed
      final vaultsList = List<Vault>.unmodifiable(_cachedVaults!);
      _vaultsController.add(vaultsList);
    } catch (e) {
      Log.error('Error encrypting and saving vaults', e);
      throw Exception('Failed to save vaults: $e');
    }
  }

  /// Get all vaults
  Future<List<Vault>> getAllVaults() async {
    await initialize();
    return List.unmodifiable(_cachedVaults ?? []);
  }

  /// Get a specific vault by ID
  Future<Vault?> getVault(String id) async {
    await initialize();
    try {
      return _cachedVaults!.firstWhere((lb) => lb.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save a vault (add new or update existing)
  Future<void> saveVault(Vault vault) async {
    await initialize();

    final index = _cachedVaults!.indexWhere((lb) => lb.id == vault.id);
    if (index == -1) {
      // Add new vault
      _cachedVaults!.add(vault);
    } else {
      // Update existing vault
      _cachedVaults![index] = vault;
    }

    await _saveVaults();
  }

  /// Add a new vault
  Future<void> addVault(Vault vault) async {
    await initialize();
    _cachedVaults!.add(vault);
    await _saveVaults();
  }

  /// Update an existing vault
  Future<void> updateVault(String id, String name, String content) async {
    await initialize();
    final index = _cachedVaults!.indexWhere((lb) => lb.id == id);
    if (index != -1) {
      final existingVault = _cachedVaults![index];
      _cachedVaults![index] = existingVault.copyWith(
        name: name,
        content: content,
      );
      await _saveVaults();
    }
  }

  /// Delete a vault
  Future<void> deleteVault(String id) async {
    await initialize();
    _cachedVaults!.removeWhere((lb) => lb.id == id);
    await _saveVaults();
  }

  /// Clear all vaults (for testing/debugging)
  Future<void> clearAll() async {
    _cachedVaults = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vaultsKey);
    _isInitialized = false;
  }

  /// Refresh vaults from storage
  Future<void> refresh() async {
    _isInitialized = false;
    _cachedVaults = null;
    await initialize();
  }

  // ========== Backup Config Operations ==========

  /// Update backup configuration for a vault
  Future<void> updateBackupConfig(String vaultId, BackupConfig config) async {
    await initialize();

    final index = _cachedVaults!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    final vault = _cachedVaults![index];
    _cachedVaults![index] = vault.copyWith(backupConfig: config);
    await _saveVaults();
    Log.info('Updated backup configuration for vault $vaultId');
  }

  /// Get backup configuration for a vault
  Future<BackupConfig?> getBackupConfig(String vaultId) async {
    await initialize();

    final vault = _cachedVaults!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return vault.backupConfig;
  }

  /// Update steward status in backup configuration
  /// This is the single source of truth for steward status updates
  Future<void> updateStewardStatus({
    required String vaultId,
    required String pubkey, // Hex format
    required StewardStatus status,
    DateTime? acknowledgedAt,
    String? acknowledgmentEventId,
    int? acknowledgedDistributionVersion,
  }) async {
    await initialize();

    final vault = _cachedVaults!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    final backupConfig = vault.backupConfig;
    if (backupConfig == null) {
      throw ArgumentError('Vault $vaultId has no backup configuration');
    }

    // Find and update the steward
    final stewardIndex = backupConfig.stewards.indexWhere(
      (h) => h.pubkey == pubkey,
    );
    if (stewardIndex == -1) {
      throw ArgumentError('Steward $pubkey not found in vault $vaultId');
    }

    final updatedStewards = List<Steward>.from(backupConfig.stewards);
    updatedStewards[stewardIndex] = copySteward(
      updatedStewards[stewardIndex],
      status: status,
      acknowledgedAt: acknowledgedAt,
      acknowledgmentEventId: acknowledgmentEventId,
      acknowledgedDistributionVersion: acknowledgedDistributionVersion,
    );

    final updatedConfig = copyBackupConfig(
      backupConfig,
      stewards: updatedStewards,
    );
    await updateBackupConfig(vaultId, updatedConfig);

    Log.info('Updated steward $pubkey status to $status in vault $vaultId');
  }

  // ========== Shard Management Methods ==========

  /// Add a shard to a vault (supports multiple shards during recovery)
  Future<void> addShardToVault(String vaultId, ShardData shard) async {
    await initialize();

    final index = _cachedVaults!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    final vault = _cachedVaults![index];
    final updatedShards = List<ShardData>.from(vault.shards)..add(shard);

    _cachedVaults![index] = vault.copyWith(shards: updatedShards);
    await _saveVaults();
    Log.info(
      'Added shard to vault $vaultId (total shards: ${updatedShards.length})',
    );
  }

  /// Get all shards for a vault
  Future<List<ShardData>> getShardsForVault(String vaultId) async {
    await initialize();

    final vault = _cachedVaults!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return List.unmodifiable(vault.shards);
  }

  /// Clear all shards for a vault
  Future<void> clearShardsForVault(String vaultId) async {
    await initialize();

    final index = _cachedVaults!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    _cachedVaults![index] = _cachedVaults![index].copyWith(shards: []);
    await _saveVaults();
    Log.info('Cleared all shards for vault $vaultId');
  }

  /// Delete vault content while preserving shards and backup config
  /// This is used when owner has distributed keys and wants to delete
  /// the local copy of content, relying on recovery to restore it later
  Future<void> deleteVaultContent(String vaultId) async {
    await initialize();

    final index = _cachedVaults!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    _cachedVaults![index] = _cachedVaults![index].copyWithContentDeleted();
    await _saveVaults();
    Log.info('Deleted content for vault $vaultId (shards preserved)');
  }

  /// Check if we are a steward for a vault (have any shards)
  Future<bool> isKeyHolderForVault(String vaultId) async {
    await initialize();

    final vault = _cachedVaults!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return vault.isSteward;
  }

  // ========== Recovery Request Management Methods ==========

  /// Add a recovery request to a vault
  Future<void> addRecoveryRequestToVault(
    String vaultId,
    RecoveryRequest request,
  ) async {
    await initialize();

    final index = _cachedVaults!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    final vault = _cachedVaults![index];
    final updatedRequests = List<RecoveryRequest>.from(vault.recoveryRequests)..add(request);

    _cachedVaults![index] = vault.copyWith(recoveryRequests: updatedRequests);
    await _saveVaults();
    Log.info('Added recovery request ${request.id} to vault $vaultId');
  }

  /// Update a recovery request in a vault
  Future<void> updateRecoveryRequestInVault(
    String vaultId,
    String requestId,
    RecoveryRequest updatedRequest,
  ) async {
    await initialize();

    final index = _cachedVaults!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    final vault = _cachedVaults![index];
    final requestIndex = vault.recoveryRequests.indexWhere(
      (r) => r.id == requestId,
    );

    if (requestIndex == -1) {
      throw ArgumentError('Recovery request not found: $requestId');
    }

    final updatedRequests = List<RecoveryRequest>.from(vault.recoveryRequests);
    updatedRequests[requestIndex] = updatedRequest;

    _cachedVaults![index] = vault.copyWith(recoveryRequests: updatedRequests);
    await _saveVaults();
    Log.info('Updated recovery request $requestId in vault $vaultId');
  }

  /// Get all recovery requests for a vault
  Future<List<RecoveryRequest>> getRecoveryRequestsForVault(
    String vaultId,
  ) async {
    await initialize();

    final vault = _cachedVaults!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return List.unmodifiable(vault.recoveryRequests);
  }

  /// Get the active recovery request for a vault (if any)
  Future<RecoveryRequest?> getActiveRecoveryRequest(String vaultId) async {
    await initialize();

    final vault = _cachedVaults!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return vault.activeRecoveryRequest;
  }

  /// Get all recovery requests across all vaults
  Future<List<RecoveryRequest>> getAllRecoveryRequests() async {
    await initialize();

    final allRequests = <RecoveryRequest>[];
    for (final vault in _cachedVaults!) {
      allRequests.addAll(vault.recoveryRequests);
    }

    return allRequests;
  }

  /// Dispose resources
  void dispose() {
    _vaultsController.close();
  }
}
