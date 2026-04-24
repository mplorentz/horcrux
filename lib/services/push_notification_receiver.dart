import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_navigator.dart';
import '../firebase_options.dart';
import '../screens/vault_detail_screen.dart';
import 'horcrux_notification_service.dart';
import 'local_notification_service.dart';
import 'logger.dart';
import 'ndk_service.dart';

final pushNotificationReceiverProvider = Provider<PushNotificationReceiver>((ref) {
  final localNotifications = ref.watch(localNotificationServiceProvider);
  final notifierService = ref.watch(horcruxNotificationServiceProvider);
  final ndkService = ref.watch(ndkServiceProvider);
  final receiver = PushNotificationReceiver(
    localNotifications: localNotifications,
    notifierService: notifierService,
    ndkService: ndkService,
  );
  ref.onDispose(() => receiver.dispose());
  return receiver;
});

/// Device-side FCM plumbing for receiving push notifications:
///
/// - Requests notification permission on iOS/macOS (Android handled by [LocalNotificationService])
/// - Fetches and caches the FCM device token in [SharedPreferences]
/// - Listens for token refreshes
/// - Wires foreground / background-tap / cold-start-tap handlers
///
/// Does NOT talk to horcrux-notifier directly -- that is the job of
/// `HorcruxNotificationService`. This class limits itself to what the device
/// does with pushes that arrive from FCM.
class PushNotificationReceiver {
  /// Whether the user has opted into push notifications.
  ///
  /// Read at app startup from `main()` to decide whether to initialize
  /// Firebase. Flipped to `true` by [optIn] and `false` by [optOut]. When
  /// absent, treated as `false` -- users incur zero Firebase / FCM footprint
  /// until they opt in.
  static const optInFlagKey = 'push_notifications_opted_in';

  static const _fcmTokenKey = 'fcm_device_token';
  static const _fcmTokenUpdatedAtKey = 'fcm_device_token_updated_at';
  static const _registeredFcmTokenKey = 'fcm_registered_token';

  final LocalNotificationService _localNotifications;
  final HorcruxNotificationService _notifierService;
  final NdkService _ndkService;

  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  String? _cachedToken;
  String? _lastRegisteredToken;
  bool _initialized = false;

  PushNotificationReceiver({
    required LocalNotificationService localNotifications,
    required HorcruxNotificationService notifierService,
    required NdkService ndkService,
  })  : _localNotifications = localNotifications,
        _notifierService = notifierService,
        _ndkService = ndkService;

  /// Most recently known FCM device token, or `null` if one hasn't been obtained yet.
  String? get token => _cachedToken;

  /// Whether push notifications are supported on this platform. Currently FCM
  /// supports Android, iOS, macOS, and web -- not Linux or Windows.
  static bool get isSupported {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  /// Returns whether the user has globally opted into push notifications.
  Future<bool> isOptedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(optInFlagKey) ?? false;
  }

  /// Global push opt-in flow.
  ///
  /// Initializes Firebase lazily, requests permission, obtains an FCM token,
  /// registers this device with horcrux-notifier, and syncs consent state.
  /// Returns `true` on success, `false` if permission is denied or setup fails.
  Future<bool> optIn() async {
    if (!isSupported) {
      Log.info('PushNotificationReceiver: push unsupported on this platform');
      return false;
    }

    try {
      await _ensureFirebaseInitialized();
      await _initializeMessaging();

      final messaging = _messaging;
      if (messaging == null) {
        Log.warning('PushNotificationReceiver: messaging unavailable after init');
        return false;
      }

      final granted = await _localNotifications.requestPlatformNotificationPermissions();
      if (!granted) {
        Log.info('PushNotificationReceiver: notification permission not granted');
        return false;
      }

      await _fetchAndStoreToken();
      await _registerWithNotifierIfNeeded(force: true);
      await _notifierService.syncConsentList();
      await _setOptInFlag(true);
      await _processLaunchNotificationIfAny();
      Log.info('PushNotificationReceiver: user opted in to push notifications');
      return true;
    } catch (e, st) {
      Log.warning('PushNotificationReceiver: optIn failed', e, st);
      return false;
    }
  }

  /// Global push opt-out flow.
  ///
  /// Best-effort deregisters with horcrux-notifier and then clears all local
  /// FCM state regardless of network conditions.
  Future<void> optOut() async {
    try {
      await _notifierService.deregister();
    } catch (e, st) {
      Log.warning('PushNotificationReceiver: notifier deregister failed', e, st);
    }

    try {
      final messaging = _messaging;
      if (messaging != null) {
        await messaging.deleteToken();
      }
    } catch (e, st) {
      Log.warning('PushNotificationReceiver: failed to delete FCM token', e, st);
    }

    await _clearPersistedTokenState();
    await _setOptInFlag(false);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    await _openedAppSubscription?.cancel();
    _openedAppSubscription = null;
    _cachedToken = null;
    _lastRegisteredToken = null;
    _initialized = false;

    Log.info('PushNotificationReceiver: user opted out of push notifications');
  }

