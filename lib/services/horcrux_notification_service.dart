import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/nostr_kinds.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../utils/push_notification_text.dart';
import '../utils/validators.dart';
import '../utils/nip98_auth.dart';
import 'login_service.dart';
import 'logger.dart';
import 'push_notification_receiver.dart';

/// Provider for [HorcruxNotificationService].
///
/// A single instance is kept for the app lifetime; it owns an [http.Client]
/// that is closed on dispose.
final horcruxNotificationServiceProvider = Provider<HorcruxNotificationService>((ref) {
  final loginService = ref.watch(loginServiceProvider);
  final vaultRepository = ref.watch(vaultRepositoryProvider);
  final service = HorcruxNotificationService(
    loginService: loginService,
    vaultRepository: vaultRepository,
  );
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
/// - **Push triggering** -- [tryPushForEvent] is the high-level entry
///   point: it checks opt-in/vault preferences, composes personalized
///   text, embeds the gift wrap (or just its id when too large), and
///   POSTs `/push`. [push] is the raw HTTP layer.
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
  static const String _consentSnapshotPrefsKey = 'horcrux_notifier_last_synced_consents';
  static const Duration _consentDebounce = Duration(milliseconds: 700);

  static const Duration _requestTimeout = Duration(seconds: 15);

  /// Upper bound (in UTF-8 bytes) on the serialized gift wrap JSON we embed
  /// inline on `/push`. Matches the notifier's hard cap on `event_json` and
  /// leaves headroom inside the FCM data payload (~4 KB total budget) for
  /// the surrounding envelope. Anything larger degrades to `event_id` +
  /// `relay_hints` so the recipient can fetch on tap.
  static const int maxEmbeddedEventBytes = 3072;

  final LoginService _loginService;
  final VaultRepository _vaultRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  StreamSubscription<List<Vault>>? _vaultsSubscription;
  Timer? _consentDebounceTimer;
  bool _syncInFlight = false;
  bool _syncQueued = false;

  HorcruxNotificationService({
    required LoginService loginService,
    required VaultRepository vaultRepository,
    http.Client? httpClient,
  })  : _loginService = loginService,
        _vaultRepository = vaultRepository,
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null {
    _startConsentSyncSubscriptions();
  }

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

  /// Derives the consent allowlist from current Horcrux relationships.
  ///
  /// For every vault the user participates in (owned or stewarded) we
  /// authorize pushes from:
  /// - the vault owner (unless that's us), and
  /// - every co-steward of the vault (excluding us).
  ///
  /// On the owner's side co-stewards come from `backupConfig.stewards`. On
  /// the steward's side the local vault stub usually doesn't carry a
  /// backup config, so we fall back to the `stewards` list that the owner
  /// piggybacks onto each shard payload (see [ShardData.stewards], which
  /// already excludes the creator).
  ///
  /// This is symmetric on purpose: any steward -- not just the owner --
  /// can originate a recovery request, so every co-steward of a shared
  /// vault needs to be allowed to push us.
  ///
  /// Pending invitations are intentionally excluded. We don't learn the
  /// invitee's pubkey until they accept, at which point they appear in
  /// the vault's steward list and the vault stream triggers a resync.
  ///
  /// Returns deduped, lower-cased, sorted pubkeys.
  List<String> computeConsentList({
    required String currentUserPubkey,
    required List<Vault> vaults,
  }) {
    final self = currentUserPubkey.trim().toLowerCase();
    final senders = <String>{};

    void add(String? raw) {
      if (raw == null) return;
      final pk = raw.trim().toLowerCase();
      if (pk.isEmpty || pk == self) return;
      if (!isValidHexPubkey(pk)) return;
      senders.add(pk);
    }

    for (final vault in vaults) {
      add(vault.ownerPubkey);

      for (final steward in vault.backupConfig?.stewards ?? const []) {
        add(steward.pubkey);
      }

      final coStewards = vault.mostRecentShard?.stewards;
      if (coStewards != null) {
        for (final entry in coStewards) {
          add(entry['pubkey']);
        }
      }
    }

    final result = senders.toList()..sort();
    return result;
  }

  /// Syncs the derived consent allowlist to notifier if it has changed.
  Future<void> syncConsentList() async {
    if (!await _isPushOptedIn()) {
      Log.debug('HorcruxNotificationService: skipping consent sync (push not opted in)');
      return;
    }

    final currentPubkey = await _loginService.getCurrentPublicKey();
    if (currentPubkey == null || !isValidHexPubkey(currentPubkey)) {
      Log.warning('HorcruxNotificationService: cannot sync consents without a valid pubkey');
      return;
    }

    final vaults = await _vaultRepository.getAllVaults();
    final computed = computeConsentList(
      currentUserPubkey: currentPubkey,
      vaults: vaults,
    );
    final lastSynced = await _loadLastSyncedConsentSnapshot();
    if (_sameConsentSet(computed, lastSynced)) {
      Log.debug('HorcruxNotificationService: consent list unchanged, skipping PUT /consent');
      return;
    }

    await replaceConsents(computed);
    await _storeLastSyncedConsentSnapshot(computed);
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
  // ---------------------------------------------------------------------------

  /// Best-effort push trigger for a freshly-published gift wrap event.
  ///
  /// Called from every gift-wrap publish site in the app (backup shard
  /// distribution, recovery request, recovery response, shard confirmation).
  /// The method is safe to fire-and-forget: it silently returns when push
  /// isn't applicable and swallows every error from the notifier. The event
  /// itself is already on Nostr, so a missed push is a UX degradation, not
  /// a correctness failure.
  ///
  /// [event] is the signed gift wrap returned by
  /// [NdkService.publishEncryptedEvent]; we forward it to the notifier
  /// as-is and derive the recipient pubkey from its `p` tag.
  ///
  /// [kind] is the *inner rumor* kind (e.g. [NostrKind.shardData]), not the
  /// gift wrap's outer kind (which is always 1059). The inner kind lives
  /// inside the NIP-59-encrypted seal, so it can't be recovered from the
  /// gift wrap without the recipient's key — callers have to pass it.
  ///
  /// The flow:
  ///
  /// 1. Bail if [vault].pushEnabled is false (owner opted this vault out).
  /// 2. Bail if the user hasn't globally opted in to push.
  /// 3. Resolve the current user as the notification sender (the outer gift
  ///    wrap pubkey is ephemeral per NIP-59, so we use the signer's real
  ///    pubkey to drive display-name resolution).
  /// 4. Compose personalized `{title, body}` via [composeNotificationText].
  ///    If the helper returns `null` for this [kind], we don't push.
  /// 5. Serialize the event. If the JSON fits under [maxEmbeddedEventBytes]
  ///    we embed it inline so the recipient can unwrap the event from the
  ///    push payload without hitting a relay. Otherwise we attach only the
  ///    event id + relay hints; the client will fetch on tap.
  /// 6. POST `/push`. 4xx/5xx responses are logged and dropped.
  ///
  /// [recoveryApproved] is only meaningful for
  /// [NostrKind.recoveryResponse]; pass `null` for every other kind.
  Future<void> tryPushForEvent({
    required Nip01Event event,
    required NostrKind kind,
    required Vault vault,
    List<String>? relayHints,
    bool? recoveryApproved,
  }) async {
    if (!vault.pushEnabled) {
      Log.debug('HorcruxNotificationService: skipping push (vault.pushEnabled=false)');
      return;
    }
    if (!await _isPushOptedIn()) {
      Log.debug('HorcruxNotificationService: skipping push (user not opted in)');
      return;
    }

    // Recipient lives in the gift wrap's `p` tag (NIP-59).
    final recipientPubkey = _extractRecipientPubkey(event);
    if (recipientPubkey == null) {
      Log.warning(
        'HorcruxNotificationService: skipping push (gift wrap missing `p` tag)',
      );
      return;
    }

    final senderPubkey = await _loginService.getCurrentPublicKey();
    if (senderPubkey == null || !isValidHexPubkey(senderPubkey)) {
      Log.debug('HorcruxNotificationService: skipping push (no current pubkey)');
      return;
    }

    final text = composeNotificationText(
      kind: kind,
      vault: vault,
      senderPubkey: senderPubkey,
      recoveryApproved: recoveryApproved,
    );
    if (text == null) {
      Log.debug('HorcruxNotificationService: no push text for kind ${kind.value}');
      return;
    }

    final eventJson = event.toJson();
    final encodedBytes = utf8.encode(jsonEncode(eventJson)).length;
    final embedInline = encodedBytes <= maxEmbeddedEventBytes;

    try {
      await push(
        recipientPubkey: recipientPubkey,
        title: text.title,
        body: text.body,
        eventJson: embedInline ? eventJson : null,
        eventId: embedInline ? null : event.id,
        relayHints: embedInline ? null : relayHints,
      );
      Log.info(
        'HorcruxNotificationService: pushed kind ${kind.value} '
        '(${embedInline ? 'inline' : 'id-only'}) to recipient',
      );
    } catch (e, st) {
      // Best-effort: swallow everything. The event is already live on
      // Nostr, so a missed push is non-fatal.
      Log.warning('HorcruxNotificationService: tryPushForEvent failed', e, st);
    }
  }

  /// Reads the first `p` tag off a gift wrap (the NIP-59 recipient pubkey).
  /// Returns null when absent or malformed; callers treat that as "skip push".
  static String? _extractRecipientPubkey(Nip01Event event) {
    for (final tag in event.tags) {
      if (tag.length >= 2 && tag[0] == 'p') {
        final value = tag[1];
        if (isValidHexPubkey(value)) return value;
      }
    }
    return null;
  }

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
    _consentDebounceTimer?.cancel();
    _consentDebounceTimer = null;
    _vaultsSubscription?.cancel();
    _vaultsSubscription = null;
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  void _startConsentSyncSubscriptions() {
    _vaultsSubscription = _vaultRepository.vaultsStream.listen(
      (_) => _scheduleConsentSync(),
      onError: (Object error, StackTrace stackTrace) {
        Log.warning('HorcruxNotificationService: vault stream error', error, stackTrace);
      },
    );
  }

  void _scheduleConsentSync() {
    _consentDebounceTimer?.cancel();
    _consentDebounceTimer = Timer(_consentDebounce, () {
      unawaited(_runSyncWithCoalescing());
    });
  }

  Future<void> _runSyncWithCoalescing() async {
    if (_syncInFlight) {
      _syncQueued = true;
      return;
    }
    _syncInFlight = true;
    try {
      do {
        _syncQueued = false;
        await syncConsentList();
      } while (_syncQueued);
    } catch (e, st) {
      Log.warning('HorcruxNotificationService: consent sync failed', e, st);
    } finally {
      _syncInFlight = false;
    }
  }

  Future<bool> _isPushOptedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(PushNotificationReceiver.optInFlagKey) ?? false;
    } catch (e, st) {
      Log.warning('HorcruxNotificationService: failed to read push opt-in flag', e, st);
      return false;
    }
  }

  Future<List<String>> _loadLastSyncedConsentSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_consentSnapshotPrefsKey) ?? const <String>[];
      final normalized = raw
          .map((e) => e.trim().toLowerCase())
          .where((e) => isValidHexPubkey(e))
          .toSet()
          .toList()
        ..sort();
      return normalized;
    } catch (e, st) {
      Log.warning('HorcruxNotificationService: failed reading consent snapshot', e, st);
      return const <String>[];
    }
  }

  Future<void> _storeLastSyncedConsentSnapshot(List<String> senders) async {
    final normalized = senders.map((e) => e.trim().toLowerCase()).toSet().toList()..sort();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_consentSnapshotPrefsKey, normalized);
    } catch (e, st) {
      Log.warning('HorcruxNotificationService: failed persisting consent snapshot', e, st);
    }
  }

  bool _sameConsentSet(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
