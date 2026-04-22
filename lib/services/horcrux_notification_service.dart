import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/key_provider.dart';
import '../utils/nip98_auth.dart';
import 'login_service.dart';
import 'logger.dart';

/// Provider for [HorcruxNotificationService].
///
/// A single instance is kept for the app lifetime; it owns an [http.Client]
/// that is closed on dispose.
final horcruxNotificationServiceProvider = Provider<HorcruxNotificationService>((ref) {
  final loginService = ref.watch(loginServiceProvider);
  final service = HorcruxNotificationService(loginService: loginService);
  ref.onDispose(service.dispose);
  return service;
});

/// Platforms the notifier knows how to dispatch to (FCM/APNs).
///
/// The server rejects anything else. macOS, web, Linux, and Windows are not
/// currently supported on the push-delivery side.
enum NotifierPlatform {
  android,
  ios;

  /// Wire value written to the `platform` field in [POST /register].
  String get wire => switch (this) {
        NotifierPlatform.android => 'android',
        NotifierPlatform.ios => 'ios',
      };

  /// Best-effort platform detection for the current device. Returns `null`
  /// on platforms the notifier does not support, so callers can surface a
  /// "push not supported on this OS" error instead of guessing.
  static NotifierPlatform? currentDevice() {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return NotifierPlatform.android;
    if (Platform.isIOS) return NotifierPlatform.ios;
    return null;
  }
}

/// Structured error raised when `horcrux-notifier` returns a non-2xx response
/// (or the transport layer fails).
///
/// The server encodes error bodies as `{"error": "<message>"}`; the message
/// is surfaced verbatim when decodable.
class HorcruxNotifierException implements Exception {
  /// HTTP status code returned by the notifier, or `0` if the request never
  /// reached a response (network failure, DNS error, etc.).
  final int statusCode;

  /// Human-readable description. Prefer the server-supplied `error` field
  /// when present, otherwise a short transport-layer summary.
  final String message;

  /// Underlying transport error, if any.
  final Object? cause;

  const HorcruxNotifierException({
    required this.statusCode,
    required this.message,
    this.cause,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;

  /// `true` when no HTTP response was ever received (DNS, socket, TLS, etc.).
  bool get isTransport => statusCode == 0;

  @override
  String toString() => 'HorcruxNotifierException($statusCode): $message';
}

/// Single client for ALL interaction with the `horcrux-notifier` server.
///
/// Responsibilities:
///
/// - **Transport + auth** -- every request is stamped with a NIP-98
///   `Authorization: Nostr <base64>` header signed by the current user's
///   Nostr key. See [Nip98Auth].
/// - **Registration lifecycle** -- [register], [deregister], [updateToken].
///   Called by `PushNotificationReceiver` on opt-in/out/token refresh.
/// - **Consent endpoints** -- [replaceConsents], [deleteConsent]. The
///   higher-level "derive the allowlist from vault relationships and sync"
///   helper lives in a later change.
/// - **Push triggering** -- [push]. The higher-level `tryPushForEvent` that
///   composes personalized text and embeds the gift-wrap event lives in a
///   later change.
///
/// The server URL defaults to [defaultBaseUrl] and can be overridden by the
/// user via settings (persisted to [SharedPreferences] under
/// [baseUrlPrefsKey]). Each HTTP method is small and explicit so future
/// tests can mock individual endpoints.
class HorcruxNotificationService {
  /// Default production notifier URL.
  static const String defaultBaseUrl = 'https://dev-notifier.horcruxbackup.com';

  /// [SharedPreferences] key for a user-overridden base URL. When present,
  /// overrides [defaultBaseUrl]; when absent or empty, the default is used.
  static const String baseUrlPrefsKey = 'horcrux_notifier_base_url';

  static const Duration _requestTimeout = Duration(seconds: 15);

  final LoginService _loginService;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  HorcruxNotificationService({
    required LoginService loginService,
    http.Client? httpClient,
  })  : _loginService = loginService,
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  /// Resolved base URL for notifier requests. Honors the user's override
  /// when set, otherwise falls back to [defaultBaseUrl]. Trailing slashes
  /// are trimmed so [Uri.parse] composition is predictable.
  Future<String> getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString(baseUrlPrefsKey)?.trim();
      if (override != null && override.isNotEmpty) {
        return _stripTrailingSlash(override);
      }
    } catch (e, st) {
      Log.warning(
        'HorcruxNotificationService: failed to read baseUrl override, '
        'falling back to default',
        e,
        st,
      );
    }
    return _stripTrailingSlash(defaultBaseUrl);
  }

