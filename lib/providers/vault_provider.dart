import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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
  static const String _legacyVaultsKey = 'encrypted_vaults';
  static const String _vaultsDirectoryName = 'vaults';
  static const String _vaultFilePrefix = 'vault_';
  static const String _vaultFileExtension = '.encrypted';
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
      await _cleanupOldStorageFormat();
      await _loadVaults();
      _isInitialized = true;
    } catch (e) {
      Log.error('Error initializing VaultRepository', e);
      _cachedVaults = [];
      _isInitialized = true;
    }
  }

  void _notifyVaultsChanged() {
    final vaultsList = List<Vault>.unmodifiable(_cachedVaults ?? const []);
    _vaultsController.add(vaultsList);
  }

  Future<Directory> _getVaultsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultsDir = Directory('${appDir.path}/$_vaultsDirectoryName');
    if (!await vaultsDir.exists()) {
      await vaultsDir.create(recursive: true);
    }
    return vaultsDir;
  }

  String _fileNameFromPath(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  bool _isVaultFilePath(String path) {
    final name = _fileNameFromPath(path);
    return name.startsWith(_vaultFilePrefix) && name.endsWith(_vaultFileExtension);
  }

  String _vaultIdFromFileName(String fileName) {
    var id = fileName;
    if (id.startsWith(_vaultFilePrefix)) {
      id = id.substring(_vaultFilePrefix.length);
    }
    if (id.endsWith(_vaultFileExtension)) {
      id = id.substring(0, id.length - _vaultFileExtension.length);
    }
    return id;
  }

  Future<File> _getVaultFile(String vaultId) async {
    final vaultsDir = await _getVaultsDirectory();
    return File('${vaultsDir.path}/$_vaultFilePrefix$vaultId$_vaultFileExtension');
  }

  Future<void> _cleanupOldStorageFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final oldEncryptedData = prefs.getString(_legacyVaultsKey);
    if (oldEncryptedData == null) {
      return;
    }

    Log.info('Detected legacy vault storage format - clearing old data');
    await prefs.remove(_legacyVaultsKey);
    Log.info('Cleared legacy SharedPreferences vault storage');
  }

  /// Load vaults from individual encrypted files and decrypt them
  Future<void> _loadVaults() async {
    final vaultsDir = await _getVaultsDirectory();
    final vaults = <Vault>[];

    final entities = await vaultsDir.list(followLinks: false).toList();
    final vaultFiles = entities.whereType<File>().where((f) => _isVaultFilePath(f.path)).toList()
      ..sort((a, b) => _fileNameFromPath(a.path).compareTo(_fileNameFromPath(b.path)));

    if (vaultFiles.isEmpty) {
      _cachedVaults = [];
      Log.info('No vault files found in ${vaultsDir.path}');
      return;
    }

    Log.info('Loading ${vaultFiles.length} encrypted vault files from ${vaultsDir.path}');

    for (final file in vaultFiles) {
      final fileName = _fileNameFromPath(file.path);
      final vaultId = _vaultIdFromFileName(fileName);

      try {
        final encryptedData = await file.readAsString();
        if (encryptedData.isEmpty) {
          Log.error('Vault file is empty, skipping: ${file.path}');
          continue;
        }

        final decryptedJson = await _loginService.decryptText(encryptedData);
        final vaultJson = json.decode(decryptedJson) as Map<String, dynamic>;
        final vault = Vault.fromJson(vaultJson);

        // Defensive: ignore files that don't match their embedded vault ID.
        if (vault.id != vaultId) {
          Log.error(
            'Vault ID mismatch for file ${file.path}: expected $vaultId, got ${vault.id}. Skipping.',
          );
          continue;
        }

        vaults.add(vault);
      } catch (e) {
        Log.error('Error loading vault $vaultId from ${file.path}', e);
        // Isolated failure: skip corrupted/unreadable vault file
      }
    }

    _cachedVaults = vaults;
  }

  /// Save a single vault to its own encrypted file
  Future<void> _saveVault(Vault vault) async {
    try {
      final file = await _getVaultFile(vault.id);
      final jsonString = json.encode(vault.toJson());
      final encryptedData = await _loginService.encryptText(jsonString);
      await file.writeAsString(encryptedData);
      Log.info('Saved encrypted vault to ${file.path}');
      _notifyVaultsChanged();
    } catch (e) {
      Log.error('Error encrypting and saving vault ${vault.id}', e);
      throw Exception('Failed to save vault ${vault.id}: $e');
    }
  }

  Future<void> _deleteVaultFile(String vaultId) async {
    try {
      final file = await _getVaultFile(vaultId);
      if (await file.exists()) {
        await file.delete();
      }
      Log.info('Deleted vault file for $vaultId');
    } catch (e) {
      Log.error('Error deleting vault file for $vaultId', e);
      throw Exception('Failed to delete vault $vaultId: $e');
    } finally {
      _notifyVaultsChanged();
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

    await _saveVault(vault);
  }

  /// Add a new vault
  Future<void> addVault(Vault vault) async {
    await initialize();
    _cachedVaults!.add(vault);
    await _saveVault(vault);
  }

  /// Update an existing vault
  Future<void> updateVault(String id, String name, String content) async {
    await initialize();
    final index = _cachedVaults!.indexWhere((lb) => lb.id == id);
    if (index != -1) {
      final existingVault = _cachedVaults![index];
      final updatedVault = existingVault.copyWith(
        name: name,
        content: content,
      );
      _cachedVaults![index] = updatedVault;
      await _saveVault(updatedVault);
    }
  }

  /// Delete a vault
  Future<void> deleteVault(String id) async {
    await initialize();
    _cachedVaults!.removeWhere((lb) => lb.id == id);
    await _deleteVaultFile(id);
  }

  /// Clear all vaults (for testing/debugging)
  Future<void> clearAll() async {
    _cachedVaults = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyVaultsKey);
    try {
      final vaultsDir = await _getVaultsDirectory();
      final entities = await vaultsDir.list(followLinks: false).toList();
      for (final entity in entities) {
        if (entity is File && _isVaultFilePath(entity.path)) {
          await entity.delete();
        }
      }
    } catch (e) {
      Log.error('Error clearing vault files', e);
    }
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
    final updatedVault = vault.copyWith(backupConfig: config);
    _cachedVaults![index] = updatedVault;
    await _saveVault(updatedVault);
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

    final updatedVault = vault.copyWith(shards: updatedShards);
    _cachedVaults![index] = updatedVault;
    await _saveVault(updatedVault);
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

    final updatedVault = _cachedVaults![index].copyWith(shards: []);
    _cachedVaults![index] = updatedVault;
    await _saveVault(updatedVault);
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

    final updatedVault = _cachedVaults![index].copyWithContentDeleted();
    _cachedVaults![index] = updatedVault;
    await _saveVault(updatedVault);
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

    final updatedVault = vault.copyWith(recoveryRequests: updatedRequests);
    _cachedVaults![index] = updatedVault;
    await _saveVault(updatedVault);
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

    final updatedVault = vault.copyWith(recoveryRequests: updatedRequests);
    _cachedVaults![index] = updatedVault;
    await _saveVault(updatedVault);
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
