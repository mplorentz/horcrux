import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/invitation_service.dart';
import '../services/logger.dart';
import '../utils/validators.dart';
import '../models/invitation_exceptions.dart';
import '../screens/invitation_acceptance_screen.dart';

/// Provider for DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(ref.read(invitationServiceProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

/// Data structure for parsed invitation link information
typedef InvitationLinkData = ({
  String inviteCode,
  String vaultId,
  String? vaultName,
  String ownerPubkey, // Hex format
  List<String> relayUrls,
});

/// Service for handling deep links, Universal Links, and custom URL schemes
class DeepLinkService {
  final InvitationService invitationService;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  DeepLinkService(this.invitationService);

  /// Sets the navigator key for navigation
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Disposes resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  /// Initializes deep link handling when app starts
  ///
  /// Sets up app_links listeners.
  /// Handles initial link (app opened via link).
  /// Sets up stream listener for subsequent links.
  /// Supports both Universal Links and custom URL scheme.
  Future<void> initializeDeepLinking() async {
    Log.info('Initializing deep link handling');

    // Handle initial link (app opened via link on cold start)
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        Log.info('App opened via deep link: $initialLink');
        await _processLink(initialLink);
      }
    } catch (e) {
      Log.error('Error handling initial link', e);
    }

    // Set up listener for incoming links (app already running)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        Log.info('Received deep link while app running: $uri');
        _processLink(uri);
      },
      onError: (error) {
        Log.error('Error in deep link stream', error);
      },
    );

    Log.info('Deep link handling initialized');
  }

  /// Handles link that opened the app (cold start)
  ///
  /// Retrieves initial link from app_links.
  /// Parses and validates link format.
  /// Routes to appropriate handler.
  Future<void> handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        Log.info('Handling initial link: $initialLink');
        await _processLink(initialLink);
      }
    } catch (e) {
      Log.error('Error handling initial link', e);
      rethrow;
    }
  }

  /// Handles link received while app is running (warm start)
  ///
  /// Parses link URL.
  /// Validates link format.
  /// Routes to invitation acceptance flow.
  void handleIncomingLink(Uri uri) {
    Log.info('Handling incoming link: $uri');
    _processLink(uri);
  }

  /// Processes a deep link URI
  ///
  /// Parses the link and routes to appropriate handler.
  /// Currently only handles invitation links.
  Future<void> _processLink(Uri uri) async {
    // Check if this looks like an invitation link before attempting to parse
    // Silently ignore non-invitation URLs (e.g., root path on web startup)
    if (uri.pathSegments.isEmpty ||
        (uri.pathSegments.isNotEmpty && uri.pathSegments[0] != 'invite')) {
      Log.debug('Ignoring non-invitation URL: $uri');
      return;
    }

    try {
      final linkData = parseInvitationLink(uri);
      if (linkData == null) {
        Log.warning('Invalid invitation link format: $uri');
        _showErrorToUser('Invalid invitation link format');
        return;
      }

      Log.info(
        'Parsed invitation link: inviteCode=${linkData.inviteCode}, vaultId=${linkData.vaultId}, vaultName=${linkData.vaultName}',
      );

      // Create/update invitation record on receiving side
      // This allows the invitation acceptance screen to load the invitation
      await invitationService.createReceivedInvitation(
        inviteCode: linkData.inviteCode,
        vaultId: linkData.vaultId,
        ownerPubkey: linkData.ownerPubkey,
        relayUrls: linkData.relayUrls,
        vaultName: linkData.vaultName,
      );

      // Navigate to invitation acceptance screen
      if (_navigatorKey?.currentContext != null) {
        Navigator.of(_navigatorKey!.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => InvitationAcceptanceScreen(inviteCode: linkData.inviteCode),
          ),
        );
        Log.info('Navigated to invitation acceptance screen');
      } else {
        Log.warning(
          'Navigator key not set, cannot navigate to invitation screen',
        );
        _showErrorToUser('Unable to open invitation. Please try again.');
      }
    } on InvalidInvitationLinkException catch (e) {
      Log.error('Invalid invitation link: $uri', e);
      _showErrorToUser(e.reason);
    } catch (e) {
      Log.error('Error processing deep link', e);
      _showErrorToUser('Failed to process invitation link: $e');
    }
  }

  /// Shows an error message to the user via a snackbar or dialog
  void _showErrorToUser(String message) {
    if (_navigatorKey?.currentContext != null) {
      final context = _navigatorKey!.currentContext!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Parses invitation link URL and extracts parameters
  ///
  /// Handles both Universal Links (`https://horcrux.app/invite/{code}`)
  /// and custom URL scheme (`horcrux://horcrux.app/invite/{code}`) formats.
  /// Extracts invite code from path (same path structure for both).
  /// Extracts owner pubkey and relay URLs from query params.
  /// Returns parsed data or throws InvalidInvitationLinkException if invalid.
  InvitationLinkData? parseInvitationLink(Uri uri) {
    try {
      // Validate scheme: https or horcrux
      if (uri.scheme != 'https' && uri.scheme != 'horcrux' && uri.scheme != 'http') {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'Unsupported URL scheme: ${uri.scheme}. Expected https:// or horcrux://',
        );
      }

      // Validate host: horcrux.app (for Universal Links) or horcrux.app (for custom scheme)
      // Allow localhost for testing on web
      final allowedHosts = ['horcrux.app', 'localhost'];
      if (!allowedHosts.contains(uri.host)) {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'Invalid host: ${uri.host}. Expected horcrux.app',
        );
      }

      // Extract invite code from path: /invite/{code}
      final pathSegments = uri.pathSegments;
      if (pathSegments.length != 2 || pathSegments[0] != 'invite') {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'Invalid path format: ${uri.path}. Expected format: /invite/{code}',
        );
      }

      final inviteCode = pathSegments[1];
      if (!isValidInviteCode(inviteCode)) {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'Invalid invite code format: $inviteCode',
        );
      }

      // Extract owner pubkey from query params
      final ownerPubkey = uri.queryParameters['owner'];
      if (ownerPubkey == null || ownerPubkey.isEmpty) {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'Missing required parameter: owner (pubkey)',
        );
      }

      if (!isValidHexPubkey(ownerPubkey)) {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'Invalid owner pubkey format: $ownerPubkey (must be 64 hex characters)',
        );
      }

      // Extract vaultId from query params
      final vaultId = uri.queryParameters['vault'];
      if (vaultId == null || vaultId.isEmpty) {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'Missing required parameter: vault (vault ID)',
        );
      }

      // Extract vault name from query params (optional)
      final vaultName = uri.queryParameters['name'];
      // Decode if present, otherwise use null (will fallback to defaultVaultName in createInvitationLink)

      // Extract relay URLs from query params (comma-separated)
      final relayUrlsParam = uri.queryParameters['relays'];
      final relayUrls = <String>[];

      if (relayUrlsParam != null && relayUrlsParam.isNotEmpty) {
        // Split by comma and decode each URL
        final relayUrlStrings = relayUrlsParam.split(',');
        for (final relayUrlStr in relayUrlStrings) {
          final decodedUrl = Uri.decodeComponent(relayUrlStr.trim());
          if (isValidRelayUrl(decodedUrl)) {
            relayUrls.add(decodedUrl);
          } else {
            Log.warning('Invalid relay URL: $decodedUrl');
            // Continue processing other URLs, but log the invalid one
          }
        }
      }

      // Validate we have at least one relay URL
      if (relayUrls.isEmpty) {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'No valid relay URLs found. At least one relay URL is required.',
        );
      }

      // Validate we don't have too many relay URLs (max 3)
      if (relayUrls.length > 3) {
        throw InvalidInvitationLinkException(
          uri.toString(),
          'Too many relay URLs: ${relayUrls.length} (maximum 3 allowed)',
        );
      }

      Log.info(
        'Successfully parsed invitation link: inviteCode=$inviteCode, vaultId=$vaultId, vaultName=$vaultName, owner=$ownerPubkey, relays=${relayUrls.length}',
      );

      return (
        inviteCode: inviteCode,
        vaultId: vaultId,
        vaultName:
            vaultName != null && vaultName.isNotEmpty ? Uri.decodeComponent(vaultName) : null,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );
    } on InvalidInvitationLinkException {
      rethrow;
    } catch (e) {
      Log.error('Error parsing invitation link: $uri', e);
      throw InvalidInvitationLinkException(
        uri.toString(),
        'Failed to parse invitation link: $e',
      );
    }
  }
}