  /// Persists a user-supplied override for the base URL.
  ///
  /// Passing `null` or an empty string clears the override (reverting to
  /// [defaultBaseUrl]). The value is not validated beyond stripping
  /// whitespace; callers should verify it parses as a URL before saving.
  Future<void> setBaseUrl(String? override) async {
    final prefs = await SharedPreferences.getInstance();
    final value = override?.trim();
    if (value == null || value.isEmpty) {
      await prefs.remove(baseUrlPrefsKey);
    } else {
      await prefs.setString(baseUrlPrefsKey, value);
    }
  }

  // ---------------------------------------------------------------------------
  // Registration lifecycle
  // ---------------------------------------------------------------------------

  /// Registers (or upserts) the current device with the notifier.
  ///
  /// - [fcmToken]: Firebase Cloud Messaging device token obtained via
  ///   `FirebaseMessaging.instance.getToken()`.
  /// - [platform]: the device platform. Use
  ///   [NotifierPlatform.currentDevice] to derive it.
  ///
  /// The notifier keys the device by the caller's Nostr pubkey (from
  /// NIP-98); a second call with a different token silently replaces the
  /// old one.
  Future<void> register({
    required String fcmToken,
    required NotifierPlatform platform,
  }) async {
    if (fcmToken.trim().isEmpty) {
      throw ArgumentError.value(fcmToken, 'fcmToken', 'must not be empty');
    }
    await _sendJson(
      method: 'POST',
      path: '/register',
      body: <String, dynamic>{
        'device_token': fcmToken,
        'platform': platform.wire,
      },
    );
    Log.info('HorcruxNotificationService: device registered (${platform.wire})');
  }

  /// Removes the caller's device from the notifier. Returns silently if the
  /// device was already absent (the server's 404 is swallowed here -- a
  /// deregister is idempotent from the caller's perspective).
  Future<void> deregister() async {
    try {
      await _send(method: 'DELETE', path: '/register');
      Log.info('HorcruxNotificationService: device deregistered');
    } on HorcruxNotifierException catch (e) {
      if (e.isNotFound) {
        Log.info(
          'HorcruxNotificationService: deregister -- nothing to remove',
        );
        return;
      }
      rethrow;
    }
  }

  /// Convenience wrapper for FCM token refreshes. The notifier upserts on
  /// POST /register, so a token rotation is just a fresh [register] call.
  Future<void> updateToken({
    required String newToken,
    required NotifierPlatform platform,
  }) =>
      register(fcmToken: newToken, platform: platform);

  // ---------------------------------------------------------------------------
  // Consent list management
  //
  // Called from the higher-level consent sync (coming in `p4-consent-sync`).
  // Exposed directly for now so that layer can be small and testable.
  // ---------------------------------------------------------------------------

  /// Replaces the caller's consent allowlist with [authorizedSenders].
  ///
  /// Each entry must be a 64-character hex pubkey; the server rejects the
  /// whole request otherwise. The list is deduped and normalized server-side.
  Future<void> replaceConsents(List<String> authorizedSenders) async {
    await _sendJson(
      method: 'PUT',
      path: '/consent',
      body: <String, dynamic>{'authorized_senders': authorizedSenders},
    );
    Log.info(
      'HorcruxNotificationService: consent list replaced '
      '(${authorizedSenders.length} senders)',
    );
  }

  /// Syncs the consent allowlist to the notifier.
  ///
  /// Full derivation from vault relationships is implemented in `p4-consent-sync`.
  /// For now this keeps the opt-in flow stable and explicitly performs no network
  /// mutation.
  Future<void> syncConsentList() async {
    Log.debug(
      'HorcruxNotificationService: syncConsentList is not yet wired to relationship derivation',
    );
  }

