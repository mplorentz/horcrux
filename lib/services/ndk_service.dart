import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../providers/key_provider.dart';
import '../utils/date_time_extensions.dart';
import 'login_service.dart';
import 'vault_share_service.dart';
import 'invitation_service.dart';
import 'shard_distribution_service.dart';
import 'logger.dart';
import 'processed_nostr_event_store.dart';
import 'publish_service.dart';
import '../models/nostr_kinds.dart';
import '../models/shard_data.dart';
import '../models/recovery_request.dart';

/// Nostr `since` for relay subscription filters ([NdkService] gift-wrap subscriptions).
///
/// When a cursor exists: [min] of (rolling window start, last seen `created_at`) — the
/// **older** bound — so a stale cursor (e.g. weeks ago) requests from that cursor, not
/// only the last [recentWindow]. When the cursor is inside the window, we still go back
/// to the window start so we always overlap at least [recentWindow].
///
/// No cursor yet (never received an event for this relay): `0` so the REQ asks from
/// the epoch (full history the relay will return, subject to relay `limit`).
@visibleForTesting
int computeSinceTime({
  required DateTime nowUtc,
  required int? lastSeenEventCreatedAtUnix,
  Duration recentWindow = const Duration(days: 3),
}) {
  final windowStartSec = nowUtc.subtract(recentWindow).secondsSinceEpoch;
  final last = lastSeenEventCreatedAtUnix;
  if (last == null || last <= 0) {
    return 0;
  }
  return math.min(windowStartSec, last);
}

/// Event emitted when a recovery response is received
class RecoveryResponseEvent {
  final String recoveryRequestId;
  final String vaultId;
  final String senderPubkey;
  final bool approved;
  final ShardData? shardData;
  final String? nostrEventId;
  final DateTime? createdAt;

  RecoveryResponseEvent({
    required this.recoveryRequestId,
    required this.vaultId,
    required this.senderPubkey,
    required this.approved,
    this.shardData,
    this.nostrEventId,
    this.createdAt,
  });
}

// Provider for NdkService
final Provider<NdkService> ndkServiceProvider = Provider<NdkService>((ref) {
  final loginService = ref.read(loginServiceProvider);
  final processedEventStore = ref.read(processedNostrEventStoreProvider);
  final service = NdkService(
    ref: ref,
    loginService: loginService,
    processedEventStore: processedEventStore,
    getInvitationService: () => ref.read(invitationServiceProvider),
  );

  // Clean up when disposed
  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
});

/// Service for managing NDK (Nostr Development Kit) connections and subscriptions
/// Handles real-time listening for recovery requests and key share events
class NdkService {
  /// Pseudo-relay URL for FCM-delivered gift wraps ([processGiftWrapFromForegroundPush]).
  static const _fcmForegroundPushRelayUrl = 'push://horcrux-fcm';

  final Ref _ref;
  final LoginService _loginService;
  final ProcessedNostrEventStore _processedEventStore;
  final InvitationService Function() _getInvitationService;

  Ndk? _ndk;
  bool _isInitialized = false;
  final List<NdkResponse> _subscriptionResponses = [];
  final List<StreamSubscription<Nip01Event>> _subscriptionStreamSubs = [];
  final List<String> _activeRelays = [];

  late final PublishService _publishService;

  // Event streams for recovery-related events (breaking circular dependency)
  final StreamController<RecoveryRequest> _recoveryRequestController =
      StreamController<RecoveryRequest>.broadcast();
  final StreamController<RecoveryResponseEvent> _recoveryResponseController =
      StreamController<RecoveryResponseEvent>.broadcast();

  /// Stream of incoming recovery requests
  Stream<RecoveryRequest> get recoveryRequestStream => _recoveryRequestController.stream;

  /// Stream of incoming recovery responses
  Stream<RecoveryResponseEvent> get recoveryResponseStream => _recoveryResponseController.stream;

  NdkService({
    required Ref ref,
    required LoginService loginService,
    required ProcessedNostrEventStore processedEventStore,
    required InvitationService Function() getInvitationService,
  })  : _ref = ref,
        _loginService = loginService,
        _processedEventStore = processedEventStore,
        _getInvitationService = getInvitationService {
    _publishService = PublishService(
      getNdk: getNdk,
    );
    unawaited(_publishService.initialize());
  }

