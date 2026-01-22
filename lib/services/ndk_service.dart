import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../providers/key_provider.dart';
import 'login_service.dart';
import 'vault_share_service.dart';
import 'invitation_service.dart';
import 'shard_distribution_service.dart';
import 'logger.dart';
import 'publish_service.dart';
import '../models/nostr_kinds.dart';
import '../models/shard_data.dart';
import '../models/recovery_request.dart';

/// Event emitted when a recovery response is received
class RecoveryResponseEvent {
  final String recoveryRequestId;
  final String vaultId;
  final String senderPubkey;
  final bool approved;
  final ShardData? shardData;
  final String? nostrEventId;

  RecoveryResponseEvent({
    required this.recoveryRequestId,
    required this.vaultId,
    required this.senderPubkey,
    required this.approved,
    this.shardData,
    this.nostrEventId,
  });
}

// Provider for NdkService
final Provider<NdkService> ndkServiceProvider = Provider<NdkService>((ref) {
  final loginService = ref.read(loginServiceProvider);
  final service = NdkService(
    ref: ref,
    loginService: loginService,
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
  final Ref _ref;
  final LoginService _loginService;
  final InvitationService Function() _getInvitationService;

  Ndk? _ndk;
  bool _isInitialized = false;
  NdkResponse? _giftWrapSubscription;
  final List<String> _activeRelays = [];
  StreamSubscription<Nip01Event>? _giftWrapStreamSub;

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
    required InvitationService Function() getInvitationService,
  })  : _ref = ref,
        _loginService = loginService,
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
      await stopListening();
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
    await _closeSubscriptions();

    Log.info('Setting up NDK subscriptions on ${_activeRelays.length} relays');

    // Subscribe to all gift wrap events (kind 1059)
    // All Horcrux data (shards, recovery requests, recovery responses) are sent as gift wraps
    _giftWrapSubscription = _ndk!.requests.subscription(
      filters: [
        Filter(
          kinds: [NostrKind.giftWrap.value], // Gift wrap events
          pTags: [myPubkey], // Events sent to us
          limit: 100, // Get recent events
        ),
      ],
      explicitRelays: _activeRelays,
    );

    // Listen to gift wrap stream - will route to appropriate handler based on inner kind
    _giftWrapStreamSub = _giftWrapSubscription!.stream.listen(
      (event) => _handleGiftWrap(event),
      onError: (error) => Log.error('Error in gift wrap stream', error),
    );

    Log.info(
      'NDK subscriptions active for gift wrapped events (kind ${NostrKind.giftWrap.value})',
    );
  }

  /// Handle incoming gift wrap event (kind 1059)
  /// Routes to appropriate handler based on the inner kind
  Future<void> _handleGiftWrap(Nip01Event event) async {
    try {
      Log.info('Received gift wrap event: ${event.id}');

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
      } else if (unwrappedEvent.kind == NostrKind.invitationRsvp.value) {
        await _handleInvitationRsvp(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.invitationDenial.value) {
        await _handleInvitationDenial(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.shardConfirmation.value) {
        await _handleShardConfirmation(unwrappedEvent);
      } else if (unwrappedEvent.kind == NostrKind.keyHolderRemoved.value) {
        await _handleKeyHolderRemoved(unwrappedEvent);
      } else {
        Log.warning('Unknown gift wrap inner kind: ${unwrappedEvent.kind}');
      }
    } catch (e) {
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
      );
      _recoveryResponseController.add(responseEvent);

      Log.info(
        'Emitted recovery response to stream: $recoveryRequestId from $senderPubkey',
      );
    } catch (e) {
      Log.error('Error handling recovery response data', e);
    }
  }

  /// Handle incoming invitation RSVP event (kind 1340)
  Future<void> _handleInvitationRsvp(Nip01Event event) async {
    try {
      Log.info('Processing invitation RSVP event: ${event.id}');
      Log.debug(
        'RSVP event before processing: kind=${event.kind}, content length=${event.content.length}, content preview=${event.content.length > 100 ? event.content.substring(0, 100) : event.content}',
      );
      final invitationService = _getInvitationService();
      await invitationService.processRsvpEvent(event: event);
      Log.info('Successfully processed RSVP event: ${event.id}');
    } catch (e) {
      Log.error('Error handling invitation RSVP event ${event.id}', e);
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
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
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

  /// Stop listening to all subscriptions
  Future<void> stopListening() async {
    await _closeSubscriptions();
    Log.info('Stopped all NDK subscriptions');
  }

  /// Close all active subscriptions
  Future<void> _closeSubscriptions() async {
    await _giftWrapStreamSub?.cancel();
    _giftWrapStreamSub = null;
    _giftWrapSubscription = null;
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

  /// Publish an encrypted event (rumor + gift wrap)
  ///
  /// Creates a rumor event with the given content and kind,
  /// wraps it in a gift wrap for the recipient,
  /// and broadcasts it to the specified relays.
  ///
  /// Returns the gift wrap event ID.
  Future<String?> publishEncryptedEvent({
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

      // Build the gift wrap event
      final giftWrap = await _buildGiftWrapEvent(
        content: content,
        kind: kind,
        recipientPubkey: recipientPubkey,
        tags: tags,
        customPubkey: customPubkey,
      );

      // Enqueue the signed event for publishing
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

      return result.eventId;
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

  /// Publish an encrypted event to multiple recipients
  ///
  /// Creates a rumor event with the given content and kind,
  /// wraps it in gift wraps for each recipient,
  /// and broadcasts them to the specified relays.
  ///
  /// Returns list of gift wrap event IDs.
  Future<List<String>> publishEncryptedEventToMultiple({
    required String content,
    required int kind,
    required List<String> recipientPubkeys, // Hex format
    required List<String> relays,
    List<List<String>>? tags,
    String? customPubkey, // Hex format - if null, uses current user's pubkey
  }) async {
    await _ensureInitialized();

    final eventIds = <String>[];

    for (final recipientPubkey in recipientPubkeys) {
      try {
        final eventId = await publishEncryptedEvent(
          content: content,
          kind: kind,
          recipientPubkey: recipientPubkey,
          relays: relays,
          tags: tags,
          customPubkey: customPubkey,
        );
        if (eventId != null) {
          eventIds.add(eventId);
        }
      } catch (e) {
        Log.error(
          'Error publishing encrypted event to ${recipientPubkey.substring(0, 8)}...',
          e,
        );
      }
    }

    return eventIds;
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
    await stopListening();
    
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