  /// Removes a single sender from the caller's consent allowlist.
  ///
  /// Treats 404 as success (the entry was already absent).
  Future<void> deleteConsent(String senderPubkey) async {
    try {
      await _send(
        method: 'DELETE',
        path: '/consent/${Uri.encodeComponent(senderPubkey)}',
      );
      Log.info('HorcruxNotificationService: consent deleted for sender');
    } on HorcruxNotifierException catch (e) {
      if (e.isNotFound) return;
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Push triggering
  //
  // The higher-level `tryPushForEvent` that composes text and embeds the
  // gift wrap lives in `p4-push-trigger`. This method is the raw HTTP layer.
  // ---------------------------------------------------------------------------

  /// Triggers an FCM/APNs push to [recipientPubkey] via the notifier.
  ///
  /// Exactly one of [eventJson] or [eventId] must be provided (the server
  /// enforces this). When both are absent or both present, the server
  /// rejects the request with 400.
  ///
  /// - [title], [body]: notification text shown by the OS.
  /// - [eventJson]: full gift-wrap event as a JSON-serializable map. Kept
  ///   under 3 KB by the caller (server caps at 3072 bytes).
  /// - [eventId]: 64-char hex event id, used when the gift wrap is too
  ///   large to embed.
  /// - [relayHints]: relay URLs the recipient can use to fetch [eventId].
  Future<void> push({
    required String recipientPubkey,
    required String title,
    required String body,
    Map<String, dynamic>? eventJson,
    String? eventId,
    List<String>? relayHints,
  }) async {
    final payload = <String, dynamic>{
      'recipient_pubkey': recipientPubkey,
      'title': title,
      'body': body,
    };
    if (eventJson != null) payload['event_json'] = eventJson;
    if (eventId != null) payload['event_id'] = eventId;
    if (relayHints != null && relayHints.isNotEmpty) {
      payload['relay_hints'] = relayHints;
    }
    await _sendJson(method: 'POST', path: '/push', body: payload);
  }

  // ---------------------------------------------------------------------------
  // Internal transport
  // ---------------------------------------------------------------------------

  /// Builds the `Authorization` header, fires the request, and maps
  /// non-2xx responses to [HorcruxNotifierException]. Returns the decoded
  /// response body as a [Map] when present, or `null` for 204 responses.
  Future<Map<String, dynamic>?> _sendJson({
    required String method,
    required String path,
    required Map<String, dynamic> body,
  }) {
    final bodyBytes = utf8.encode(jsonEncode(body));
    return _send(
      method: method,
      path: path,
      bodyBytes: bodyBytes,
      contentType: 'application/json',
    );
  }

  Future<Map<String, dynamic>?> _send({
    required String method,
    required String path,
    List<int>? bodyBytes,
    String? contentType,
  }) async {
    final keyPair = await _loginService.getStoredNostrKey();
    if (keyPair == null) {
      throw const HorcruxNotifierException(
        statusCode: 0,
        message: 'No Nostr key available; cannot authenticate with notifier',
      );
    }

    final base = await getBaseUrl();
    final url = Uri.parse('$base$path');

    final authHeader = Nip98Auth.buildAuthorizationHeader(
      keyPair: keyPair,
      method: method,
      url: url,
      body: bodyBytes,
    );

    final headers = <String, String>{'Authorization': authHeader};
    if (contentType != null) headers['Content-Type'] = contentType;

    final request = http.Request(method, url)..headers.addAll(headers);
    if (bodyBytes != null) request.bodyBytes = bodyBytes;

    http.StreamedResponse streamed;
    try {
      streamed = await _httpClient.send(request).timeout(_requestTimeout);
    } catch (e) {
      throw HorcruxNotifierException(
        statusCode: 0,
        message: 'Notifier request failed: $e',
        cause: e,
      );
    }

    final response = await http.Response.fromStream(streamed);
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (response.bodyBytes.isEmpty) return null;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) return decoded;
        return null;
      } catch (_) {
        // Non-JSON body on success is unexpected but not fatal for the
        // caller; we only return structured data.
        return null;
      }
    }

    throw HorcruxNotifierException(
      statusCode: status,
      message: _extractErrorMessage(response) ?? 'HTTP $status',
    );
  }

  static String? _extractErrorMessage(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Non-JSON body: fall through.
    }
    final raw = response.body.trim();
    return raw.isEmpty ? null : raw;
  }

  static String _stripTrailingSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  /// Closes the underlying [http.Client] if this service owns it.
  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
