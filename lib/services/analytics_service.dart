import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import 'logger.dart';

/// Riverpod provider for [AnalyticsService].
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = AnalyticsService(database: db);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Chokepoint for all PostHog product analytics calls.
///
/// Every PostHog API call in the app flows through this service. It enforces:
///
/// - **Consent gate**: capture/screenView are no-ops when the user has not
///   opted in, or when the build is debug (`kDebugMode`).
/// - **PII boundary**: No call site receives raw vault ids, npubs, names, or
///   content — use [vaultHash] to derive a non-identifying identifier.
///
/// ## Lifecycle
///
/// 1. `setup()` is called once during app initialization. It reads the cached
///    `analytics_opt_in` from the drift kv table and initializes PostHog only
///    if the user has opted in. Debug builds skip all PostHog init.
/// 2. `identify(npubBech32)` is called after login.
/// 3. `capture()` / `screenView()` are called throughout the app.
/// 4. `reset()` is called on logout / account switch.
/// 5. `dispose()` calls PostHog close.
class AnalyticsService {
  final AppDatabase _database;
  bool _optedIn = false;
  bool _initialized = false;

  AnalyticsService({required AppDatabase database}) : _database = database;

  /// Drift kv key for the cached analytics opt-in boolean.
  static const String analyticsOptInKey = 'analytics_opt_in';

  /// Drift kv key for the last account refresh timestamp (epoch ms).
  static const String accountRefreshedAtKey = 'account_refreshed_at';

  static const String _posthogProjectKey = 'phc_NvxeaSVRpqhbjdusQCxVD7mftTpZtQNMXpMBLPLy12B';
  static const String _posthogHost = 'https://eu.i.posthog.com';

  /// Whether the analytics service is currently opted in.
  bool get isOptedIn => _optedIn;

  /// Initializes PostHog if the user has opted into analytics.
  ///
  /// Reads the cached [analyticsOptInKey] from the drift kv table. If `true`,
  /// calls [Posthog.setup] with the project key and host. Always a no-op in
  /// debug builds.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops if already
  /// initialized or in the correct state.
  Future<void> setup() async {
    if (kDebugMode) {
      Log.info('[Analytics] Debug build — PostHog not initialized');
      return;
    }

    final cachedOptIn = await _getCachedOptIn();
    if (cachedOptIn == true) {
      _initializePosthog();
    }
  }

  /// Initializes the PostHog SDK with project configuration.
  void _initializePosthog() {
    if (_initialized) return;

    final config = PostHogConfig(_posthogProjectKey);
    config.host = _posthogHost;
    // No session replay, error tracking, or autocapture in this bead.
    config.sessionReplay = false;
    config.captureApplicationLifecycleEvents = false;
    config.capturePushNotificationSubscriptions = false;
    Posthog().setup(config);
    _initialized = true;
    _optedIn = true;
    Log.info('[Analytics] PostHog initialized');
  }

  /// Tears down PostHog and resets the state.
  void _teardownPosthog() {
    if (_initialized) {
      Posthog().reset();
      Posthog().close();
      _initialized = false;
    }
    _optedIn = false;
    Log.info('[Analytics] PostHog torn down');
  }

  /// Associates events with a specific user.
  ///
  /// [npubBech32] is the user's bech32 npub (npub1...). Called after PostHog
  /// setup, once the npub is known.
  ///
  /// No-op in debug builds or when not opted in.
  Future<void> identify(String npubBech32) async {
    if (!_shouldEmit()) return;
    await Posthog().identify(userId: npubBech32);
    Log.info('[Analytics] Identified user');
  }

  /// Resets the current user identity.
  ///
  /// Called on logout / account switch. No-op in debug builds.
  Future<void> reset() async {
    if (kDebugMode || !_initialized) return;
    await Posthog().reset();
    Log.info('[Analytics] Reset user identity');
  }

  /// Captures a custom event.
  ///
  /// [event] is the event name (e.g. `vault_created`). [properties] are
  /// optional event properties — must not contain PII (raw vault ids, npubs,
  /// names, or content). Use [vaultHash] for vault identifiers.
  ///
  /// No-op in debug builds or when the user has not opted in.
  Future<void> capture(String event, {Map<String, Object>? properties}) async {
    if (!_shouldEmit()) return;
    await Posthog().capture(eventName: event, properties: properties);
    Log.debug('[Analytics] Captured: $event');
  }

