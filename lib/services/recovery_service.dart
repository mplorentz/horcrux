import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nostr_kinds.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart';
import '../models/shard_data.dart';
import '../models/steward_status.dart';
import '../providers/vault_provider.dart';
import '../utils/invite_code_utils.dart';
import 'backup_service.dart';
import 'ndk_service.dart';
import 'vault_share_service.dart';
import 'logger.dart';

/// Provider for RecoveryService
/// This service depends on VaultRepository for recovery operations
final Provider<RecoveryService> recoveryServiceProvider = Provider<RecoveryService>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  final backupService = ref.read(backupServiceProvider);
  // Use ref.read() to break circular dependency with NdkService
  final NdkService ndkService = ref.read(ndkServiceProvider);
  final vaultShareService = ref.read(vaultShareServiceProvider);
  final service = RecoveryService(
    repository,
    backupService,
    ndkService,
    vaultShareService,
  );

  // Clean up streams when disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Service for managing vault recovery operations
/// Includes notification tracking for incoming recovery requests
class RecoveryService {
  final VaultRepository repository;
  final BackupService backupService;
  final NdkService _ndkService;
  final VaultShareService _vaultShareService;

  static const String _viewedNotificationIdsKey = 'viewed_recovery_notification_ids';

  Set<String>? _viewedNotificationIds;
  bool _isInitialized = false;

  // Stream for real-time notification updates
  final _notificationController = StreamController<List<RecoveryRequest>>.broadcast();
  Stream<List<RecoveryRequest>> get notificationStream => _notificationController.stream;

  // Stream for recovery request updates (for status screen)
  final _recoveryRequestController = StreamController<RecoveryRequest>.broadcast();
  Stream<RecoveryRequest> get recoveryRequestStream => _recoveryRequestController.stream;

  RecoveryService(
    this.repository,
    this.backupService,
    this._ndkService,
    this._vaultShareService,
  ) {
    _loadViewedNotificationIds();
    _setupNdkStreamListeners();
  }

