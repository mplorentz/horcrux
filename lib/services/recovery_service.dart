import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../models/nostr_kinds.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart';
import '../models/share.dart';
import '../models/steward_status.dart';
import '../providers/vault_provider.dart';
import '../utils/invite_code_utils.dart';
import 'backup_service.dart';
import 'horcrux_notification_service.dart';
import 'local_notification_service.dart';
import 'ndk_service.dart';
import 'notification_recency.dart';
import 'processed_nostr_event_store.dart';
import 'logger.dart';

/// Provider for RecoveryService
/// This service depends on VaultRepository for recovery operations.
///
/// Watches every provider that holds a long-lived DB-backed reference so
/// that invalidating [appDatabaseProvider] on logout cascades through and
/// rebuilds this service against the fresh database. NdkService stays read
/// (not watched) to avoid a circular dependency between the two.
final Provider<RecoveryService> recoveryServiceProvider = Provider<RecoveryService>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  final backupService = ref.watch(backupServiceProvider);
  // Use ref.read() to break circular dependency with NdkService
  final NdkService ndkService = ref.read(ndkServiceProvider);
  final processedStore = ref.watch(processedNostrEventStoreProvider);
  final localNotifications = ref.watch(localNotificationServiceProvider);
  final notificationService = ref.watch(horcruxNotificationServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  final service = RecoveryService(
    repository,
    backupService,
    ndkService,
    processedStore,
    localNotifications,
    notificationService,
    database,
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
  final ProcessedNostrEventStore _processedStore;
  final LocalNotificationService _localNotifications;
  final HorcruxNotificationService _notificationService;
  final AppDatabase _database;

  Set<String>? _viewedNotificationIds;
  bool _isInitialized = false;
  Timer? _expirySweepTimer;

  /// Per-(vault, initiator) mutex serializing [initiateRecovery] calls. The
  /// check-then-act against `getRecoveryRequestsForVault` is async, so without
  /// this two concurrent callers from the same user (e.g. double-tap, or
  /// background retry vs. user tap) could both observe "no active recovery for
  /// me" and persist duplicate active requests. Different users may initiate
  /// concurrently on the same vault and intentionally do not contend on this
  /// lock. The lock is released in `finally`, so a failed initiation does not
  /// leave the (vault, user) permanently locked.
  final Map<String, Future<void>> _initiateRecoveryLocks = {};

  String _initiateRecoveryLockKey(String vaultId, String initiatorPubkey) =>
      '$vaultId|$initiatorPubkey';

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
    this._processedStore,
    this._localNotifications,
    this._notificationService,
    this._database,
  ) {
    _loadViewedNotificationIds();
  }

  /// Dispose resources
  void dispose() {
    _expirySweepTimer?.cancel();
    _expirySweepTimer = null;
    _notificationController.close();
    _recoveryRequestController.close();
  }

  /// Initialize the service: first-open UTC, processed Nostr event ids, viewed-notification ids.
  ///
  /// Call from app startup after [LocalNotificationService.initialize] and before relay traffic
  /// so dedupe and notification policy see stable state.
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await getFirstAppOpenUtc(database: _database);
      await _processedStore.ensureLoaded();
      await _loadViewedNotificationIds();
    } catch (e) {
      Log.error('Error initializing RecoveryService', e);
      _viewedNotificationIds = {};
    }

    _isInitialized = true;
    Log.info('RecoveryService initialized');

    // Emit existing recovery requests to the notification stream
    await _emitNotificationUpdate();

    await repository.cleanupExpiredRecoverySessions();
    _expirySweepTimer ??= Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(repository.cleanupExpiredRecoverySessions());
    });
  }

  /// Load viewed notification IDs from storage
  Future<void> _loadViewedNotificationIds() async {
    try {
      _viewedNotificationIds = (await _database.appStateDao.viewedNotificationIds()).toSet();
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
      await _database.appStateDao.replaceViewedNotificationIds(_viewedNotificationIds!);
      Log.info('Saved ${_viewedNotificationIds!.length} viewed notification IDs to storage');
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

    final pendingRequests = await _pendingRecoveryRequests();
    _notificationController.add(pendingRequests);
  }

  /// Steward banner / counts: unresponded, not self-initiated, and "live" per
  /// [RecoveryNotificationPolicy] (matches local notification rules so relay backfill
  /// does not surface historical requests as pending).
  Future<List<RecoveryRequest>> _pendingRecoveryRequests() async {
    await initialize();
    final firstOpen = await getFirstAppOpenUtc(database: _database);
    final currentPubkey = await _ndkService.getCurrentPubkey();
    final allRequests = await repository.getAllRecoveryRequests();

    return allRequests.where((req) {
      final userResponse = req.responseForPubkey(currentPubkey);
      if (userResponse != null && userResponse.status.isResolved) {
        return false;
      }
      if (!RecoveryNotificationPolicy.shouldNotifyRecoveryRequest(
        req,
        firstOpen,
        currentPubkeyHex: currentPubkey,
      )) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Initiate recovery for a vault
  /// Returns the created recovery request
  /// Throws [StateError] if this user already has a manageable recovery on this vault
  /// (practice or real), matching [Vault.manageableRecoveryFor] and the vault detail UI.
  Future<RecoveryRequest> initiateRecovery(
    String vaultId, {
    required String initiatorPubkey,
    required List<String> stewardPubkeys,
    required int threshold,
    bool isPractice = false,
  }) async {
    await initialize();

    // Wait out any in-flight initiation from this same user on this vault
    // before checking the active-recovery invariant, so the check-then-write
    // below is effectively atomic from the caller's point of view. Other
    // users' concurrent initiations on the same vault do not contend.
    final lockKey = _initiateRecoveryLockKey(vaultId, initiatorPubkey);
    while (_initiateRecoveryLocks.containsKey(lockKey)) {
      try {
        await _initiateRecoveryLocks[lockKey];
      } catch (_) {
        // Previous attempt threw; that's fine -- this caller still gets to try.
      }
    }

    final completer = Completer<void>();
    _initiateRecoveryLocks[lockKey] = completer.future;
    try {
      // At most one manageable session per user per vault across practice and real.
      // Omit [Vault.manageableRecoveryFor]'s `isPractice` filter so the same
      // "newer of the two kinds" rule covers both; that matches
      // [VaultDetailButtonStack] (hide Initiate when either kind is in play).
      final vault = await repository.getVault(vaultId);
      final blockingRecovery = vault?.manageableRecoveryFor(initiatorPubkey);

      if (blockingRecovery != null) {
        throw StateError(
          'You already have an active recovery session for this vault. End it before starting a new one.',
        );
      }

      // Create recovery request
      // Generate cryptographically secure request ID
      final requestId = '${generateSecureID()}_$vaultId';

      final recoveryRequest = RecoveryRequest.makeFromParticipants(
        id: requestId,
        vaultId: vaultId,
        initiatorPubkey: initiatorPubkey,
        requestedAt: DateTime.now(),
        status: RecoveryRequestStatus.pending,
        threshold: threshold,
        stewardPubkeys: stewardPubkeys,
        expiresAt: null,
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
    } finally {
      _initiateRecoveryLocks.remove(lockKey);
      completer.complete();
    }
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
      // Real recovery: use held share data from the database.
      final shares = await repository.getSharesForVault(vaultId);
      if (shares.isEmpty) {
        throw StateError(
          'Cannot recover: you don\'t have a key to this vault.',
        );
      }

      final selectedShard = latestShare(shares)!;

      Log.debug(
        'Selected shard with distributionVersion ${selectedShard.distributionVersion} for recovery',
      );

      final backupConfig = vault.backupConfig;
      if (backupConfig == null) {
        throw StateError(
          'No steward metadata available for recovery. '
          'Please refresh share metadata from a recent distribution.',
        );
      }

      // Use normalized stewards from the DB-backed backup config.
      stewardPubkeys = backupConfig.stewards
          .where((s) => s.pubkey != null && s.status != StewardStatus.invited)
          .map((s) => s.pubkey!)
          .toSet()
          .toList();

      if (stewardPubkeys.isEmpty) {
        throw StateError('No stewards available for recovery');
      }

      threshold = backupConfig.threshold;

      // Use normalized relay configuration first; fall back to legacy shard
      // relay hints for older vault rows.
      if (backupConfig.relays.isNotEmpty) {
        relayUrls = backupConfig.relays;
      } else if (selectedShard.relayUrls != null && selectedShard.relayUrls!.isNotEmpty) {
        relayUrls = selectedShard.relayUrls!;
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
        await respondToRecoveryRequestWithShare(
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

  /// Merges a recovery request from Nostr into local vault state.
  ///
  /// Unlike [initiateRecovery], this does not create a new request id—it persists an event
  /// the relays delivered. Since events are immutable, we skip if this request id already exists locally.
  ///
  /// After a new request is persisted, may show a local OS notification per
  /// [RecoveryNotificationPolicy]. Pass `allowLocalNotification: false` when the
  /// caller has already shown the user a notification for this event (e.g. an FCM
  /// push the user just tapped) so we do not double-notify.
  Future<void> processRecoveryRequest(
    RecoveryRequest request, {
    bool allowLocalNotification = true,
  }) async {
    await initialize();

    final existingRequests = await repository.getRecoveryRequestsForVault(
      request.vaultId,
    );
    final existingRequest = existingRequests.where((r) => r.id == request.id).firstOrNull;

    if (existingRequest != null) {
      Log.info(
        'Ignoring incoming recovery request ${request.id} - already exists locally (status: ${existingRequest.status.name})',
      );
      return;
    }

    await repository.addRecoveryRequestToVault(request.vaultId, request);
    Log.info('Added incoming recovery request ${request.id}');

    await _emitNotificationUpdate();

    if (!allowLocalNotification) return;

    final firstOpen = await getFirstAppOpenUtc(database: _database);
    final myPubkey = await _ndkService.getCurrentPubkey();
    if (RecoveryNotificationPolicy.shouldNotifyRecoveryRequest(
      request,
      firstOpen,
      currentPubkeyHex: myPubkey,
    )) {
      unawaited(_localNotifications.notifyRecoveryRequestProcessed(request));
    }
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
    final collectedShareIds = request.approvedResponsesWithShare
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
      collectedShareIds: collectedShareIds,
      threshold: threshold,
      canRecover: request.approvedCount >= threshold,
      lastUpdated: DateTime.now(),
    );
  }

  /// Merges one steward's recovery response into local vault state (from Nostr or from this device).
  ///
  /// Since events are immutable, we skip processing if the response already exists.
  /// Returns `true` when the response was actually processed, `false` when it was
  /// skipped (duplicate or already processed).
  ///
  /// When [recoveryResponseSourceEvent] is set (relay-delivered event), may show a local OS
  /// notification per [RecoveryNotificationPolicy]. Local-only applies omit it. Pass
  /// `allowLocalNotification: false` when the caller has already shown the user a
  /// notification for this event (e.g. an FCM push the user just tapped) so we do
  /// not double-notify.
  Future<bool> processRecoveryResponse(
    String recoveryRequestId,
    String responderPubkey,
    bool approved, {
    Share? share,
    String? nostrEventId,
    RecoveryResponseEvent? recoveryResponseSourceEvent,
    bool allowLocalNotification = true,
  }) async {
    await initialize();

    // Get the request from vault repository (source of truth)
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    // Check if response already exists for this pubkey
    final existingResponse = request.responseForPubkey(responderPubkey);
    if (existingResponse != null) {
      // Check if this is a duplicate by comparing nostrEventId if provided
      if (nostrEventId != null && existingResponse.nostrEventId == nostrEventId) {
        Log.info(
          'Ignoring duplicate recovery response for request $recoveryRequestId from '
          '${responderPubkey.substring(0, 8)}... (nostrEventId: $nostrEventId)',
        );
        return false;
      }
      // If response already exists and has respondedAt, skip processing (immutable event)
      if (existingResponse.respondedAt != null) {
        Log.info(
          'Ignoring recovery response for request $recoveryRequestId from '
          '${responderPubkey.substring(0, 8)}... - already processed '
          '(respondedAt=${existingResponse.respondedAt})',
        );
        return false;
      }
    }

    // Update the response
    final newResponse = RecoveryResponse(
      pubkey: responderPubkey,
      approved: approved,
      respondedAt: DateTime.now(),
      share: share,
      nostrEventId: nostrEventId,
    );
    final updatedResponses = request.copyResponsesByPubkey();
    updatedResponses[responderPubkey] = newResponse;

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
    final updatedRequest = request.withUpsertedResponse(
      status: newStatus,
      response: newResponse,
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

    // Emit notification update to refresh banner
    await _emitNotificationUpdate();

    if (recoveryResponseSourceEvent != null && allowLocalNotification) {
      final firstOpen = await getFirstAppOpenUtc(database: _database);
      final myPubkey = await _ndkService.getCurrentPubkey();
      if (RecoveryNotificationPolicy.shouldNotifyRecoveryResponse(
        responseCreatedAt: recoveryResponseSourceEvent.createdAt,
        firstOpenUtc: firstOpen,
        requestBeforeApply: request,
        currentPubkeyHex: myPubkey,
        responseSenderPubkey: responderPubkey,
      )) {
        unawaited(
          _localNotifications.notifyRecoveryResponseProcessed(recoveryResponseSourceEvent),
        );
      }
    }

    Log.info(
      'Updated recovery request $recoveryRequestId with response from '
      '${responderPubkey.substring(0, 8)}... (approved: $approved)',
    );
    return true;
  }

  /// Approve or deny a recovery request with automatic shard data retrieval and Nostr sending
  /// This is a convenience method that handles the complete approval flow:
  /// 1. Retrieves shard data if approving
  /// 2. Records the response locally
  /// 3. Sends the response via Nostr using relay URLs from shard data
  Future<void> respondToRecoveryRequestWithShare(
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

    Share? stewardShare;

    // If approving and NOT a practice request, get the share material for this vault
    // Practice requests should not include share payloads
    if (approved && !request.isPractice) {
      final shares = await repository.getSharesForVault(request.vaultId);
      if (shares.isEmpty) {
        throw ArgumentError('No share data found for vault ${request.vaultId}');
      }
      stewardShare = latestShare(shares)!;
      Log.info(
        'Selected share with distributionVersion ${stewardShare.distributionVersion} for recovery request $recoveryRequestId',
      );
    } else if (approved && request.isPractice) {
      Log.info('Practice request - skipping share data retrieval');
    }

    // Submit response locally
    await processRecoveryResponse(
      recoveryRequestId,
      responderPubkey,
      approved,
      share: stewardShare,
    );

    // Send response via Nostr (both approvals and denials)
    // For denials, we need to get relay URLs from vault backup config or steward's shard data
    // since we don't have shard data from the approval
    {
      try {
        List<String> relayUrls = [];

        // Try to get relay URLs from share material first (for approvals)
        if (stewardShare != null &&
            stewardShare.relayUrls != null &&
            stewardShare.relayUrls!.isNotEmpty) {
          relayUrls = stewardShare.relayUrls!;
          Log.info('Using relay URLs from share data for recovery response');
        } else {
          // For denials or when share data doesn't have relay URLs,
          // get relay URLs from vault backup config or steward's held share
          final vault = await repository.getVault(request.vaultId);
          if (vault != null) {
            // Try backup config first
            if (vault.backupConfig != null && vault.backupConfig!.relays.isNotEmpty) {
              relayUrls = vault.backupConfig!.relays;
              Log.info('Using relay URLs from backup config for recovery response');
            } else {
              // Fall back to relay URLs from steward-held share.
              final share = latestShare(await repository.getSharesForVault(request.vaultId));
              if (share != null && share.relayUrls != null && share.relayUrls!.isNotEmpty) {
                relayUrls = share.relayUrls!;
                Log.info('Using relay URLs from steward share data for recovery response');
              }
            }
          }
        }

        if (relayUrls.isNotEmpty) {
          final eventId = await sendRecoveryResponseViaNostr(
            request,
            stewardShare,
            approved,
            relays: relayUrls,
          );
          Log.info(
            'Sent recovery response via Nostr for request $recoveryRequestId (approved: $approved, event: ${eventId.substring(0, 8)}...)',
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
    final request = await getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      throw ArgumentError('Recovery request not found: $recoveryRequestId');
    }

    await _updateRecoveryRequestStatus(
      recoveryRequestId,
      RecoveryRequestStatus.cancelled,
    );

    await repository.deleteRecoveryResponseSharesForRequest(
      vaultId: request.vaultId,
      requestId: recoveryRequestId,
    );
    Log.info(
      'Cleared recovery share payloads for cancelled recovery request $recoveryRequestId',
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

    // Delete recovered content (owned_vaults row) from vault.
    // Skip for practice recoveries — the End-Practice dialog only promises
    // to archive the request, not to delete vault content.
    final vaultExists = await repository.getVault(request.vaultId) != null;
    if (vaultExists && !request.isPractice) {
      await repository.deleteVaultContent(request.vaultId);
      Log.info('Deleted recovered content from vault ${request.vaultId}');
    }

    await repository.deleteRecoveryResponsesForRequest(
      vaultId: request.vaultId,
      requestId: recoveryRequestId,
    );
    Log.info('Deleted recovery response rows for recovery request $recoveryRequestId');

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
    final shares = request.approvedSharesWithPayload;

    if (shares.isEmpty) {
      throw Exception('No recovery shares found');
    }

    if (shares.length < request.threshold) {
      throw Exception(
        'Insufficient shares: need ${request.threshold}, have ${shares.length}',
      );
    }

    // Reconstruct the vault content from the shares
    final content = await backupService.reconstructFromShares(shares: shares);

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

    return request.responses.toList();
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

      Log.info('Sending recovery request ${request.id} to ${request.totalStewards} stewards');

      // Send gift wrap to each steward using NdkService with empty content, data in tags.
      // The signed events come back positionally aligned with the recipient list so we can
      // pipe each one into [tryPushForEvent] without rebuilding it.
      final recipients = request.stewardPubkeys.toList();
      final publishedEvents = await _ndkService.publishEncryptedEventToMultiple(
        content: '',
        kind: NostrKind.recoveryRequest.value,
        recipientPubkeys: recipients,
        relays: relays,
        tags: [
          ['d', 'recovery_request_${request.id}'],
          ['vault_id', request.vaultId],
          ['recovery_request_id', request.id],
          ['is_practice', request.isPractice.toString()],
        ],
        customPubkey: currentPubkey,
        vaultId: request.vaultId,
      );

      final eventIds = [
        for (final event in publishedEvents)
          if (event != null) event.id,
      ];

      // Update request status to sent
      await updateRecoveryRequestStatus(
        request.id,
        RecoveryRequestStatus.sent,
        nostrEventId: eventIds.isNotEmpty ? eventIds.first : null,
      );

      // Best-effort push to each steward. We look up the vault once so the
      // per-recipient loop stays cheap; if the vault is missing (owner
      // bookkeeping error) we skip the push entirely rather than guessing.
      final vaultForPush = await repository.getVault(request.vaultId);
      if (vaultForPush != null) {
        for (final event in publishedEvents) {
          if (event == null) continue;
          await _notificationService.tryPushForEvent(
            event: event,
            kind: NostrKind.recoveryRequest,
            vault: vaultForPush,
            relayHints: relays,
          );
        }
      }

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
    Share? share,
    bool approved, {
    required List<String> relays,
  }) async {
    try {
      final currentPubkey = await _ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        throw Exception('Unable to get current user keys for signing');
      }

      // New Nostr wire format: content is raw payload string (empty for denial/practice), metadata in tags
      final String nostrContent;
      if (approved && !request.isPractice && share != null) {
        nostrContent = shareToNostrContent(share);
      } else {
        nostrContent = '';
      }

      // Build tags: recovery_request_id, vault_id, is_practice, and share metadata
      final tags = <List<String>>[
        ['d', 'recovery_response_${request.id}_$currentPubkey'],
        ['recovery_request_id', request.id],
        ['vault_id', request.vaultId],
      ];

      if (request.isPractice) {
        tags.add(['is_practice', 'true']);
      }

      // Share metadata tags when approved with content
      if (approved && !request.isPractice && share != null) {
        tags.addAll(shareToNostrTags(share));
      }

      Log.debug(
        'Sending recovery response to ${request.initiatorPubkey.substring(0, 8)}...',
      );

      // Publish using NdkService. The returned event is the signed gift
      // wrap, which we forward to the notifier without rebuilding.
      final publishedEvent = await _ndkService.publishEncryptedEvent(
        content: nostrContent,
        kind: NostrKind.recoveryResponse.value,
        recipientPubkey: request.initiatorPubkey,
        relays: relays,
        tags: tags,
        vaultId: request.vaultId,
      );

      if (publishedEvent == null) {
        throw Exception('Failed to publish recovery response event');
      }
      final eventId = publishedEvent.id;

      // Best-effort push to the recovery initiator. Practice responses
      // still deserve a push because the initiator is actively waiting;
      // the body text says "sent a shard" / "approved" / "denied".
      final vaultForPush = await repository.getVault(request.vaultId);
      if (vaultForPush != null) {
        await _notificationService.tryPushForEvent(
          event: publishedEvent,
          kind: NostrKind.recoveryResponse,
          vault: vaultForPush,
          relayHints: relays,
          recoveryApproved: approved,
        );
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

  /// Get pending (unresponded) recovery request notifications for steward UI.
  ///
  /// Excludes own requests, resolved responses, and requests outside
  /// [RecoveryNotificationPolicy] (historical relay replay).
  Future<List<RecoveryRequest>> getPendingNotifications() async {
    return _pendingRecoveryRequests();
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

  /// Get notification count (same scope as [getPendingNotifications]).
  Future<int> getNotificationCount({bool unviewedOnly = true}) async {
    await initialize();

    final filteredRequests = await _pendingRecoveryRequests();

    if (unviewedOnly) {
      return filteredRequests
          .where((request) => !_viewedNotificationIds!.contains(request.id))
          .length;
    }
    return filteredRequests.length;
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
    await _database.appStateDao.clearViewedNotificationIds();
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

/// Recent-vs-historical replay rules for recovery-related local notifications and steward UI
/// ([RecoveryService._pendingRecoveryRequests]).
///
/// Recency itself is defined by [isEventRecent] in `notification_recency.dart`;
/// this policy layers the domain rules on top (self-origin filtering, initiator-
/// only-hears-peer-responses, terminal-session filtering). Kept next to
/// [RecoveryService] and referenced from tests via this type.
class RecoveryNotificationPolicy {
  RecoveryNotificationPolicy._();

  /// Prefer [RecoveryRequest.eventCreationTime]; fall back to [RecoveryRequest.requestedAt].
  ///
  /// When [currentPubkeyHex] is set and matches [RecoveryRequest.initiatorPubkey], returns false
  /// (do not notify for your own recovery request event echoed from relays; steward UI also
  /// excludes self-initiated requests).
  static bool shouldNotifyRecoveryRequest(
    RecoveryRequest request,
    DateTime firstOpenUtc, {
    String? currentPubkeyHex,
  }) {
    if (currentPubkeyHex != null && request.initiatorPubkey == currentPubkeyHex) {
      return false;
    }
    final anchor = request.eventCreationTime ?? request.requestedAt;
    return isEventRecent(anchor, firstOpenUtc);
  }

  /// Whether to show a local OS notification for an incoming recovery **response** event.
  ///
  /// Combines: inner [responseCreatedAt] must exist and fall in the [isEventRecent] window;
  /// [requestBeforeApply] / [currentPubkeyHex] must be known; only the **initiator** is notified
  /// of peers' responses; not when the response is the user's own relay echo; not when the
  /// session is already terminal.
  static bool shouldNotifyRecoveryResponse({
    required DateTime? responseCreatedAt,
    required DateTime firstOpenUtc,
    required RecoveryRequest? requestBeforeApply,
    required String? currentPubkeyHex,
    required String responseSenderPubkey,
  }) {
    if (responseCreatedAt == null) {
      return false;
    }
    if (!isEventRecent(responseCreatedAt, firstOpenUtc)) {
      return false;
    }
    if (requestBeforeApply == null || currentPubkeyHex == null) {
      return false;
    }
    if (responseSenderPubkey == currentPubkeyHex) {
      return false;
    }
    if (requestBeforeApply.status.isTerminal) {
      return false;
    }
    return requestBeforeApply.initiatorPubkey == currentPubkeyHex;
  }
}