  /// Captures a screen view event.
  ///
  /// [screen] is the screen name (typically the widget class name). [properties]
  /// are optional extra properties (for consent screen, includes
  /// `analytics_opted_in`).
  ///
  /// No-op in debug builds or when the user has not opted in.
  Future<void> screenView(String screen, {Map<String, Object>? properties}) async {
    if (!_shouldEmit()) return;
    final props = <String, Object>{'screen': screen};
    if (properties != null) {
      props.addAll(properties);
    }
    await Posthog().capture(eventName: 'screen_viewed', properties: props);
    Log.debug('[Analytics] Screen viewed: $screen');
  }

  /// Returns a non-identifying vault hash for analytics.
  ///
  /// Uses SHA-256 truncated to the first 16 hex characters. This is
  /// deterministic and one-way — never send raw vault ids to PostHog.
  static String vaultHash(String vaultId) {
    final bytes = utf8.encode(vaultId);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Synchronizes the opt-in state after a fresh account fetch.
  ///
  /// Compares [newOptIn] with the current [_optedIn]. If different, either
  /// initializes or tears down PostHog at runtime. Called from the fire-and-
  /// forget account refresh flow.
  Future<void> syncOptIn(bool newOptIn) async {
    if (kDebugMode) {
      _optedIn = false;
      _teardownPosthog();
      return;
    }

    if (newOptIn && !_optedIn) {
      await _setCachedOptIn(true);
      _initializePosthog();
    } else if (!newOptIn && _optedIn) {
      await _setCachedOptIn(false);
      _teardownPosthog();
    }
    // No-op if unchanged.
  }

  /// Reads the cached opt-in value from the drift kv table.
  Future<bool?> _getCachedOptIn() async {
    try {
      final raw = await _database.appStateDao.getBool(analyticsOptInKey);
      return raw;
    } catch (e, st) {
      Log.warning('[Analytics] Failed to read cached opt-in', e, st);
      return null;
    }
  }

  Future<void> _setCachedOptIn(bool value) async {
    try {
      await _database.appStateDao.setBool(key: analyticsOptInKey, value: value);
    } catch (e, st) {
      Log.warning('[Analytics] Failed to cache opt-in', e, st);
    }
  }

  /// Returns true if analytics calls should be emitted.
  bool _shouldEmit() => !kDebugMode && _optedIn && _initialized;

  /// Cleans up the PostHog SDK.
  void dispose() {
    _teardownPosthog();
  }
}

/// A [NavigatorObserver] that fires `screen_viewed` events through
/// [AnalyticsService].
///
/// Wired into `MaterialApp.navigatorObservers` in [main.dart]. On every push
/// or replace, extracts the route name from [RouteSettings.name] and calls
/// [AnalyticsService.screenView]. Skips `didPop` (covered by the next push).
///
/// Route names are set via `settings: RouteSettings(name: 'WidgetClassName')`
/// on each `MaterialPageRoute` call site.
class RouteAnalyticsObserver extends NavigatorObserver {
  late AnalyticsService _analyticsService;
  bool _initialized = false;

  /// Initializes the observer with a reference to [AnalyticsService].
  ///
  /// Called from [main.dart] after the provider is available.
  void init(AnalyticsService analyticsService) {
    _analyticsService = analyticsService;
    _initialized = true;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _sendScreenView(newRoute);
    }
  }

  void _sendScreenView(Route<dynamic> route) {
    if (!_initialized) return;
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;

    Map<String, Object>? properties;
    // If route settings has extra data, look for analytics properties.
    final settings = route.settings;
    if (settings.arguments is Map<String, Object?>) {
      final args = settings.arguments as Map<String, Object?>;
      if (args.containsKey('analytics_properties')) {
        final rawProps = args['analytics_properties'];
        if (rawProps is Map<String, Object>) {
          properties = rawProps;
        }
      }
    }

    _analyticsService.screenView(name, properties: properties);
  }
}
