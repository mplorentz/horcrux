import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../models/terms_of_service.dart';
import '../providers/key_provider.dart';
import '../utils/nip98_auth.dart';
import 'login_service.dart';
import 'logger.dart';

/// Provider for [HorcruxApiService].
final horcruxApiServiceProvider = Provider<HorcruxApiService>((ref) {
  final loginService = ref.watch(loginServiceProvider);
  final database = ref.watch(appDatabaseProvider);
  final service = HorcruxApiService(
    loginService: loginService,
    database: database,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Structured error raised when the horcrux-api returns a non-2xx response
/// (or the transport layer fails).
class HorcruxApiException implements Exception {
  final int statusCode;
  final String message;
  final Object? cause;

  const HorcruxApiException({
    required this.statusCode,
    required this.message,
    this.cause,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isUnprocessable => statusCode == 422;
  bool get isTransport => statusCode == 0;

  @override
  String toString() => 'HorcruxApiException($statusCode): $message';
}

/// Client for the operator-run horcrux-api service.
///
/// Handles all authenticated (NIP-98) and unauthenticated requests to the
/// horcrux-api server. Currently provides ToS endpoints; will be extended
/// with account (email, analytics opt-in) endpoints in subsequent beads.
///
/// ## Endpoints
///
/// | Method | Path | Auth | Description |
/// |--------|------|------|-------------|
/// | POST | `/tos/accept` | NIP-98 | Record acceptance of a ToS version |
///
/// The ToS/Privacy Policy text itself is bundled with the app (see
/// [TermsOfService]) rather than fetched from the server, so onboarding
/// doesn't depend on API reachability.
///
/// ## Base URL
///
/// - Debug builds → `https://dev-api.horcruxbackup.com`
/// - Release builds → `https://api.horcruxbackup.com`
///
/// The server URL can be overridden in the Drift `kv` table under
/// [baseUrlPrefsKey] (e.g. for tests or local development).
class HorcruxApiService {
  /// Default API URL. Debug builds use the dev server; release builds use
  /// production.
  static String get defaultBaseUrl =>
      kDebugMode ? 'https://dev-api.horcruxbackup.com' : 'https://api.horcruxbackup.com';

  /// Drift `kv` key for a user-overridden base URL. When present, overrides
  /// [defaultBaseUrl]; when absent or empty, the default is used.
  static const String baseUrlPrefsKey = 'horcrux_api_base_url';

  /// Drift `kv` key for the last accepted ToS version.
  static const String tosAcceptedVersionKey = 'tos_accepted_version';

  /// Request timeout for API calls.
  static const Duration _requestTimeout = Duration(seconds: 15);

  final LoginService _loginService;
  final AppDatabase _database;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  HorcruxApiService({
    required LoginService loginService,
    required AppDatabase database,
    http.Client? httpClient,
  })  : _loginService = loginService,
        _database = database,
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  // ---------------------------------------------------------------------------
  // ToS endpoints
  // ---------------------------------------------------------------------------

  /// Records acceptance of the given [tosVersion] against the current user's
  /// npub on the horcrux-api server.
  ///
  /// Requires NIP-98 auth. The caller must have a Nostr key pair loaded.
  ///
  /// Returns silently on success. Throws [HorcruxApiException] on failure.
  Future<void> acceptTermsOfService(int tosVersion) async {
    final keyPair = await _loginService.getStoredNostrKey();
    if (keyPair == null) {
      throw const HorcruxApiException(
        statusCode: 0,
        message: 'No Nostr key available; cannot authenticate with horcrux-api',
      );
    }

    final base = await getBaseUrl();
    final url = Uri.parse('$base/tos/accept');
    final body = utf8.encode(jsonEncode(<String, dynamic>{'tos_version': tosVersion}));

    final authHeader = Nip98Auth.buildAuthorizationHeader(
      keyPair: keyPair,
      method: 'POST',
      url: url,
      body: body,
    );

    final response = await _httpClient
        .post(
          url,
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Persist the accepted version locally so we know not to re-prompt.
      await _storeAcceptedVersion(tosVersion);
      Log.info('HorcruxApiService: ToS v$tosVersion accepted');
      return;
    }

    throw HorcruxApiException(
      statusCode: response.statusCode,
      message: 'Failed to accept Terms of Service: HTTP ${response.statusCode}',
    );
  }

  /// Returns the last locally-accepted ToS version, or `null` if the user has
  /// never accepted the ToS (e.g. fresh install, upgrade from pre-ToS version).
  Future<int?> getLastAcceptedVersion() async {
    return _database.appStateDao.getInt(tosAcceptedVersionKey);
  }

  /// Checks whether the user needs to accept the current ToS version.
  ///
  /// Returns `true` if the user has never accepted the ToS (no stored
  /// version), or if [kCurrentTosVersion] is greater than the last accepted
  /// version. Purely local — the ToS text and version are bundled with the
  /// app, so this never depends on network reachability.
  Future<bool> needsConsentAcceptance() async {
    final accepted = await getLastAcceptedVersion();
    if (accepted == null) {
      return true; // Never accepted
    }
    return kCurrentTosVersion > accepted;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Resolved base URL. Honors a persisted override when set, otherwise falls
  /// back to [defaultBaseUrl]. Trailing slashes are trimmed.
  Future<String> getBaseUrl() async {
    final override = await _database.appStateDao.getString(baseUrlPrefsKey);
    final trimmed = override?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return _stripTrailingSlash(trimmed);
    }
    return _stripTrailingSlash(defaultBaseUrl);
  }

  Future<void> _storeAcceptedVersion(int version) async {
    await _database.appStateDao.setInt(
      key: tosAcceptedVersionKey,
      value: version,
    );
  }

  static String _stripTrailingSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  /// Closes the underlying [http.Client] if this service owns it.
  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