  /// Startup path for push initialization.
  ///
  /// No-ops unless the global opt-in flag is set. Keeps token/registration
  /// current across launches.
  Future<void> maybeInitialize() async {
    if (!isSupported) return;
    if (!await isOptedIn()) return;

    try {
      await _ensureFirebaseInitialized();
      await _initializeMessaging();
      await _fetchAndStoreToken();
      await _registerWithNotifierIfNeeded();
      await _processLaunchNotificationIfAny();
    } catch (e, st) {
      Log.warning('PushNotificationReceiver: maybeInitialize failed', e, st);
    }
  }

  Future<void> initialize() async {
    await maybeInitialize();
  }

  Future<void> _initializeMessaging() async {
    if (_initialized) return;
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e, st) {
      Log.warning(
        'PushNotificationReceiver: Firebase not initialized, skipping FCM init',
        e,
        st,
      );
      return;
    }

    await _loadCachedToken();
    _subscribeToTokenRefreshes();
    _subscribeToForegroundMessages();
    _subscribeToNotificationOpens();
    _initialized = true;
    Log.info('PushNotificationReceiver initialized');
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  Future<void> _loadCachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_fcmTokenKey);
      _lastRegisteredToken = prefs.getString(_registeredFcmTokenKey);
      if (_cachedToken != null) {
        Log.debug('Loaded cached FCM token from SharedPreferences');
      }
    } catch (e, st) {
      Log.warning('Failed to load cached FCM token', e, st);
    }
  }

  Future<void> _fetchAndStoreToken() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      // On iOS/macOS getToken returns null until APNs has been registered, so
      // we ensure APNs token availability first.
      if (Platform.isIOS || Platform.isMacOS) {
        final apns = await messaging.getAPNSToken();
        if (apns == null) {
          Log.warning(
            'APNs token not yet available; FCM token will be fetched after APNs registration',
          );
        }
      }

      final fcmToken = await messaging.getToken();
      if (fcmToken == null) {
        Log.warning('FCM getToken() returned null');
        return;
      }
      await _persistToken(fcmToken);
      _logTokenForTesting(fcmToken);
    } catch (e, st) {
      Log.warning('Failed to fetch FCM token', e, st);
    }
  }

  Future<void> _persistToken(String fcmToken) async {
    if (fcmToken == _cachedToken) return;
    _cachedToken = fcmToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, fcmToken);
      await prefs.setString(
        _fcmTokenUpdatedAtKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e, st) {
      Log.warning('Failed to persist FCM token to SharedPreferences', e, st);
    }
  }

  void _subscribeToTokenRefreshes() {
    final messaging = _messaging;
    if (messaging == null) return;
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
      (fcmToken) async {
        Log.info('FCM token refreshed');
        await _persistToken(fcmToken);
        await _registerWithNotifierIfNeeded();
        _logTokenForTesting(fcmToken);
      },
      onError: (Object error, StackTrace stackTrace) {
        Log.warning('FCM onTokenRefresh error', error, stackTrace);
      },
    );
  }

  Future<void> _registerWithNotifierIfNeeded({bool force = false}) async {
    final token = _cachedToken;
    if (token == null || token.isEmpty) return;

    final platform = NotifierPlatform.currentDevice();
    if (platform == null) {
      Log.info(
        'PushNotificationReceiver: notifier registration skipped on unsupported platform',
      );
      return;
    }

    if (!force && token == _lastRegisteredToken) return;

    await _notifierService.register(fcmToken: token, platform: platform);
    _lastRegisteredToken = token;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_registeredFcmTokenKey, token);
    } catch (e, st) {
      Log.warning('Failed to persist registered FCM token', e, st);
    }
  }

  Future<void> _setOptInFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(optInFlagKey, value);
  }

  Future<void> _clearPersistedTokenState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);
      await prefs.remove(_fcmTokenUpdatedAtKey);
      await prefs.remove(_registeredFcmTokenKey);
    } catch (e, st) {
      Log.warning('Failed to clear persisted FCM token state', e, st);
    }
  }

  void _subscribeToForegroundMessages() {
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        unawaited(_onForegroundRemoteMessage(message));
      },
      onError: (Object error, StackTrace stackTrace) {
        Log.warning('FCM onMessage error', error, stackTrace);
      },
    );
  }

  void _subscribeToNotificationOpens() {
    if (_messaging == null) return;
    _openedAppSubscription?.cancel();
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        unawaited(_onPushNotificationOpened(message));
      },
      onError: (Object error, StackTrace stackTrace) {
        Log.warning('FCM onMessageOpenedApp error', error, stackTrace);
      },
    );
  }

  /// Cold-start: user opened the app by tapping a notification.
  Future<void> _processLaunchNotificationIfAny() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        await _onPushNotificationOpened(initial);
      }
    } catch (e, st) {
      Log.warning('PushNotificationReceiver: getInitialMessage failed', e, st);
    }
  }

  Future<void> _onPushNotificationOpened(RemoteMessage message) async {
    Log.info(
      'FCM notification open: messageId=${message.messageId}, data=${message.data}',
    );

    Nip01Event? giftWrap;
    final embedded = parseFcmEmbeddedEventJson(message.data);
    if (embedded != null) {
      try {
        giftWrap = Nip01Event.fromJson(embedded);
      } catch (e, st) {
        Log.warning('FCM tap: invalid embedded event_json', e, st);
        return;
      }
    } else {
      final eventId = parseFcmEventId(message.data);
      if (eventId == null || eventId.isEmpty) {
        Log.warning('FCM tap: no event_json and no event_id');
        return;
      }
      final hints = parseFcmRelayHints(message.data);
      giftWrap = await _ndkService.fetchGiftWrapByIdForPush(
        eventIdHex: eventId,
        relayHints: hints,
      );
      if (giftWrap == null) {
        Log.warning('FCM tap: could not fetch gift wrap for $eventId');
        return;
      }
    }

    final vaultId = await _ndkService.resolveVaultIdForGiftWrap(giftWrap);
    try {
      await _ndkService.processGiftWrapFromForegroundPush(giftWrap);
    } catch (e, st) {
      Log.warning('FCM tap: gift wrap processing failed', e, st);
    }
    if (vaultId != null) {
      await _navigateToVaultWhenReady(vaultId);
    }
  }

  Future<void> _navigateToVaultWhenReady(String vaultId) async {
    for (var i = 0; i < 40; i++) {
      final nav = navigatorKey.currentState;
      if (nav != null && nav.mounted) {
        await nav.push(
          MaterialPageRoute<void>(
            builder: (context) => VaultDetailScreen(vaultId: vaultId),
          ),
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    Log.warning('FCM tap: navigator not ready; skipped navigation to vault $vaultId');
  }

  /// Handles a push that arrives while the app is foregrounded.
  ///
  /// iOS/macOS suppress the OS notification display when the app is in the
  /// foreground, so the user only sees a notification if we surface one
  /// ourselves. We rely on the normal NDK pipeline to do that: the embedded
  /// gift wrap is routed through [NdkService.processGiftWrapFromForegroundPush]
  /// and its per-kind handlers call into [LocalNotificationService] to emit a
  /// live notification (liveness-gated to ignore relay backfill). This keeps
  /// foreground FCM deliveries aligned with relay-delivered events and avoids
  /// double-notifying.
  ///
  /// No fallback notification is shown here — if the pipeline decides not to
  /// notify for this event (e.g. deduped, historical, or a kind we don't
  /// surface), the push stays silent in the foreground.
  Future<void> _onForegroundRemoteMessage(RemoteMessage message) async {
    Log.info(
      'FCM foreground message received: messageId=${message.messageId}, '
      'data=${message.data}, '
      'notification=${message.notification?.title}/${message.notification?.body}',
    );

    final embedded = parseFcmEmbeddedEventJson(message.data);
    if (embedded != null) {
      try {
        final event = Nip01Event.fromJson(embedded);
        await _ndkService.processGiftWrapFromForegroundPush(event);
      } catch (e, st) {
        Log.warning(
          'FCM foreground: failed to process embedded gift wrap',
          e,
          st,
        );
      }
    } else if (kDebugMode) {
      unawaited(
        _localNotifications.showNotification(
          title: 'FCM data message',
          body: 'Received ${message.data}',
          payload: 'fcm_test',
        ),
      );
    }
  }

  /// Logs the FCM token in a highly visible format so it's easy to copy out of
  /// the debug console and paste into Firebase Cloud Messaging test tools.
  void _logTokenForTesting(String fcmToken) {
    final banner = '=' * 80;
    // ignore: avoid_print
    debugPrint('\n$banner\nFCM DEVICE TOKEN:\n$fcmToken\n$banner\n');
    Log.info('FCM device token obtained (length=${fcmToken.length})');
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    _openedAppSubscription?.cancel();
    _openedAppSubscription = null;
  }
}

/// Parses inline `event_json` from FCM [RemoteMessage.data].
///
/// Mobile FCM delivers all data values as JSON strings; some environments may
/// expose decoded maps. Returns `null` when absent or not decodable as a JSON
/// object (id-only pushes omit this until the tap handler fetches the event).
@visibleForTesting
Map<String, dynamic>? parseFcmEmbeddedEventJson(Map<String, dynamic> data) {
  final raw = data['event_json'];
  if (raw == null) return null;
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return null;
}

/// Parses `event_id` (hex) from FCM [RemoteMessage.data] for id-only pushes.
@visibleForTesting
String? parseFcmEventId(Map<String, dynamic> data) {
  final raw = data['event_id'];
  if (raw == null) return null;
  final s = raw is String ? raw : raw.toString();
  return s.isEmpty ? null : s;
}

/// Parses `relay_hints` as a JSON array or list of relay URLs.
@visibleForTesting
List<String>? parseFcmRelayHints(Map<String, dynamic> data) {
  final raw = data['relay_hints'];
  if (raw == null) return null;
  if (raw is List) {
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {}
  }
  return null;
}
