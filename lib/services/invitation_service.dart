import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invitation_link.dart';
import '../models/invitation_status.dart';
import '../models/invitation_exceptions.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../models/backup_config.dart';
import '../models/vault.dart';
import '../models/nostr_kinds.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../services/login_service.dart';
import '../services/logger.dart';
import '../utils/invite_code_utils.dart';
import '../utils/validators.dart';
import 'invitation_sending_service.dart';
import 'ndk_service.dart';
import 'relay_scan_service.dart';

/// Provider for InvitationService
final invitationServiceProvider = Provider<InvitationService>((ref) {
  final service = InvitationService(
    ref.read(vaultRepositoryProvider),
    ref.read(invitationSendingServiceProvider),
    ref.read(loginServiceProvider),
    () => ref.read(ndkServiceProvider),
    ref.read(relayScanServiceProvider),
  );

  // Properly clean up when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Service for managing invitation links and processing invitation-related events
class InvitationService {
  final VaultRepository repository;
  final InvitationSendingService invitationSendingService;
  final LoginService _loginService;
  final NdkService Function() _getNdkService;
  final RelayScanService _relayScanService;

  // Stream controller for notifying listeners when invitations change
  final StreamController<void> _invitationsChangedController = StreamController<void>.broadcast();

  // SharedPreferences keys
  static String _invitationKey(String inviteCode) => 'invitation_$inviteCode';
  static String _vaultInvitationsKey(String vaultId) => 'vault_invitations_$vaultId';

  InvitationService(
    this.repository,
    this.invitationSendingService,
    this._loginService,
    this._getNdkService,
    this._relayScanService,
  );

  /// Stream that emits whenever invitations change
  /// UI providers listen to this to automatically update
  Stream<void> get invitationsChangedStream => _invitationsChangedController.stream;

  /// Notify listeners that invitations have changed
  void _notifyInvitationsChanged() {
    _invitationsChangedController.add(null);
  }

  /// Dispose of resources
  void dispose() {
    _invitationsChangedController.close();
  }

  /// Generates a new invitation link for a given invitee
  ///
  /// Validates vault exists and user is owner.
  /// Generates cryptographically secure invite code.
  /// Creates InvitationLink and stores in SharedPreferences.
  /// Returns invitation link with URL.
  Future<InvitationLink> generateInvitationLink({
    required String vaultId,
    required String inviteeName,
    required List<String> relayUrls,
  }) async {
    // Validate inputs
    if (inviteeName.trim().isEmpty) {
      throw ArgumentError('Invitee name cannot be empty');
    }

    if (!areValidRelayUrls(relayUrls)) {
      throw ArgumentError(
        'Invalid relay URLs: must be 1-3 valid WebSocket URLs',
      );
    }

    // Get current user's pubkey
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot generate invitation.');
    }

    // Validate vault exists and user is owner
    final vault = await repository.getVault(vaultId);
    if (vault == null) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    if (vault.ownerPubkey != ownerPubkey) {
      throw ArgumentError('User is not the owner of this vault');
    }

    // Generate secure invite code
    final inviteCode = generateSecureID();

    // Create invitation link
    final invitation = createInvitationLink(
      inviteCode: inviteCode,
      vaultId: vaultId,
      vaultName: vault.name,
      ownerPubkey: ownerPubkey,
      relayUrls: relayUrls,
      inviteeName: inviteeName.trim(),
    );

    // Update status to pending (ready to be sent)
    final pendingInvitation = invitation.updateStatus(InvitationStatus.pending);

    // Validate the invitation
    validateInvitationLink(pendingInvitation);

    // Store invitation
    await _saveInvitation(pendingInvitation);

    // Add to vault invitations index
    await _addToVaultIndex(vaultId, inviteCode);

    // Ensure relay URLs are added to NDK service so we can receive RSVP events
    // Add relays asynchronously - don't fail invitation generation if relay addition fails
    _addRelaysToNdk(relayUrls);

    // Sync relays to RelayScanService and ensure scanning is started
    try {
      await _relayScanService.syncRelaysFromUrls(relayUrls);
      await _relayScanService.ensureScanningStarted();
      Log.info(
        'Synced ${relayUrls.length} relay(s) from invitation to RelayScanService',
      );
    } catch (e) {
      Log.error('Error syncing relays from invitation to RelayScanService', e);
      // Don't fail invitation generation if relay sync fails
    }

    // Add invited steward placeholder to backup config immediately
    // This allows the RSVP handler to find and update it when the invitee accepts
    try {
      await _addInvitedKeyHolderToBackupConfig(
        vaultId: vaultId,
        inviteCode: inviteCode,
        inviteeName: inviteeName.trim(),
        relayUrls: relayUrls,
      );
      Log.info(
        'Added invited steward placeholder for $inviteeName to backup config',
      );
    } catch (e) {
      Log.error('Error adding invited steward to backup config', e);
      // Don't fail invitation generation if this fails
    }

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info(
      'Generated invitation link for vault $vaultId, invitee: $inviteeName',
    );

    return pendingInvitation;
  }

  /// Retrieves all pending invitations for a vault
  ///
  /// Loads invitations from SharedPreferences.
  /// Filters to pending status.
  /// Returns sorted by creation date.
  Future<List<InvitationLink>> getPendingInvitations(String vaultId) async {
    // Get all invite codes for this vault
    final inviteCodes = await _getVaultInviteCodes(vaultId);

    // Load all invitations
    final invitations = <InvitationLink>[];
    for (final code in inviteCodes) {
      final invitation = await _loadInvitation(code);
      if (invitation != null) {
        invitations.add(invitation);
      }
    }

    // Filter to pending status and sort by creation date
    final pending = invitations.where((inv) => inv.status == InvitationStatus.pending).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return pending;
  }

  /// Looks up invitation details by invite code
  ///
  /// Looks up invitation code in SharedPreferences.
  /// Returns InvitationLink if found, null otherwise.
  /// Throws ArgumentError if invite code format is invalid.
  Future<InvitationLink?> lookupInvitationByCode(String inviteCode) async {
    // Validate invite code format first
    if (!isValidInviteCodeFormat(inviteCode)) {
      throw ArgumentError(
        'Invalid invitation code format. The code must be a valid Base64URL string.',
      );
    }

    return await _loadInvitation(inviteCode);
  }

  /// Creates an invitation record when received via deep link
  ///
  /// This is called when an invitee opens an invitation link.
  /// Creates a local invitation record so it can be displayed and processed.
  /// If the invitation already exists, updates it with the latest data.
  Future<void> createReceivedInvitation({
    required String inviteCode,
    required String vaultId,
    required String ownerPubkey,
    required List<String> relayUrls,
    String? vaultName,
  }) async {
    // Check if invitation already exists
    final existing = await _loadInvitation(inviteCode);
    if (existing != null) {
      Log.debug('Invitation $inviteCode already exists, skipping creation');
      return;
    }

    // Create invitation record from received link data
    // Note: inviteeName is not known on the receiving side, so we pass null
    final invitation = createInvitationLink(
      inviteCode: inviteCode,
      vaultId: vaultId,
      vaultName: vaultName,
      ownerPubkey: ownerPubkey,
      relayUrls: relayUrls,
      inviteeName: null, // Not available on receiving side
    );

    // Set status to pending (awaiting acceptance)
    final pendingInvitation = invitation.updateStatus(InvitationStatus.pending);

    // Validate the invitation
    validateInvitationLink(pendingInvitation);

    // Store invitation locally
    await _saveInvitation(pendingInvitation);

    // Note: We don't add to vault invitations index on the receiving side
    // because the invitee doesn't own the vault - that index is owner-only

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info(
      'Created received invitation record for inviteCode=$inviteCode, vaultId=$vaultId',
    );
  }

  /// Processes invitation redemption when invitee accepts
  ///
  /// Validates invite code exists and is pending.
  /// Checks if already redeemed.
  /// Updates invitation status to redeemed.
  /// Adds invitee to backup config as steward.
  /// Sends RSVP event via InvitationSendingService.
  /// Updates invitation tracking.
  Future<void> redeemInvitation({
    required String inviteCode,
    required String inviteePubkey, // Hex format
  }) async {
    // Validate invite code format first
    if (!isValidInviteCodeFormat(inviteCode)) {
      throw ArgumentError(
        'Invalid invitation code format. The code must be a valid Base64URL string.',
      );
    }

    // Validate invitee pubkey format
    if (!isValidHexPubkey(inviteePubkey)) {
      throw ArgumentError(
        'Invalid invitee pubkey format: must be 64 hex characters',
      );
    }

    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      throw InvitationNotFoundException(inviteCode);
    }

    // Validate invitation status
    if (invitation.status == InvitationStatus.redeemed) {
      throw InvitationAlreadyRedeemedException(inviteCode);
    }

    if (invitation.status == InvitationStatus.invalidated) {
      throw InvitationInvalidatedException(
        inviteCode,
        'Invitation has been invalidated',
      );
    }

    if (!invitation.status.canRedeem) {
      throw ArgumentError(
        'Invitation cannot be redeemed in current status: ${invitation.status}',
      );
    }

    // Check if user is trying to redeem their own invitation (vault owner)
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey != null && invitation.ownerPubkey == ownerPubkey) {
      throw ArgumentError(
        'You cannot redeem an invitation to your own vault. You are already the owner.',
      );
    }

    // Check if user is already a steward
    // Note: On the invitee side, the vault may not exist yet, so we check if it exists first
    final vault = await repository.getVault(invitation.vaultId);
    if (vault != null) {
      final backupConfig = vault.backupConfig;
      final isAlreadyKeyHolder = backupConfig?.stewards.any(
            (holder) => holder.pubkey == inviteePubkey,
          ) ??
          false;

      if (isAlreadyKeyHolder) {
        throw ArgumentError(
          'You are already a steward for this vault. This invitation has already been accepted.',
        );
      }

      // Vault exists - add invitee to backup config
      // This happens on the owner's side when they accept their own invitation
      await _addKeyHolderToBackupConfig(
        invitation.vaultId,
        inviteePubkey,
        invitation.inviteeName, // Can be null for received invitations
        invitation.relayUrls,
      );
    } else {
      // Vault doesn't exist yet - this is the invitee side
      // Create a vault stub so invitee can see it in their list
      final vaultStub = Vault(
        id: invitation.vaultId,
        name: invitation.vaultName,
        content: null, // No content yet - waiting for shard
        createdAt: invitation.createdAt,
        ownerPubkey: invitation.ownerPubkey,
        shards: [], // No shards yet - awaiting key distribution
        backupConfig: null,
      );

      await repository.addVault(vaultStub);
      Log.info(
        'Created vault stub for invitee: ${invitation.vaultId} (${invitation.vaultName})',
      );
    }

    // Update invitation status to redeemed
    final redeemedInvitation = invitation.updateStatus(
      InvitationStatus.redeemed,
      redeemedBy: inviteePubkey,
      redeemedAt: DateTime.now(),
    );
    await _saveInvitation(redeemedInvitation);

    // Send RSVP event BEFORE syncing relays to avoid timing issues
    // The RSVP uses specificRelays which will connect to relays on demand
    String? rsvpEventId;
    try {
      rsvpEventId = await invitationSendingService.sendRsvpEvent(
        inviteCode: inviteCode,
        ownerPubkey: invitation.ownerPubkey,
        relayUrls: invitation.relayUrls,
      );

      if (rsvpEventId == null) {
        // RSVP event failed to publish - throw error so UI can show appropriate message
        throw Exception(
          'Failed to publish RSVP event to relays. Please check your relay connections.',
        );
      }

      Log.info('RSVP event published successfully: $rsvpEventId');
    } catch (e) {
      Log.error('Error sending RSVP event for invitation $inviteCode', e);
      // Re-throw so the UI can handle it appropriately
      // The invitation is already marked as redeemed, but RSVP failed
      throw Exception(
        'Invitation was accepted locally, but failed to notify the owner: $e',
      );
    }

    // NOW sync relays from invitation and start scanning so invitee can receive shards
    // This is done AFTER sending RSVP to avoid timing conflicts with relay connections
    try {
      await _relayScanService.syncRelaysFromUrls(invitation.relayUrls);
      await _relayScanService.ensureScanningStarted();
      Log.info(
        'Synced ${invitation.relayUrls.length} relay(s) from invitation to RelayScanService (invitee side)',
      );
    } catch (e) {
      Log.error(
        'Error syncing relays from invitation to RelayScanService (invitee side)',
        e,
      );
      // Don't fail invitation redemption if relay sync fails
    }

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Redeemed invitation $inviteCode by invitee $inviteePubkey');
  }

  /// Processes invitation denial when invitee declines
  ///
  /// Validates invite code exists and is pending.
  /// Updates invitation status to denied.
  /// Sends denial event via InvitationSendingService.
  /// Invalidates invitation code.
  Future<void> denyInvitation({
    required String inviteCode,
    String? reason,
  }) async {
    // Validate invite code format first
    if (!isValidInviteCodeFormat(inviteCode)) {
      throw ArgumentError(
        'Invalid invitation code format. The code must be a valid Base64URL string.',
      );
    }

    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      throw InvitationNotFoundException(inviteCode);
    }

    // Validate invitation status
    if (invitation.status == InvitationStatus.redeemed) {
      throw InvitationAlreadyRedeemedException(inviteCode);
    }

    if (invitation.status == InvitationStatus.invalidated) {
      throw InvitationInvalidatedException(
        inviteCode,
        'Invitation has been invalidated',
      );
    }

    if (!invitation.status.canRedeem) {
      throw ArgumentError(
        'Invitation cannot be denied in current status: ${invitation.status}',
      );
    }

    // Update invitation status to denied
    final deniedInvitation = invitation.updateStatus(InvitationStatus.denied);
    await _saveInvitation(deniedInvitation);

    // Send denial event
    try {
      await invitationSendingService.sendDenialEvent(
        inviteCode: inviteCode,
        ownerPubkey: invitation.ownerPubkey,
        relayUrls: invitation.relayUrls,
        reason: reason,
      );
    } catch (e) {
      Log.error('Error sending denial event for invitation $inviteCode', e);
      // Don't fail if event sending fails - invitation is already denied
    }

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info(
      'Denied invitation $inviteCode${reason != null ? ", reason: $reason" : ""}',
    );
  }

  /// Invalidates an invitation (e.g., when invitee removed from backup config)
  ///
  /// Updates invitation status to invalidated.
  /// Sends invalid event via InvitationSendingService if invitee already accepted.
  /// Removes invitation from tracking.
  Future<void> invalidateInvitation({
    required String inviteCode,
    required String reason,
  }) async {
    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      throw InvitationNotFoundException(inviteCode);
    }

    // Update invitation status to invalidated
    final invalidatedInvitation = invitation.updateStatus(
      InvitationStatus.invalidated,
    );
    await _saveInvitation(invalidatedInvitation);

    // If invitation was already redeemed, send invalid event to notify invitee
    if (invitation.status == InvitationStatus.redeemed && invitation.redeemedBy != null) {
      try {
        await invitationSendingService.sendInvitationInvalidEvent(
          inviteCode: inviteCode,
          inviteePubkey: invitation.redeemedBy!,
          relayUrls: invitation.relayUrls,
          reason: reason,
        );
      } catch (e) {
        Log.error('Error sending invalid event for invitation $inviteCode', e);
        // Don't fail if event sending fails
      }
    }

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Invalidated invitation $inviteCode, reason: $reason');
  }

  /// Processes RSVP event received from invitee
  ///
  /// Decrypts event content using NIP-44.
  /// Validates invite code and invitee pubkey.
  /// Updates invitation status to redeemed.
  /// Adds invitee to backup config if not already present.
  /// Updates steward status to "awaiting key".
  Future<void> processRsvpEvent({required Nip01Event event}) async {
    // Validate event kind
    if (event.kind != NostrKind.invitationRsvp.value) {
      throw ArgumentError(
        'Invalid event kind: expected ${NostrKind.invitationRsvp.value}, got ${event.kind}',
      );
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot process RSVP event.');
    }

    // Parse the RSVP data from the unwrapped content (already decrypted by NDK)
    Map<String, dynamic> payload;
    try {
      Log.debug('RSVP event content: ${event.content}');
      payload = json.decode(event.content) as Map<String, dynamic>;
      Log.debug('RSVP event payload keys: ${payload.keys.toList()}');
    } catch (e) {
      Log.error('Error parsing RSVP event JSON', e);
      throw Exception(
        'Failed to parse RSVP event content. The event may be corrupted or encrypted incorrectly: $e',
      );
    }

    // Extract invite code from payload
    final inviteCode = payload['invite_code'] as String?;
    if (inviteCode == null) {
      throw ArgumentError('Missing invite_code in RSVP event payload');
    }

    // Extract invitee pubkey from payload
    final inviteePubkey = payload['invitee_pubkey'] as String?;
    if (inviteePubkey == null || !isValidHexPubkey(inviteePubkey)) {
      throw ArgumentError('Invalid invitee_pubkey in RSVP event payload');
    }

    if (inviteePubkey != event.pubKey) {
      throw ArgumentError(
        'Invitee pubkey mismatch: event pubkey != payload pubkey',
      );
    }

    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      Log.warning('RSVP event received for unknown invitation: $inviteCode');
      return; // Silently ignore if invitation not found
    }

    // Update invitation status to redeemed
    final redeemedInvitation = invitation.updateStatus(
      InvitationStatus.redeemed,
      redeemedBy: inviteePubkey,
      redeemedAt: DateTime.now(),
    );
    await _saveInvitation(redeemedInvitation);

    // Add invitee to backup config if not already present
    // This will update invited stewards or add new ones
    await _addKeyHolderToBackupConfig(
      invitation.vaultId,
      inviteePubkey,
      invitation.inviteeName, // Can be null for received invitations
      invitation.relayUrls, // Pass relay URLs from invitation
      inviteCode: inviteCode, // Pass invite code for matching
    );

    // Also update status to awaitingKey if steward already exists with invited status
    // This handles the case where the steward was added to the backup config
    // but the UI hasn't saved yet
    try {
      final backupConfig = await repository.getBackupConfig(
        invitation.vaultId,
      );
      if (backupConfig != null) {
        final stewardIndex = backupConfig.stewards.indexWhere(
          (steward) => steward.pubkey == inviteePubkey,
        );
        if (stewardIndex != -1) {
          final steward = backupConfig.stewards[stewardIndex];
          if (steward.status == StewardStatus.invited) {
            // Update status to awaitingKey
            final updatedStewards = List<Steward>.from(
              backupConfig.stewards,
            );
            updatedStewards[stewardIndex] = copySteward(
              steward,
              status: StewardStatus.awaitingKey,
            );
            final updatedConfig = copyBackupConfig(
              backupConfig,
              stewards: updatedStewards,
              lastUpdated: DateTime.now(),
            );
            await repository.updateBackupConfig(
              invitation.vaultId,
              updatedConfig,
            );
            Log.info(
              'Updated steward $inviteePubkey status from invited to awaitingKey',
            );
          }
        }
      }
    } catch (e) {
      Log.warning('Error updating steward status after RSVP: $e');
      // Don't fail RSVP processing if status update fails
    }

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info(
      'Processed RSVP event for invitation $inviteCode from invitee $inviteePubkey',
    );
  }

  /// Processes denial event received from invitee
  ///
  /// Decrypts event content using NIP-44.
  /// Validates invite code.
  /// Updates invitation status to denied.
  /// Invalidates invitation code.
  Future<void> processDenialEvent({required Nip01Event event}) async {
    // Validate event kind
    if (event.kind != NostrKind.invitationDenial.value) {
      throw ArgumentError(
        'Invalid event kind: expected ${NostrKind.invitationDenial.value}, got ${event.kind}',
      );
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception('No key pair available. Cannot process denial event.');
    }

    // Parse the denial data from the unwrapped content (already decrypted by NDK)
    Map<String, dynamic> payload;
    try {
      Log.debug('Denial event content: ${event.content}');
      payload = json.decode(event.content) as Map<String, dynamic>;
      Log.debug('Denial event payload keys: ${payload.keys.toList()}');
    } catch (e) {
      Log.error('Error parsing denial event JSON', e);
      throw Exception(
        'Failed to parse denial event content. The event may be corrupted or encrypted incorrectly: $e',
      );
    }

    // Extract invite code from payload
    final inviteCode = payload['invite_code'] as String?;
    if (inviteCode == null) {
      throw ArgumentError('Missing invite_code in denial event payload');
    }

    // Extract invitee pubkey from payload (optional for denial)
    final inviteePubkey = payload['invitee_pubkey'] as String?;
    if (inviteePubkey != null && !isValidHexPubkey(inviteePubkey)) {
      throw ArgumentError('Invalid invitee_pubkey in denial event payload');
    }

    // Load invitation
    final invitation = await _loadInvitation(inviteCode);
    if (invitation == null) {
      Log.warning('Denial event received for unknown invitation: $inviteCode');
      return; // Silently ignore if invitation not found
    }

    // Update invitation status to denied
    final deniedInvitation = invitation.updateStatus(InvitationStatus.denied);
    await _saveInvitation(deniedInvitation);

    // Notify listeners
    _notifyInvitationsChanged();

    Log.info('Processed denial event for invitation $inviteCode');
  }

  // ========== Storage Helper Methods ==========

  /// Save an invitation to SharedPreferences
  Future<void> _saveInvitation(InvitationLink invitation) async {
    final prefs = await SharedPreferences.getInstance();
    final json = invitationLinkToJson(invitation);
    final jsonString = jsonEncode(json);

    await prefs.setString(_invitationKey(invitation.inviteCode), jsonString);
    Log.debug('Saved invitation ${invitation.inviteCode} to SharedPreferences');
  }

  /// Load an invitation from SharedPreferences
  Future<InvitationLink?> _loadInvitation(String inviteCode) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_invitationKey(inviteCode));

    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return invitationLinkFromJson(json);
    } catch (e) {
      Log.error('Error loading invitation $inviteCode', e);
      return null;
    }
  }

  /// Add invite code to vault invitations index
  Future<void> _addToVaultIndex(String vaultId, String inviteCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _vaultInvitationsKey(vaultId);

    final existingCodes = prefs.getStringList(key) ?? [];
    if (!existingCodes.contains(inviteCode)) {
      existingCodes.add(inviteCode);
      await prefs.setStringList(key, existingCodes);
      Log.debug('Added invite code $inviteCode to vault $vaultId index');
    }
  }

  /// Get all invite codes for a vault
  Future<List<String>> _getVaultInviteCodes(String vaultId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _vaultInvitationsKey(vaultId);
    return prefs.getStringList(key) ?? [];
  }

  /// Add a steward to backup config (or create config if it doesn't exist)
  ///
  /// When an RSVP is received:
  /// - If a steward with this pubkey already exists, do nothing
  /// - If a steward with matching inviteCode exists but no pubkey (invited status),
  ///   update it with the pubkey and change status to awaitingKey
  /// - Otherwise, add a new steward
  Future<void> _addKeyHolderToBackupConfig(
    String vaultId,
    String pubkey,
    String? name, // Can be null for received invitations
    List<String> relayUrls, {
    String? inviteCode, // Invite code for matching invited stewards
  }) async {
    var backupConfig = await repository.getBackupConfig(vaultId);

    if (backupConfig == null) {
      // Create new backup config with this steward
      // We'll use default values - owner can adjust later
      final newSteward = createSteward(pubkey: pubkey, name: name);
      backupConfig = createBackupConfig(
        vaultId: vaultId,
        threshold: 1, // Start with 1-of-1, will be updated when more stewards are added
        totalKeys: 1, // Will be updated when more stewards are added
        stewards: [newSteward],
        relays: relayUrls, // Use relay URLs from invitation
      );
      await repository.updateBackupConfig(vaultId, backupConfig);
      Log.info(
        'Created new backup config for vault $vaultId with steward $pubkey',
      );

      // Sync relays from backup config to RelayScanService
      await _syncRelaysFromBackupConfig(backupConfig);
    } else {
      // FIRST: Check if there's an invited steward (no pubkey) with matching invite code
      // This must be checked BEFORE checking for existing pubkey, otherwise we'll miss
      // updating invited stewards when RSVP comes in
      if (inviteCode != null) {
        Log.debug(
          'Looking for invited steward with invite code: "$inviteCode"',
        );

        final invitedStewardIndex = backupConfig.stewards.indexWhere(
          (steward) =>
              steward.inviteCode == inviteCode &&
              steward.pubkey == null &&
              steward.status == StewardStatus.invited,
        );

        if (invitedStewardIndex != -1) {
          // Update the invited steward with pubkey and change status to awaitingKey
          final updatedStewards = List<Steward>.from(
            backupConfig.stewards,
          );
          updatedStewards[invitedStewardIndex] = copySteward(
            updatedStewards[invitedStewardIndex],
            pubkey: pubkey,
            status: StewardStatus.awaitingKey,
            // Keep inviteCode for reference, but it's no longer needed after acceptance
          );

          final updatedConfig = copyBackupConfig(
            backupConfig,
            stewards: updatedStewards,
            lastUpdated: DateTime.now(),
          );
          await repository.updateBackupConfig(vaultId, updatedConfig);
          Log.info(
            'Updated invited steward with invite code "$inviteCode" - added pubkey $pubkey and changed status to awaitingKey',
          );

          // Sync relays from backup config to RelayScanService
          await _syncRelaysFromBackupConfig(updatedConfig);
          return;
        } else {
          Log.debug(
            'No invited steward found with invite code "$inviteCode"',
          );
        }
      } else {
        Log.debug('No invite code provided, skipping invited steward check');
      }

      // SECOND: Check if steward with this pubkey already exists
      final existingByPubkey =
          backupConfig.stewards.where((holder) => holder.pubkey == pubkey).toList();
      if (existingByPubkey.isNotEmpty) {
        // Check if this steward needs status update (e.g., was invited, now accepting)
        final existingHolder = existingByPubkey.first;
        if (existingHolder.status == StewardStatus.invited ||
            existingHolder.status == StewardStatus.awaitingKey ||
            existingHolder.status == StewardStatus.awaitingNewKey) {
          // Status is already appropriate or will be updated elsewhere
          Log.debug(
            'Key holder $pubkey already exists in backup config with status ${existingHolder.status}',
          );
        } else {
          Log.debug('Key holder $pubkey already exists in backup config');
        }
        return;
      }

      // THIRD: Add new steward and update totalKeys
      final newSteward = createSteward(pubkey: pubkey, name: name);
      final updatedStewards = [...backupConfig.stewards, newSteward];
      final updatedConfig = copyBackupConfig(
        backupConfig,
        stewards: updatedStewards,
        totalKeys: updatedStewards.length,
        lastUpdated: DateTime.now(),
      );
      await repository.updateBackupConfig(vaultId, updatedConfig);
      Log.info(
        'Added steward $pubkey to backup config for vault $vaultId',
      );

      // Sync relays from backup config to RelayScanService
      await _syncRelaysFromBackupConfig(updatedConfig);
    }
  }

  /// Sync relays from backup config to RelayScanService and ensure scanning is started
  Future<void> _syncRelaysFromBackupConfig(BackupConfig backupConfig) async {
    if (backupConfig.relays.isEmpty) {
      Log.debug('No relays in backup config to sync');
      return;
    }

    try {
      await _relayScanService.syncRelaysFromUrls(backupConfig.relays);
      await _relayScanService.ensureScanningStarted();
      Log.info(
        'Synced ${backupConfig.relays.length} relay(s) from backup config to RelayScanService',
      );
    } catch (e) {
      Log.error(
        'Error syncing relays from backup config to RelayScanService',
        e,
      );
      // Don't fail the operation if relay sync fails
    }
  }

  /// Add an invited steward placeholder to the backup config
  ///
  /// This is called when an invitation is generated, before the invitee has accepted.
  /// It creates a steward with null pubkey and invited status, which will be
  /// updated when the RSVP is received.
  Future<void> _addInvitedKeyHolderToBackupConfig({
    required String vaultId,
    required String inviteCode,
    required String inviteeName,
    required List<String> relayUrls,
  }) async {
    var backupConfig = await repository.getBackupConfig(vaultId);

    // Create the invited steward
    final invitedSteward = createInvitedSteward(
      name: inviteeName,
      inviteCode: inviteCode,
    );

    if (backupConfig == null) {
      // Create new backup config with just this invited steward
      backupConfig = createBackupConfig(
        vaultId: vaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [invitedSteward],
        relays: relayUrls,
      );
      await repository.updateBackupConfig(vaultId, backupConfig);
      Log.info(
        'Created backup config with invited steward for $inviteeName',
      );
    } else {
      // Check if this invite code already exists (avoid duplicates)
      final existingWithCode =
          backupConfig.stewards.where((holder) => holder.inviteCode == inviteCode).toList();

      if (existingWithCode.isNotEmpty) {
        Log.info(
          'Invited steward with invite code $inviteCode already exists, skipping',
        );
        return;
      }

      // Add the invited steward
      final updatedStewards = [...backupConfig.stewards, invitedSteward];
      final updatedConfig = copyBackupConfig(
        backupConfig,
        stewards: updatedStewards,
        totalKeys: updatedStewards.length,
        relays: relayUrls.isNotEmpty ? relayUrls : backupConfig.relays,
        lastUpdated: DateTime.now(),
      );
      await repository.updateBackupConfig(vaultId, updatedConfig);
      Log.info(
        'Added invited steward for $inviteeName to existing backup config',
      );

      // Sync relays from updated backup config
      await _syncRelaysFromBackupConfig(updatedConfig);
    }
  }

  /// Add relay URLs to NDK service so we can receive RSVP events
  ///
  /// This is called when an invitation is generated to ensure the owner
  /// is listening on the relays where the invitee will send RSVP events.
  Future<void> _addRelaysToNdk(List<String> relayUrls) async {
    try {
      final ndkService = _getNdkService();
      for (final relayUrl in relayUrls) {
        try {
          await ndkService.addRelay(relayUrl);
          Log.info('Added relay to NDK for invitation listening: $relayUrl');
        } catch (e) {
          Log.warning('Failed to add relay $relayUrl to NDK: $e');
          // Continue with other relays even if one fails
        }
      }
    } catch (e) {
      Log.error('Error accessing NDK service to add relays', e);
      // Don't fail invitation generation if relay addition fails
    }
  }
}