  /// Set up listeners for incoming NDK events
  void _setupNdkStreamListeners() {
    // Listen for incoming recovery requests
    _ndkService.recoveryRequestStream.listen(
      (recoveryRequest) async {
        try {
          await addIncomingRecoveryRequest(recoveryRequest);
        } catch (e) {
          Log.error(
            'Error processing incoming recovery request from stream',
            e,
          );
        }
      },
      onError: (error) {
        Log.error('Error in recovery request stream', error);
      },
    );

    // Listen for incoming recovery responses
    _ndkService.recoveryResponseStream.listen(
      (responseEvent) async {
        try {
          await respondToRecoveryRequest(
            responseEvent.recoveryRequestId,
            responseEvent.senderPubkey,
            responseEvent.approved,
            shardData: responseEvent.shardData,
            nostrEventId: responseEvent.nostrEventId,
          );
        } catch (e) {
          Log.error('Error processing recovery response from stream', e);
        }
      },
      onError: (error) {
        Log.error('Error in recovery response stream', error);
      },
    );

    Log.info('RecoveryService listening to NdkService event streams');
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
    _recoveryRequestController.close();
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await _loadViewedNotificationIds();
      _isInitialized = true;
      Log.info('RecoveryService initialized');
    } catch (e) {
      Log.error('Error initializing RecoveryService', e);
      _viewedNotificationIds = {};
      _isInitialized = true;
    }
  }

  /// Load viewed notification IDs from storage
  Future<void> _loadViewedNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_viewedNotificationIdsKey);

    if (jsonData == null || jsonData.isEmpty) {
      _viewedNotificationIds = {};
      return;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonData);
      _viewedNotificationIds = Set<String>.from(jsonList);
      Log.info(
        'Loaded ${_viewedNotificationIds!.length} viewed notification IDs from storage',
      );
    } catch (e) {
      Log.error('Error loading viewed notification IDs', e);
      _viewedNotificationIds = {};
    }
  }

  /// Save viewed notification IDs to storage
  Future<void> _saveViewedNotificationIds() async {
    if (_viewedNotificationIds == null) {
      return;
    }

    try {
      final jsonList = _viewedNotificationIds!.toList();
      final jsonString = json.encode(jsonList);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_viewedNotificationIdsKey, jsonString);
      Log.info('Saved ${jsonList.length} viewed notification IDs to storage');
    } catch (e) {
      Log.error('Error saving viewed notification IDs', e);
      throw Exception('Failed to save viewed notification IDs: $e');
    }
  }

  /// Emit notification update to stream
  Future<void> _emitNotificationUpdate() async {
    if (_viewedNotificationIds == null) {
      return;
    }

    // Get current user's pubkey to filter out their own recovery requests
    final currentPubkey = await _ndkService.getCurrentPubkey();

    // Get all recovery requests from vault repository
    final allRequests = await repository.getAllRecoveryRequests();

    // Filter out viewed notifications and requests initiated by the current user
    final unviewed = allRequests.where((req) {
      // Exclude viewed notifications
      if (_viewedNotificationIds!.contains(req.id)) return false;

      // Exclude requests initiated by the current user (steward's own requests)
      if (currentPubkey != null && req.initiatorPubkey == currentPubkey) {
        return false;
      }

      return true;
    }).toList();

    _notificationController.add(unviewed);
  }

  /// Initiate recovery for a vault
  /// Returns the created recovery request
  /// Throws an exception if the user already has an active recovery request for this vault
  Future<RecoveryRequest> initiateRecovery(
    String vaultId, {
    required String initiatorPubkey,
    required List<String> stewardPubkeys,
    required int threshold,
    Duration? expirationDuration,
    bool isPractice = false,
  }) async {
    await initialize();

    // Check if user already has an active recovery request for this vault
    final existingRequests = await repository.getRecoveryRequestsForVault(
      vaultId,
    );
    final hasActiveRequest = existingRequests.any(
      (r) => r.initiatorPubkey == initiatorPubkey && r.status.isActive,
    );

    if (hasActiveRequest) {
      throw StateError(
        'You already have an active recovery request for this vault. Please manage your existing recovery request.',
      );
    }

    // Create recovery request
    // Generate cryptographically secure request ID
    final requestId = '${generateSecureID()}_$vaultId';
    final expiresAt = expirationDuration != null
        ? DateTime.now().add(expirationDuration)
        : DateTime.now().add(
            const Duration(hours: 24),
          ); // Default 24 hour expiration

    // Initialize steward responses
    final stewardResponses = <String, RecoveryResponse>{};
    for (final pubkey in stewardPubkeys) {
      stewardResponses[pubkey] = RecoveryResponse(
        pubkey: pubkey,
        approved: false,
      );
    }

    final recoveryRequest = RecoveryRequest(
      id: requestId,
      vaultId: vaultId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now(),
      status: RecoveryRequestStatus.pending,
      threshold: threshold,
      expiresAt: expiresAt,
      stewardResponses: stewardResponses,
      isPractice: isPractice,
    );

    // Validate and save
    if (!recoveryRequest.isValid) {
      throw ArgumentError('Invalid recovery request');
    }

    // Add to vault (single source of truth)
    await repository.addRecoveryRequestToVault(vaultId, recoveryRequest);

    // Emit notification update
    await _emitNotificationUpdate();

    Log.info('Created recovery request $requestId for vault $vaultId');
    return recoveryRequest;
  }

  /// Initiate recovery and send it via Nostr
  /// This is a convenience method that handles the full orchestration:
  /// 1. Loads vault data from repository
  /// 2. Extracts steward pubkeys, threshold, and relays based on recovery type
  /// 3. Creates the recovery request
  /// 4. Sends via Nostr using relays from backup config or shard data
  /// 5. Auto-approves if initiator is also a steward
  ///
  /// Returns the created recovery request
  /// Throws an exception if recovery cannot be initiated
  Future<RecoveryRequest> initiateAndSendRecovery(
    String vaultId, {
    Duration? expirationDuration,
    bool isPractice = false,
  }) async {
    await initialize();

    // Get current user pubkey
    final initiatorPubkey = await _ndkService.getCurrentPubkey();
    if (initiatorPubkey == null) {
      throw StateError('Could not load current user');
    }

    // Load vault from repository
    final vault = await repository.getVault(vaultId);
    if (vault == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    List<String> stewardPubkeys;
    int threshold;
    List<String> relayUrls;

    if (isPractice) {
      // Practice recovery: use backup config
      final backupConfig = vault.backupConfig;
      if (backupConfig == null) {
        throw StateError('No recovery plan configured for this vault');
      }

      // Get steward pubkeys from backup config (owners only - stewards cannot practice recovery)
      stewardPubkeys = backupConfig.stewards
          .where(
            (s) => s.pubkey != null && s.status == StewardStatus.holdingKey,
          )
          .map((s) => s.pubkey!)
          .toList();

      if (stewardPubkeys.isEmpty) {
        throw StateError(
          'No stewards available for recovery. Make sure stewards have received and confirmed their keys.',
        );
      }

      threshold = backupConfig.threshold;
      relayUrls = backupConfig.relays;

      if (relayUrls.isEmpty) {
        throw StateError('No relays configured in recovery plan');
      }
    } else {
      // Real recovery: use shard data
      if (vault.shards.isEmpty) {
        throw StateError(
          'Cannot recover: you don\'t have a key to this vault.',
        );
      }

      final selectedShard = vault.mostRecentShard;
      if (selectedShard == null) {
        throw StateError(
          'Cannot recover: you don\'t have a key to this vault.',
        );
      }

      Log.debug(
        'Selected shard with distributionVersion ${selectedShard.distributionVersion} for recovery',
      );

      // Use peers list for recovery (includes owner if they have a shard)
      stewardPubkeys = <String>[];
      if (selectedShard.peers != null) {
        for (final peer in selectedShard.peers!) {
          final pubkey = peer['pubkey'];
          if (pubkey != null) {
            stewardPubkeys.add(pubkey);
          }
        }
      }

      if (stewardPubkeys.isEmpty) {
        throw StateError('No stewards available for recovery');
      }

      threshold = selectedShard.threshold;

      // Get relays from shard data (if available) or backup config
      if (selectedShard.relayUrls != null && selectedShard.relayUrls!.isNotEmpty) {
        relayUrls = selectedShard.relayUrls!;
      } else if (vault.backupConfig != null && vault.backupConfig!.relays.isNotEmpty) {
        relayUrls = vault.backupConfig!.relays;
      } else {
        throw StateError(
          'No relays configured for recovery. Please configure relays in the recovery plan.',
        );
      }
    }

    Log.info(
      'Initiating recovery with ${stewardPubkeys.length} stewards: ${stewardPubkeys.map((k) => k.substring(0, 8)).join(", ")}...',
    );

    // Create recovery request
    final recoveryRequest = await initiateRecovery(
      vaultId,
      initiatorPubkey: initiatorPubkey,
      stewardPubkeys: stewardPubkeys,
      threshold: threshold,
      expirationDuration: expirationDuration,
      isPractice: isPractice,
    );

    // Send recovery request via Nostr
    try {
      await sendRecoveryRequestViaNostr(recoveryRequest, relays: relayUrls);
    } catch (e) {
      Log.error('Failed to send recovery request via Nostr', e);
      // Don't rethrow - recovery request was created successfully
      // even if sending failed
    }

    // Auto-approve if the initiator is in the stewardPubkeys list (includes owner if they have a shard)
    if (stewardPubkeys.contains(initiatorPubkey)) {
      try {
        Log.info('Initiator is a steward (or owner with shard), auto-approving recovery request');
        await respondToRecoveryRequestWithShard(
          recoveryRequest.id,
          initiatorPubkey,
          true,
        );
        Log.info('Auto-approved recovery request');
      } catch (e) {
        Log.error('Failed to auto-approve recovery request', e);
        // Don't rethrow - recovery request was created successfully
        // even if auto-approval failed
      }
    }

    return recoveryRequest;
  }

  /// Add an incoming recovery request (received via Nostr)
  /// This is different from initiateRecovery which creates a new request
  /// Since events are immutable, we skip processing if the request already exists locally
  Future<void> addIncomingRecoveryRequest(RecoveryRequest request) async {
    await initialize();

    // Check if request already exists in vault (source of truth)
    final existingRequests = await repository.getRecoveryRequestsForVault(
      request.vaultId,
    );
    final existingRequest = existingRequests.where((r) => r.id == request.id).firstOrNull;

    if (existingRequest != null) {
      // Since events are immutable, skip processing if we already have this request locally
      Log.info(
        'Ignoring incoming recovery request ${request.id} - already exists locally (status: ${existingRequest.status.name})',
      );
      return;
    }

    // Add new request to vault
    await repository.addRecoveryRequestToVault(request.vaultId, request);
    Log.info('Added incoming recovery request ${request.id}');

    // Emit notification update
    await _emitNotificationUpdate();
  }

  /// Get all recovery requests for the current user
  Future<List<RecoveryRequest>> getRecoveryRequests({
    String? vaultId,
    RecoveryRequestStatus? status,
  }) async {
    await initialize();

    // Get requests from vault repository (source of truth)
    List<RecoveryRequest> requests;
    if (vaultId != null) {
      // Get requests for a specific vault
      requests = await repository.getRecoveryRequestsForVault(vaultId);
    } else {
      // Get all requests across all vaults
      requests = await repository.getAllRecoveryRequests();
    }

    // Filter by status if provided
    if (status != null) {
      requests = requests.where((r) => r.status == status).toList();
    }

    return requests;
  }

  /// Get a specific recovery request by ID
  Future<RecoveryRequest?> getRecoveryRequest(String recoveryRequestId) async {
    await initialize();

    // Get all requests from vault repository and find the matching one
    final allRequests = await repository.getAllRecoveryRequests();
    try {
      return allRequests.firstWhere((r) => r.id == recoveryRequestId);
    } catch (e) {
      return null;
    }
  }

  /// Get recovery status for a specific request
  Future<RecoveryStatus?> getRecoveryStatus(String recoveryRequestId) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) return null;

    // Count responses that have shard data (approved responses)
    final collectedShardIds = request.stewardResponses.values
        .where((r) => r.shardData != null)
        .map((r) => r.pubkey) // Use pubkey as identifier
        .toList();

    // Use the actual Shamir threshold from the recovery request
    final threshold = request.threshold;

    return RecoveryStatus(
      recoveryRequestId: recoveryRequestId,
      totalStewards: request.totalStewards,
      respondedCount: request.respondedCount,
      approvedCount: request.approvedCount,
      deniedCount: request.deniedCount,
      collectedShardIds: collectedShardIds,
      threshold: threshold,
      canRecover: request.approvedCount >= threshold,
      lastUpdated: DateTime.now(),
    );
  }

  /// Respond to a recovery request (from a steward)
  /// Since events are immutable, we skip processing if the response already exists
  Future<void> respondToRecoveryRequest(
    String recoveryRequestId,
    String responderPubkey,
    bool approved, {
    ShardData? shardData,
    String? nostrEventId,
  }) async {
    await initialize();

    // Get the request from vault repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    // Check if response already exists for this pubkey
    final existingResponse = request.stewardResponses[responderPubkey];
    if (existingResponse != null) {
      // Check if this is a duplicate by comparing nostrEventId if provided
      if (nostrEventId != null && existingResponse.nostrEventId == nostrEventId) {
        Log.info(
          'Ignoring duplicate recovery response for request $recoveryRequestId from $responderPubkey (nostrEventId: $nostrEventId)',
        );
        return;
      }
      // If response already exists and has respondedAt, skip processing (immutable event)
      if (existingResponse.respondedAt != null) {
        Log.info(
          'Ignoring recovery response for request $recoveryRequestId from $responderPubkey - response already exists',
        );
        return;
      }
    }

    // Update the response
    final updatedResponses = Map<String, RecoveryResponse>.from(
      request.stewardResponses,
    );
    updatedResponses[responderPubkey] = RecoveryResponse(
      pubkey: responderPubkey,
      approved: approved,
      respondedAt: DateTime.now(),
      shardData: shardData,
      nostrEventId: nostrEventId,
    );

    // Update request status
    var newStatus = request.status;
    if (request.status == RecoveryRequestStatus.pending ||
        request.status == RecoveryRequestStatus.sent) {
      newStatus = RecoveryRequestStatus.inProgress;
    }

    // Check if we have enough approvals to complete
    final approvedCount = updatedResponses.values.where((r) => r.approved).length;

    if (approvedCount >= request.threshold) {
      newStatus = RecoveryRequestStatus.completed;
    }

    // Update the request
    final updatedRequest = request.copyWith(
      status: newStatus,
      stewardResponses: updatedResponses,
    );

    // Update in vault (single source of truth)
    try {
      await repository.updateRecoveryRequestInVault(
        request.vaultId,
        recoveryRequestId,
        updatedRequest,
      );
    } catch (e) {
      Log.error('Error updating recovery request in vault', e);
      rethrow;
    }

    // Emit update to stream for real-time UI updates
    _recoveryRequestController.add(updatedRequest);

    Log.info(
      'Updated recovery request $recoveryRequestId with response from ${responderPubkey.substring(0, 8)}... (approved: $approved)',
    );
  }

  /// Approve or deny a recovery request with automatic shard data retrieval and Nostr sending
  /// This is a convenience method that handles the complete approval flow:
  /// 1. Retrieves shard data if approving
  /// 2. Records the response locally
  /// 3. Sends the response via Nostr using relay URLs from shard data
  Future<void> respondToRecoveryRequestWithShard(
    String recoveryRequestId,
    String responderPubkey,
    bool approved,
  ) async {
    await initialize();

    // Get the recovery request to find the vault ID
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    ShardData? shardData;

    // If approving and NOT a practice request, get the shard data for this vault
    // Practice requests should not include shard data
    if (approved && !request.isPractice) {
      final vault = await repository.getVault(request.vaultId);
      if (vault == null) {
        throw ArgumentError('Vault not found: ${request.vaultId}');
      }
      shardData = vault.mostRecentShard;
      if (shardData == null) {
        throw ArgumentError('No shard data found for vault ${request.vaultId}');
      }
      Log.info(
        'Selected shard with distributionVersion ${shardData.distributionVersion} for recovery request $recoveryRequestId',
      );
    } else if (approved && request.isPractice) {
      Log.info('Practice request - skipping shard data retrieval');
    }

    // Submit response locally
    await respondToRecoveryRequest(
      recoveryRequestId,
      responderPubkey,
      approved,
      shardData: shardData,
    );

    // Send response via Nostr if approved
    // For practice requests, we need to get relay URLs from backup config instead of shard data
    if (approved) {
      try {
        List<String> relayUrls = [];

        if (request.isPractice) {
          // For practice requests, try multiple sources for relay URLs:
          // 1. Backup config (if available, e.g., for owners)
          // 2. Shard data from steward's shards (for stewards)
          final vault = await repository.getVault(request.vaultId);
          if (vault?.backupConfig != null && vault!.backupConfig!.relays.isNotEmpty) {
            relayUrls = vault.backupConfig!.relays;
            Log.info(
              'Using relay URLs from backup config for practice request',
            );
          } else if (vault != null) {
            // Fall back to relay URLs from steward's shards
            final latestShard = vault.mostRecentShard;
            if (latestShard != null &&
                latestShard.relayUrls != null &&
                latestShard.relayUrls!.isNotEmpty) {
              relayUrls = latestShard.relayUrls!;
              Log.info(
                'Using relay URLs from shard data for practice request',
              );
            }
          }
          if (relayUrls.isEmpty) {
            Log.warning(
              'No relay URLs found for practice request (checked backup config and shards)',
            );
          }
        } else if (shardData != null &&
            shardData.relayUrls != null &&
            shardData.relayUrls!.isNotEmpty) {
          // For real recovery, use relay URLs from shard data
          relayUrls = shardData.relayUrls!;
        }

        if (relayUrls.isNotEmpty) {
          await sendRecoveryResponseViaNostr(
            request,
            shardData,
            approved,
            relays: relayUrls,
          );
          Log.info(
            'Sent recovery response via Nostr for request $recoveryRequestId',
          );
        } else {
          Log.warning('No relay URLs available for sending recovery response');
        }
      } catch (e) {
        Log.error('Failed to send recovery response via Nostr', e);
        // Continue anyway - the response is still recorded locally
      }
    }
  }

  /// Helper method to update recovery request status
  Future<void> _updateRecoveryRequestStatus(
    String recoveryRequestId,
    RecoveryRequestStatus status,
  ) async {
    await initialize();

    // Get the request from vault repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    final updatedRequest = request.copyWith(status: status);

    // Update in vault (single source of truth)
    await repository.updateRecoveryRequestInVault(
      request.vaultId,
      recoveryRequestId,
      updatedRequest,
    );

    Log.info(
      'Updated recovery request $recoveryRequestId status to ${status.displayName}',
    );
  }

  /// Cancel a recovery request
  Future<void> cancelRecoveryRequest(String recoveryRequestId) async {
    await _updateRecoveryRequestStatus(
      recoveryRequestId,
      RecoveryRequestStatus.cancelled,
    );

    // Delete all recovery shards for this recovery request
    // Note: User's own shard is stored separately in _cachedShardData (keyed by vaultId)
    // and won't be affected by removeRecoveryShards() which only deletes recovery shards
    // (keyed by recoveryRequestId)
    await _vaultShareService.removeRecoveryShards(recoveryRequestId);
    Log.info(
      'Deleted recovery shards for cancelled recovery request $recoveryRequestId',
    );
  }

  /// Exit recovery mode after successful recovery
  /// Archives the recovery request, deletes recovered content and recovery shards,
  /// while preserving the user's own steward shard
  Future<void> exitRecoveryMode(String recoveryRequestId) async {
    await initialize();

    // Get the request from vault repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    // Update recovery request status to archived
    await _updateRecoveryRequestStatus(
      recoveryRequestId,
      RecoveryRequestStatus.archived,
    );

    // Delete recovered content from vault (set to null)
    final vault = await repository.getVault(request.vaultId);
    if (vault != null) {
      await repository.saveVault(vault.copyWith(content: null));
      Log.info('Deleted recovered content from vault ${request.vaultId}');
    }

    // Delete all recovery shards for this recovery request
    // Note: User's own shard is stored separately in _cachedShardData (keyed by vaultId)
    // and won't be affected by removeRecoveryShards() which only deletes recovery shards
    // (keyed by recoveryRequestId)
    await _vaultShareService.removeRecoveryShards(recoveryRequestId);
    Log.info('Deleted recovery shards for recovery request $recoveryRequestId');

    Log.info('Exited recovery mode for recovery request $recoveryRequestId');
  }

  /// Check if recovery is possible for a vault
  Future<bool> canRecoverVault(String vaultId) async {
    await initialize();

    // Check if there are any active recovery requests for this vault
    final requests = await getRecoveryRequests(vaultId: vaultId);

    for (final request in requests) {
      if (request.status.isActive) {
        final status = await getRecoveryStatus(request.id);
        if (status != null && status.canRecover) {
          return true;
        }
      }
    }

    return false;
  }

  /// Perform vault recovery using collected shards
  /// Returns the recovered vault content
  Future<String> performRecovery(String recoveryRequestId) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    // Get the recovery status to check if recovery is possible
    final status = await getRecoveryStatus(recoveryRequestId);
    if (status == null || !status.canRecover) {
      throw Exception(
        'Recovery is not yet possible - insufficient shares collected',
      );
    }

    // Collect shards from approved responses
    final shards = request.stewardResponses.values
        .where((r) => r.approved && r.shardData != null)
        .map((r) => r.shardData!)
        .toList();

    if (shards.isEmpty) {
      throw Exception('No recovery shards found');
    }

    if (shards.length < request.threshold) {
      throw Exception(
        'Insufficient shards: need ${request.threshold}, have ${shards.length}',
      );
    }

    // Reconstruct the vault content from the shards
    final content = await backupService.reconstructFromShares(shares: shards);

    // Update the vault with recovered content
    final vault = await repository.getVault(request.vaultId);
    if (vault != null) {
      await repository.updateVault(request.vaultId, vault.name, content);
    }

    // Update the recovery request status to completed
    final updatedRequest = request.copyWith(
      status: RecoveryRequestStatus.completed,
    );

    // Update in vault (single source of truth)
    try {
      await repository.updateRecoveryRequestInVault(
        request.vaultId,
        recoveryRequestId,
        updatedRequest,
      );
    } catch (e) {
      Log.error('Error updating completed recovery request in vault', e);
      rethrow;
    }

    Log.info(
      'Successfully recovered vault ${request.vaultId} from $recoveryRequestId',
    );
    return content;
  }

  /// Get steward responses for a recovery request
  Future<List<RecoveryResponse>> getKeyHolderResponses(
    String recoveryRequestId,
  ) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) return [];

    return request.stewardResponses.values.toList();
  }

  /// Update recovery request status (for Nostr event tracking)
  Future<void> updateRecoveryRequestStatus(
    String recoveryRequestId,
    RecoveryRequestStatus status, {
    String? nostrEventId,
  }) async {
    await initialize();

    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    final updatedRequest = request.copyWith(
      status: status,
      nostrEventId: nostrEventId ?? request.nostrEventId,
    );

    // Update in vault (single source of truth)
    try {
      await repository.updateRecoveryRequestInVault(
        request.vaultId,
        recoveryRequestId,
        updatedRequest,
      );
    } catch (e) {
      Log.error('Error updating recovery request status in vault', e);
      rethrow;
    }

    Log.info(
      'Updated recovery request $recoveryRequestId status to ${status.displayName}',
    );
  }

  /// Send recovery request to stewards via Nostr gift wraps
  /// Returns the list of gift wrap event IDs
  Future<List<String>> sendRecoveryRequestViaNostr(
    RecoveryRequest request, {
    required List<String> relays,
  }) async {
    try {
      final currentPubkey = await _ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        throw Exception('Unable to get current user keys for signing');
      }

      Log.info(
        'Sending recovery request ${request.id} to ${request.stewardResponses.length} stewards',
      );

      // Prepare recovery request data
      final requestData = {
        'type': 'recovery_request',
        'recovery_request_id': request.id,
        'vault_id': request.vaultId,
        'initiator_pubkey': request.initiatorPubkey,
        'requested_at': request.requestedAt.toIso8601String(),
        'expires_at': request.expiresAt?.toIso8601String(),
        'threshold': request.threshold,
        'is_practice': request.isPractice,
      };

      final requestJson = json.encode(requestData);

      // Send gift wrap to each steward using NdkService
      final eventIds = await _ndkService.publishEncryptedEventToMultiple(
        content: requestJson,
        kind: NostrKind.recoveryRequest.value,
        recipientPubkeys: request.stewardResponses.keys.toList(),
        relays: relays,
        tags: [
          ['d', 'recovery_request_${request.id}'],
          ['vault_id', request.vaultId],
          ['recovery_request_id', request.id],
        ],
        customPubkey: currentPubkey,
      );

      // Update request status to sent
      await updateRecoveryRequestStatus(
        request.id,
        RecoveryRequestStatus.sent,
        nostrEventId: eventIds.isNotEmpty ? eventIds.first : null,
      );

      Log.info(
        'Successfully sent recovery request ${request.id} to ${eventIds.length} stewards',
      );
      return eventIds;
    } catch (e) {
      Log.error('Failed to send recovery request via Nostr', e);
      rethrow;
    }
  }

  /// Send recovery response (shard data) back to initiator via Nostr gift wrap
  /// Returns the gift wrap event ID
  /// Note: shardData is nullable for practice requests (which don't include shard data)
  Future<String> sendRecoveryResponseViaNostr(
    RecoveryRequest request,
    ShardData? shardData,
    bool approved, {
    required List<String> relays,
  }) async {
    try {
      final currentPubkey = await _ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        throw Exception('Unable to get current user keys for signing');
      }

      // Prepare recovery response data
      final responseData = {
        'type': 'recovery_response',
        'recovery_request_id': request.id,
        'vault_id': request.vaultId,
        'responder_pubkey': currentPubkey,
        'approved': approved,
        'responded_at': DateTime.now().toIso8601String(),
        'is_practice': request.isPractice,
      };

      // Include shard data if approved and NOT a practice request
      // Practice requests should never include shard data
      if (approved && !request.isPractice && shardData != null) {
        responseData['shard_data'] = shardDataToJson(shardData);
      }

      final responseJson = json.encode(responseData);

      Log.debug(
        'Sending recovery response to ${request.initiatorPubkey.substring(0, 8)}...',
      );

      // Publish using NdkService
      final eventId = await _ndkService.publishEncryptedEvent(
        content: responseJson,
        kind: NostrKind.recoveryResponse.value,
        recipientPubkey: request.initiatorPubkey,
        relays: relays,
        tags: [
          ['d', 'recovery_response_${request.id}_$currentPubkey'],
          ['vault_id', request.vaultId],
          ['recovery_request_id', request.id],
          ['approved', approved.toString()],
        ],
      );

      if (eventId == null) {
        throw Exception('Failed to publish recovery response event');
      }

      Log.info(
        'Sent recovery response to ${request.initiatorPubkey.substring(0, 8)}... (event: ${eventId.substring(0, 8)}..., approved: $approved)',
      );
      return eventId;
    } catch (e) {
      Log.error('Failed to send recovery response via Nostr', e);
      rethrow;
    }
  }

  // ========== Notification Methods ==========

  /// Get pending (unviewed) recovery request notifications
  /// Excludes recovery requests initiated by the current user (steward's own requests)
  Future<List<RecoveryRequest>> getPendingNotifications() async {
    await initialize();

    // Get current user's pubkey to filter out their own recovery requests
    final currentPubkey = await _ndkService.getCurrentPubkey();

    final allRequests = await repository.getAllRecoveryRequests();
    return allRequests.where((request) {
      // Exclude viewed notifications
      if (_viewedNotificationIds!.contains(request.id)) return false;

      // Exclude requests initiated by the current user (steward's own requests)
      if (currentPubkey != null && request.initiatorPubkey == currentPubkey) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Get all recovery request notifications (including viewed)
  Future<List<RecoveryRequest>> getAllNotifications() async {
    await initialize();
    return await repository.getAllRecoveryRequests();
  }

  /// Mark a recovery request notification as viewed
  Future<void> markNotificationAsViewed(String recoveryRequestId) async {
    await initialize();

    if (!_viewedNotificationIds!.contains(recoveryRequestId)) {
      _viewedNotificationIds!.add(recoveryRequestId);
      await _saveViewedNotificationIds();
      await _emitNotificationUpdate();
      Log.info('Marked recovery request $recoveryRequestId as viewed');
    }
  }

  /// Mark a recovery request notification as unviewed
  Future<void> markNotificationAsUnviewed(String recoveryRequestId) async {
    await initialize();

    if (_viewedNotificationIds!.contains(recoveryRequestId)) {
      _viewedNotificationIds!.remove(recoveryRequestId);
      await _saveViewedNotificationIds();
      await _emitNotificationUpdate();
      Log.info('Marked recovery request $recoveryRequestId as unviewed');
    }
  }

  /// Get notification count
  /// Excludes recovery requests initiated by the current user (steward's own requests)
  Future<int> getNotificationCount({bool unviewedOnly = true}) async {
    await initialize();

    // Get current user's pubkey to filter out their own recovery requests
    final currentPubkey = await _ndkService.getCurrentPubkey();

    final allRequests = await repository.getAllRecoveryRequests();

    // Filter out requests initiated by the current user
    final filteredRequests = allRequests.where((request) {
      if (currentPubkey != null && request.initiatorPubkey == currentPubkey) {
        return false;
      }
      return true;
    }).toList();

    if (unviewedOnly) {
      return filteredRequests
          .where((request) => !_viewedNotificationIds!.contains(request.id))
          .length;
    } else {
      return filteredRequests.length;
    }
  }

  /// Check if a notification has been viewed
  Future<bool> isNotificationViewed(String recoveryRequestId) async {
    await initialize();
    return _viewedNotificationIds!.contains(recoveryRequestId);
  }

  /// Clear all viewed notification markers (doesn't delete requests)
  Future<void> clearViewedNotifications() async {
    await initialize();

    _viewedNotificationIds!.clear();
    await _saveViewedNotificationIds();
    await _emitNotificationUpdate();
    Log.info('Cleared all viewed notification markers');
  }

  /// Clear all recovery requests (for testing)
  Future<void> clearAll() async {
    _viewedNotificationIds = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_viewedNotificationIdsKey);
    _isInitialized = false;
    _notificationController.add([]);
    Log.info('Cleared all recovery request notifications');
  }

  /// Refresh the cached data from storage
  Future<void> refresh() async {
    _isInitialized = false;
    _viewedNotificationIds = null;
    await initialize();
  }
}