  /// Initialize NDK with current user's key and set up subscriptions
  Future<void> initialize() async {
    if (_isInitialized) {
      Log.info('NDK already initialized');
      return;
    }

    try {
      // Get current user's key pair
      final keyPair = await _loginService.getStoredNostrKey();
      if (keyPair == null) {
        throw Exception('No key pair available. Cannot initialize NDK.');
      }

      // Initialize NDK with default config
      _ndk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: Bip340EventVerifier(),
          engine: NdkEngine.JIT,
        ),
      );

      // Login with user's private key
      _ndk!.accounts.loginPrivateKey(
        pubkey: keyPair.publicKey,
        privkey: keyPair.privateKey!,
      );

      _isInitialized = true;
      Log.info(
        'NDK initialized successfully with pubkey: ${keyPair.publicKey}',
      );

      // Start listening for events if we have relays
      if (_activeRelays.isNotEmpty) {
        await _setupSubscriptions();
      }
    } catch (e) {
      Log.error('Error initializing NDK', e);
      throw Exception('Failed to initialize NDK: $e');
    }
  }

  /// Add a relay and start listening to it immediately
  Future<void> addRelay(String relayUrl) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activeRelays.contains(relayUrl)) {
      Log.info('Relay already active: $relayUrl');
      return;
    }

    try {
      _activeRelays.add(relayUrl);
      Log.info(
        'Added relay: $relayUrl (total active: ${_activeRelays.length})',
      );

      // Restart subscriptions to include new relay
      await _setupSubscriptions();
      _publishService.onRelayReconnected(relayUrl);
    } catch (e) {
      Log.error('Error adding relay $relayUrl', e);
      _activeRelays.remove(relayUrl);
    }
  }

  /// Remove a relay from active listening
  Future<void> removeRelay(String relayUrl) async {
    _activeRelays.remove(relayUrl);
    Log.info(
      'Removed relay: $relayUrl (remaining active: ${_activeRelays.length})',
    );

    // Restart subscriptions without this relay
    if (_activeRelays.isNotEmpty) {
      await _setupSubscriptions();
    } else {
      await closeSubscriptions();
    }
  }

  /// Set up subscriptions for recovery requests and key shares
  Future<void> _setupSubscriptions() async {
    if (!_isInitialized || _ndk == null) {
      Log.warning('Cannot setup subscriptions: NDK not initialized');
      return;
    }

    // Get current user's pubkey
    final keyPair = await _loginService.getStoredNostrKey();
    if (keyPair == null) {
      Log.error('No key pair available for subscriptions');
      return;
    }

    final myPubkey = keyPair.publicKey;

    // Close existing subscriptions
    await closeSubscriptions();

    Log.info('Setting up NDK subscriptions on ${_activeRelays.length} relays');

    await _processedEventStore.ensureLoaded();

    // One subscription per relay so we can persist a cursor per relay (merged NDK streams
    // do not expose which relay delivered each event).
    for (final relayUrl in _activeRelays) {
      final lastSeen = await _processedEventStore.getLastSeen(relayUrl);
      final sinceFilter = computeSinceTime(
        nowUtc: DateTime.now().toUtc(),
        lastSeenEventCreatedAtUnix: lastSeen,
      );
      Log.info(
        'Nostr subscription for $relayUrl since=$sinceFilter '
        '(last seen event created_at=${lastSeen ?? 'none'})',
      );

      // Subscribe to all gift wrap events (kind 1059)
      // All Horcrux data (shards, recovery requests, recovery responses) are sent as gift wraps
      final response = _ndk!.requests.subscription(
        filters: [
          Filter(
            kinds: [NostrKind.giftWrap.value],
            pTags: [myPubkey],
            since: sinceFilter,
          ),
        ],
        explicitRelays: [relayUrl],
      );
      _subscriptionResponses.add(response);

      _subscriptionStreamSubs.add(
        response.stream.listen(
          (event) => _handleIncomingNostrEvent(event, relayUrl: relayUrl),
          onError: (error) => Log.error('Error in Nostr subscription stream ($relayUrl)', error),
        ),
      );
    }

    Log.info(
      'NDK subscriptions setup for ${_subscriptionResponses.length} relays',
    );
  }

  /// Unwraps and routes a kind-1059 gift wrap received on an FCM foreground message
  /// with inline `event_json` — same pipeline as relay subscription deliveries.
  ///
  /// No-ops when NDK cannot be initialized (no key). Large pushes that omit inline
  /// JSON are handled later by the tap / cold-start path.
  Future<void> processGiftWrapFromForegroundPush(Nip01Event event) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e, st) {
        Log.warning(
          'NDK could not initialize; skipping FCM foreground gift-wrap',
          e,
          st,
        );
        return;
      }
    }
    await _handleIncomingNostrEvent(event, relayUrl: _fcmForegroundPushRelayUrl);
  }

  /// Fetches a kind-1059 gift wrap by [eventIdHex] using [relayHints] first, then
  /// any [getActiveRelays] entries — for FCM payloads that omit inline `event_json`.
  Future<Nip01Event?> fetchGiftWrapByIdForPush({
    required String eventIdHex,
    List<String>? relayHints,
  }) async {
    await _ensureInitialized();
    if (_ndk == null) return null;

    final relays = <String>{
      ...?relayHints,
      ..._activeRelays,
    }.toList();
    if (relays.isEmpty) {
      Log.warning(
        'fetchGiftWrapByIdForPush: no relays (empty hints and no active subscriptions)',
      );
      return null;
    }

    try {
      final filter = Filter(
        kinds: [NostrKind.giftWrap.value],
        ids: [eventIdHex],
      );
      final response = _ndk!.requests.query(
        filters: [filter],
        explicitRelays: relays,
      );
      final events = await response.future;
      if (events.isEmpty) {
        Log.warning('fetchGiftWrapByIdForPush: relay returned no events for $eventIdHex');
        return null;
      }
      for (final e in events) {
        if (e.id == eventIdHex) return e;
      }
      return events.first;
    } catch (e, st) {
      Log.warning('fetchGiftWrapByIdForPush failed', e, st);
      return null;
    }
  }

  /// Best-effort [Vault.id] for navigation after a push — unwraps once and reads
  /// inner JSON/tags. Returns `null` when unknown or unwrap fails.
  Future<String?> resolveVaultIdForGiftWrap(Nip01Event giftWrap) async {
    await _ensureInitialized();
    if (_ndk == null) return null;
    try {
      final inner = await _ndk!.giftWrap.fromGiftWrap(giftWrap: giftWrap);
      switch (inner.kind) {
        case 1337: // [NostrKind.shardData]
          final m = json.decode(inner.content) as Map<String, dynamic>;
          final id = m['vaultId'] as String? ?? m['vault_id'] as String?;
          return (id != null && id.isNotEmpty) ? id : null;
        case 1338: // [NostrKind.recoveryRequest]
          final m = json.decode(inner.content) as Map<String, dynamic>;
          final id = m['vault_id'] as String? ?? m['vaultId'] as String?;
          return (id != null && id.isNotEmpty) ? id : null;
        case 1339: // [NostrKind.recoveryResponse]
          final m = json.decode(inner.content) as Map<String, dynamic>;
          final id = m['vault_id'] as String? ?? m['vaultId'] as String?;
          return (id != null && id.isNotEmpty) ? id : null;
        case 1342: // [NostrKind.shardConfirmation]
          return _firstTagValue(inner.tags, 'vault_id');
        default:
          return null;
      }
    } catch (e, st) {
      Log.debug('resolveVaultIdForGiftWrap failed', e, st);
      return null;
    }
  }

  String? _firstTagValue(List<List<String>> tags, String name) {
    for (final t in tags) {
      if (t.length >= 2 && t[0] == name) {
        final v = t[1];
        return v.isEmpty ? null : v;
      }
    }
    return null;
  }

  /// Handle incoming Nostr events
  /// Routes to appropriate handler based on the inner kind.
  Future<void> _handleIncomingNostrEvent(
    Nip01Event event, {
    required String relayUrl,
  }) async {
    if (!await _processedEventStore.claimEvent(event.id)) {
      if (await _processedEventStore.contains(event.id)) {
        await _processedEventStore.recordLastSeen(relayUrl, event.createdAt);
      }
      return;
    }

    try {
      Log.info('Received subscription Nostr event: ${event.id}');

      // Unwrap the gift wrap event using NDK
      final unwrappedEvent = await _ndk!.giftWrap.fromGiftWrap(giftWrap: event);

      Log.info(
        'Unwrapped event: kind=${unwrappedEvent.kind}, id=${unwrappedEvent.id}',
      );
      Log.debug('Gift wrap event tags: ${event.tags}');
      Log.debug('Unwrapped event tags: ${unwrappedEvent.tags}');

      // Route based on the inner event kind
      if (unwrappedEvent.kind == NostrKind.shardData.value) {
        await _handleShardData(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.recoveryRequest.value) {
        await _handleRecoveryRequestData(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.recoveryResponse.value) {
        await _handleRecoveryResponseData(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.invitationAcceptance.value) {
        await _handleInvitationAcceptance(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.invitationDenial.value) {
        await _handleInvitationDenial(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.shardConfirmation.value) {
        await _handleShardConfirmation(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.keyHolderRemoved.value) {
        await _handleKeyHolderRemoved(unwrappedEvent);
      } else {
        Log.warning('Unknown gift wrap inner kind: ${unwrappedEvent.kind}');
      }

      await _processedEventStore.recordProcessed(event.id);
      await _processedEventStore.recordLastSeen(relayUrl, event.createdAt);
    } catch (e) {
      await _processedEventStore.releaseClaimedEvent(event.id);
      Log.error('Error handling gift wrap event ${event.id}', e);
    }
  }

  /// Handle incoming shard data (kind 1337)
  Future<void> _handleShardData(Nip01Event event) async {
    try {
      Log.info('Processing shard data event: ${event.id}');

      // Parse the shard data from the unwrapped content
      final shardJson = json.decode(event.content) as Map<String, dynamic>;
      var shardData = shardDataFromJson(shardJson);

      // Set the nostrEventId from the unwrapped event ID
      // This is needed for duplicate detection when the owner receives their own shard
      shardData = shardData.copyWith(nostrEventId: event.id);

      Log.debug('Shard data: $shardData');

      // Store the shard data and send confirmation event
      // This handles the complete invitation flow
      final vaultId = shardData.vaultId;
      if (vaultId == null || vaultId.isEmpty) {
        Log.error(
          'Cannot process shard data event ${event.id}: missing vaultId in shard data',
        );
        return;
      }

      final vaultShareService = _ref.read(vaultShareServiceProvider);
      await vaultShareService.processVaultShare(vaultId, shardData);
    } catch (e) {
      Log.error('Error handling shard data event ${event.id}', e);
    }
  }

  /// Handle incoming recovery request data (kind 1338)
  Future<void> _handleRecoveryRequestData(Nip01Event event) async {
    try {
      // Parse the recovery request from the unwrapped content
      final requestData = json.decode(event.content) as Map<String, dynamic>;
      final senderPubkey = event.pubKey;

      // Create RecoveryRequest object
      final recoveryRequest = RecoveryRequest(
        id: requestData['recovery_request_id'] as String? ?? event.id,
        vaultId: requestData['vault_id'] as String,
        initiatorPubkey: senderPubkey,
        requestedAt: DateTime.parse(requestData['requested_at'] as String),
        status: RecoveryRequestStatus.sent,
        threshold: requestData['threshold'] as int? ?? 1, // Default to 1 if not present
        nostrEventId: event.id,
        eventCreationTime: DateTime.fromMillisecondsSinceEpoch(
          event.createdAt * 1000,
          isUtc: true,
        ),
        expiresAt: requestData['expires_at'] != null
            ? DateTime.parse(requestData['expires_at'] as String)
            : null,
        stewardResponses: {}, // Will be populated later
        isPractice:
            requestData['is_practice'] as bool? ?? false, // Read is_practice from Nostr payload
      );

      // Emit recovery request to stream (RecoveryService will listen)
      _recoveryRequestController.add(recoveryRequest);

      Log.info('Emitted incoming recovery request to stream: ${event.id}');
    } catch (e) {
      Log.error('Error handling recovery request data', e);
    }
  }

  /// Handle incoming recovery response data (kind 1339)
  Future<void> _handleRecoveryResponseData(Nip01Event event) async {
    try {
      // Parse the recovery response from the unwrapped content
      final responseData = json.decode(event.content) as Map<String, dynamic>;
      final senderPubkey = event.pubKey;

      final recoveryRequestId = responseData['recovery_request_id'] as String;
      final vaultId = responseData['vault_id'] as String;
      final approved = responseData['approved'] as bool;

      Log.info(
        'Received recovery response from $senderPubkey for vault $vaultId: approved=$approved',
      );

      ShardData? shardData;

      // If approved, extract and store the shard data FOR RECOVERY
      if (approved && responseData.containsKey('shard_data')) {
        final shardDataJson = responseData['shard_data'] as Map<String, dynamic>;
        shardData = shardDataFromJson(shardDataJson);

        // Store as a recovery shard (not a steward shard)
        final vaultShareService = _ref.read(vaultShareServiceProvider);
        await vaultShareService.addRecoveryShard(recoveryRequestId, shardData);

        Log.info(
          'Stored recovery shard from $senderPubkey for recovery request $recoveryRequestId',
        );
      }

      // Emit recovery response to stream (RecoveryService will listen)
      final responseEvent = RecoveryResponseEvent(
        recoveryRequestId: recoveryRequestId,
        vaultId: vaultId,
        senderPubkey: senderPubkey,
        approved: approved,
        shardData: shardData,
        nostrEventId: event.id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          event.createdAt * 1000,
          isUtc: true,
        ),
      );
      _recoveryResponseController.add(responseEvent);

      Log.info(
        'Emitted recovery response to stream: $recoveryRequestId from $senderPubkey',
      );
    } catch (e) {
      Log.error('Error handling recovery response data', e);
    }
  }

  /// Handle incoming invitation acceptance event (kind 1340)
  Future<void> _handleInvitationAcceptance(Nip01Event event) async {
    try {
      Log.info('Processing invitation acceptance event: ${event.id}');
      Log.debug(
        'Invitation acceptance event before processing: kind=${event.kind}, content length=${event.content.length}, content preview=${event.content.length > 100 ? event.content.substring(0, 100) : event.content}',
      );
      final invitationService = _getInvitationService();
      await invitationService.processInvitationAcceptanceEvent(event: event);
      Log.info('Successfully processed invitation acceptance event: ${event.id}');
    } catch (e) {
      Log.error('Error handling invitation acceptance event ${event.id}', e);
    }
  }

  /// Handle incoming invitation denial event (kind 1341)
  Future<void> _handleInvitationDenial(Nip01Event event) async {
    try {
      Log.info('Processing invitation denial event: ${event.id}');
      final invitationService = _getInvitationService();
      await invitationService.processDenialEvent(event: event);
      Log.info('Successfully processed denial event: ${event.id}');
    } catch (e) {
      Log.error('Error handling invitation denial event ${event.id}', e);
    }
  }

  /// Handle incoming shard confirmation event (kind 1342)
  Future<void> _handleShardConfirmation(Nip01Event event) async {
    try {
      Log.info('Processing shard confirmation event: ${event.id}');
      Log.debug('Shard confirmation event tags: ${event.tags}');
      final shardDistributionService = _ref.read(
        shardDistributionServiceProvider,
      );
      await shardDistributionService.processShardConfirmationEvent(
        event: event,
      );
      Log.info('Successfully processed shard confirmation event: ${event.id}');
    } catch (e) {
      Log.error('Error handling shard confirmation event ${event.id}', e);
    }
  }

  /// Handle incoming steward removed event (kind 1345)
  Future<void> _handleKeyHolderRemoved(Nip01Event event) async {
    try {
      Log.info('Processing steward removed event: ${event.id}');
      Log.debug('Key holder removed event tags: ${event.tags}');
      final vaultShareService = _ref.read(vaultShareServiceProvider);
      await vaultShareService.processKeyHolderRemoval(event: event);
      Log.info('Successfully processed steward removed event: ${event.id}');
    } catch (e) {
      Log.error('Error handling steward removed event ${event.id}', e);
    }
  }

  /// Publish a recovery request to stewards
  Future<String?> publishRecoveryRequest({
    required String vaultId,
    required List<String> stewardPubkeys,
    DateTime? expiresAt,
  }) async {
    if (!_isInitialized || _ndk == null) {
      throw Exception('NDK not initialized');
    }

    try {
      final keyPair = await _loginService.getStoredNostrKey();
      if (keyPair == null) {
        throw Exception('No key pair available');
      }

      // Create recovery request payload
      final requestPayload = {
        'vaultId': vaultId,
        'requestType': 'recovery',
        'expiresAt': expiresAt?.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final requestJson = json.encode(requestPayload);

      // Send encrypted DM to each steward
      final publishedEventIds = <String>[];

      for (final keyHolderPubkey in stewardPubkeys) {
        // Encrypt the request for this steward
        final encryptedContent = await _loginService.encryptForRecipient(
          plaintext: requestJson,
          recipientPubkey: keyHolderPubkey,
        );

        // Create kind 4 DM event
        final dmEvent = Nip01Event(
          kind: NostrKind.recoveryRequest.value,
          pubKey: keyPair.publicKey,
          content: encryptedContent,
          tags: [
            ['p', keyHolderPubkey], // Recipient
          ],
          createdAt: secondsSinceEpoch(),
        );

        // Sign and broadcast the event
        await _ndk!.accounts.sign(dmEvent);
        _ndk!.broadcast.broadcast(
          nostrEvent: dmEvent,
          specificRelays: _activeRelays.isNotEmpty ? _activeRelays : null,
        );

        publishedEventIds.add(dmEvent.id);
        Log.info(
          'Published recovery request to $keyHolderPubkey: ${dmEvent.id}',
        );
      }

      return publishedEventIds.isNotEmpty ? publishedEventIds.first : null;
    } catch (e) {
      Log.error('Error publishing recovery request', e);
      return null;
    }
  }

  /// Publish a recovery response
  Future<String?> publishRecoveryResponse({
    required String initiatorPubkey,
    required String recoveryRequestId,
    required bool approved,
    String? shardDataJson,
  }) async {
    if (!_isInitialized || _ndk == null) {
      throw Exception('NDK not initialized');
    }

    try {
      final keyPair = await _loginService.getStoredNostrKey();
      if (keyPair == null) {
        throw Exception('No key pair available');
      }

      // Create response payload
      final responsePayload = {
        'recoveryRequestId': recoveryRequestId,
        'approved': approved,
        'shardData': shardDataJson,
        'respondedAt': DateTime.now().toIso8601String(),
      };

      final responseJson = json.encode(responsePayload);

      // Encrypt for initiator
      final encryptedContent = await _loginService.encryptForRecipient(
        plaintext: responseJson,
        recipientPubkey: initiatorPubkey,
      );

      // Create kind 4 DM event
      final dmEvent = Nip01Event(
        kind: NostrKind.recoveryResponse.value,
        pubKey: keyPair.publicKey,
        content: encryptedContent,
        tags: [
          ['p', initiatorPubkey], // Send to initiator
          ['e', recoveryRequestId], // Reference to original request
        ],
        createdAt: secondsSinceEpoch(),
      );

      // Sign and broadcast the event
      await _ndk!.accounts.sign(dmEvent);
      _ndk!.broadcast.broadcast(
        nostrEvent: dmEvent,
        specificRelays: _activeRelays.isNotEmpty ? _activeRelays : null,
      );

      Log.info('Published recovery response: ${dmEvent.id}');
      return dmEvent.id;
    } catch (e) {
      Log.error('Error publishing recovery response', e);
      return null;
    }
  }

  /// Close all active subscriptions
  Future<void> closeSubscriptions() async {
    for (final sub in _subscriptionStreamSubs) {
      await sub.cancel();
    }
    _subscriptionStreamSubs.clear();
    _subscriptionResponses.clear();
    Log.info('Stopped all NDK subscriptions');
  }

  /// Get the list of active relays
  List<String> getActiveRelays() {
    return List.unmodifiable(_activeRelays);
  }

  /// Ensure NDK is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _ndk == null) {
      await initialize();
    }
  }

  /// Get current user's public key
  Future<String?> getCurrentPubkey() async {
    final keyPair = await _loginService.getStoredNostrKey();
    return keyPair?.publicKey;
  }

  /// Publish an encrypted event (rumor + gift wrap).
  ///
  /// Creates a rumor event with the given content and kind, wraps it in a
  /// gift wrap for the recipient, and broadcasts it to the specified relays.
  ///
  /// Returns the signed gift wrap event on success, or `null` when every
  /// relay rejected it. Callers that only care about the event ID can read
  /// `.id` off the result; callers that need to forward the wrap elsewhere
  /// (e.g. to `horcrux-notifier` for push) can pass the whole event.
  Future<Nip01Event?> publishEncryptedEvent({
    required String content,
    required int kind,
    required String recipientPubkey, // Hex format
    required List<String> relays,
    List<List<String>>? tags,
    String? customPubkey, // Hex format - if null, uses current user's pubkey
  }) async {
    await _ensureInitialized();

    try {
      final pubkeySnippet =
          recipientPubkey.length > 8 ? recipientPubkey.substring(0, 8) : recipientPubkey;

      final giftWrap = await _buildGiftWrapEvent(
        content: content,
        kind: kind,
        recipientPubkey: recipientPubkey,
        tags: tags,
        customPubkey: customPubkey,
      );

      final result = await _publishService.enqueueEvent(
        event: giftWrap,
        relays: relays,
      );

      if (result.successfulRelays.isEmpty) {
        Log.error(
          'Failed to publish encrypted event (kind $kind) to $pubkeySnippet after retries',
        );
        return null;
      }

      if (result.failedRelays.isNotEmpty) {
        Log.warning(
          'Encrypted event published with partial success (event ${result.eventId}): '
          'successful relays=${result.successfulRelays.length}, failed=${result.failedRelays.length}',
        );
      } else {
        Log.info(
          'Encrypted event published to all relays: ${result.eventId}',
        );
      }

      return giftWrap;
    } catch (e, stackTrace) {
      Log.error('Error enqueuing encrypted event', e);
      Log.debug('Encrypted event enqueue stack', stackTrace);
      return null;
    }
  }

  /// Build a gift wrap event (rumor + gift wrap)
  ///
  /// Creates a rumor event with the given content and kind,
  /// wraps it in a gift wrap for the recipient.
  ///
  /// Returns the signed gift wrap event.
  Future<Nip01Event> _buildGiftWrapEvent({
    required String content,
    required int kind,
    required String recipientPubkey, // Hex format
    List<List<String>>? tags,
    String? customPubkey, // Hex format - if null, uses current user's pubkey
  }) async {
    if (!_isInitialized || _ndk == null) {
      throw Exception('NDK not initialized');
    }

    final senderPubkey = customPubkey ?? await getCurrentPubkey();
    if (senderPubkey == null) {
      throw Exception('No sender pubkey available');
    }

    final rumor = await _ndk!.giftWrap.createRumor(
      customPubkey: senderPubkey,
      content: content,
      kind: kind,
      tags: tags ?? [],
    );

    return _ndk!.giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: recipientPubkey,
    );
  }

  /// Publish an encrypted event to multiple recipients.
  ///
  /// Creates a rumor event with the given content and kind, wraps it in a
  /// distinct gift wrap for each recipient, and broadcasts them to the
  /// specified relays.
  ///
  /// The returned list is positionally aligned with [recipientPubkeys];
  /// entries for recipients whose publish failed are `null`. Callers that
  /// only want event IDs can map over the non-null entries and read `.id`.
  Future<List<Nip01Event?>> publishEncryptedEventToMultiple({
    required String content,
    required int kind,
    required List<String> recipientPubkeys, // Hex format
    required List<String> relays,
    List<List<String>>? tags,
    String? customPubkey, // Hex format - if null, uses current user's pubkey
  }) async {
    await _ensureInitialized();

    final results = <Nip01Event?>[];

    for (final recipientPubkey in recipientPubkeys) {
      try {
        results.add(
          await publishEncryptedEvent(
            content: content,
            kind: kind,
            recipientPubkey: recipientPubkey,
            relays: relays,
            tags: tags,
            customPubkey: customPubkey,
          ),
        );
      } catch (e) {
        Log.error(
          'Error publishing encrypted event to ${recipientPubkey.substring(0, 8)}...',
          e,
        );
        results.add(null);
      }
    }

    return results;
  }

  /// Get the underlying NDK instance for advanced operations
  ///
  /// Note: This should be used sparingly. Prefer using the methods
  /// provided by NdkService instead of accessing NDK directly.
  Future<Ndk> getNdk() async {
    await _ensureInitialized();
    return _ndk!;
  }

  /// Check if NDK is initialized
  bool get isInitialized => _isInitialized;

  /// Set NDK instance for testing purposes only
  /// This method should only be used in tests
  @visibleForTesting
  void setNdkForTesting(Ndk ndk) {
    _ndk = ndk;
    _isInitialized = true;
  }

  /// Dispose of NDK resources
  /// This stops all listening, closes subscriptions, and cleans up resources
  Future<void> dispose() async {
    // Stop listening to all subscriptions first
    await closeSubscriptions();

    // Close event streams
    await _recoveryRequestController.close();
    await _recoveryResponseController.close();

    // Dispose publish service
    await _publishService.dispose();

    // Clear state
    _activeRelays.clear();
    _ndk = null;
    _isInitialized = false;
    Log.info('NDK service disposed');
  }
}
