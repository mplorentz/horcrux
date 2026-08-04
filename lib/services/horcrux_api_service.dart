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

/// The account record stored on horcrux-api, keyed by the user's npub.
///
/// This is the system of record for PII (email) and consent preferences
/// (analytics opt-in, mailing list). It is deliberately NOT published to
/// public Nostr.
class Account {
  /// The user's public key as a 32-byte hex string (the `npub_hex` field).
  final String npubHex;

  /// Contact email, or `null` if the user hasn't provided one.
  final String? email;

  /// Whether the user opted in to analytics collection. Defaults to `false`.
  final bool analyticsOptIn;

  /// Whether the user subscribed to the product-updates mailing list.
  final bool mailingList;

  /// The last Terms of Service version the user accepted, or `null`.
  final int? tosVersion;

  /// When the Terms of Service were last accepted, or `null`.
  final DateTime? tosAcceptedAt;

  const Account({
    required this.npubHex,
    this.email,
    this.analyticsOptIn = false,
    this.mailingList = false,
    this.tosVersion,
    this.tosAcceptedAt,
  });

  /// Parses an account record from the horcrux-api JSON response shape.
  ///
  /// See [HorcruxApiService] class docs for the wire format.
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      npubHex: json['npub_hex'] as String? ?? '',
      email: json['email'] as String?,
      analyticsOptIn: json['analytics_opt_in'] as bool? ?? false,
      mailingList: json['mailing_list'] as bool? ?? false,
      tosVersion: json['tos_version'] as int?,
      tosAcceptedAt: json['tos_accepted_at'] != null
          ? DateTime.tryParse(json['tos_accepted_at'] as String)
          : null,
    );
  }
}

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
/// Handles authenticated (NIP-98) requests to the horcrux-api server,
/// covering the ToS acceptance and account (email, analytics opt-in,
/// mailing-list) endpoints.
///
/// ## Endpoints
///
/// | Method | Path | Auth | Description |
/// |--------|------|------|-------------|
/// | POST | `/tos/accept` | NIP-98 | Record acceptance of a ToS version |
/// | PUT | `/account` | NIP-98 | Upsert email, analytics opt-in, mailing-list |
/// | GET | `/account` | NIP-98 | Read the signer's own account record |
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
  // Account endpoints
  // ---------------------------------------------------------------------------

  /// Reads the current user's account record from the horcrux-api server.
  ///
  /// Requires NIP-98 auth. The caller must have a Nostr key pair loaded.
  /// Returns the [Account] parsed from the server response. Throws
  /// [HorcruxApiException] on failure.
  Future<Account> getAccount() async {
    final keyPair = await _loginService.getStoredNostrKey();
    if (keyPair == null) {
      throw const HorcruxApiException(
        statusCode: 0,
        message: 'No Nostr key available; cannot authenticate with horcrux-api',
      );
    }

    final base = await getBaseUrl();
    final url = Uri.parse('$base/account');

    final authHeader = Nip98Auth.buildAuthorizationHeader(
      keyPair: keyPair,
      method: 'GET',
      url: url,
    );

    final response = await _httpClient
        .get(url, headers: {'Authorization': authHeader})
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final account = Account.fromJson(json);
      Log.info('HorcruxApiService: fetched account for npub ${account.npubHex}');
      return account;
    }

    throw HorcruxApiException(
      statusCode: response.statusCode,
      message: 'Failed to fetch account: HTTP ${response.statusCode}',
    );
  }

  /// Upserts the current user's account preferences on the horcrux-api server.
  ///
  /// Requires NIP-98 auth. The caller must have a Nostr key pair loaded.
  ///
  /// - [email]: contact email, or `null` to clear it.
  /// - [analyticsOptIn]: whether the user opted in to analytics (required).
  /// - [mailingList]: whether the user subscribed to product updates
  ///   (defaults to `false`).
  ///
  /// Returns silently on success. Throws [HorcruxApiException] on failure.
  Future<void> updateAccount({
    String? email,
    required bool analyticsOptIn,
    bool mailingList = false,
  }) async {
    final keyPair = await _loginService.getStoredNostrKey();
    if (keyPair == null) {
      throw const HorcruxApiException(
        statusCode: 0,
        message: 'No Nostr key available; cannot authenticate with horcrux-api',
      );
    }

    final base = await getBaseUrl();
    final url = Uri.parse('$base/account');
    final body = utf8.encode(jsonEncode(<String, dynamic>{
      'email': email,
      'analytics_opt_in': analyticsOptIn,
      'mailing_list': mailingList,
    }));

    final authHeader = Nip98Auth.buildAuthorizationHeader(
      keyPair: keyPair,
      method: 'PUT',
      url: url,
      body: body,
    );

    final response = await _httpClient
        .put(
          url,
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(_requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Log.info(
          'HorcruxApiService: account updated (analytics=$analyticsOptIn, mailingList=$mailingList)');
      return;
    }

    throw HorcruxApiException(
      statusCode: response.statusCode,
      message: 'Failed to update account: HTTP ${response.statusCode}',
    );
  }

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