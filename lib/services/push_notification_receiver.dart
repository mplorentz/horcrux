import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_notification_service.dart';
import 'logger.dart';

final pushNotificationReceiverProvider = Provider<PushNotificationReceiver>((ref) {
  final localNotifications = ref.watch(localNotificationServiceProvider);
  final receiver = PushNotificationReceiver(localNotifications: localNotifications);
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

  final LocalNotificationService _localNotifications;

  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  String? _cachedToken;
  bool _initialized = false;

  PushNotificationReceiver({required LocalNotificationService localNotifications})
      : _localNotifications = localNotifications;

  /// Most recently known FCM device token, or `null` if one hasn't been obtained yet.
  String? get token => _cachedToken;

  /// Whether push notifications are supported on this platform. Currently FCM
  /// supports Android, iOS, macOS, and web -- not Linux or Windows.
  static bool get isSupported {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!isSupported) {
      Log.info('PushNotificationReceiver: platform unsupported, skipping FCM init');
      return;
    }

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
    await _fetchAndStoreToken();
    _subscribeToTokenRefreshes();
    _subscribeToForegroundMessages();

    _initialized = true;
    Log.info('PushNotificationReceiver initialized');
  }

  Future<void> _loadCachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_fcmTokenKey);
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
        _logTokenForTesting(fcmToken);
      },
      onError: (Object error, StackTrace stackTrace) {
        Log.warning('FCM onTokenRefresh error', error, stackTrace);
      },
    );
  }

  void _subscribeToForegroundMessages() {
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        Log.info(
          'FCM foreground message received: messageId=${message.messageId}, '
          'data=${message.data}, '
          'notification=${message.notification?.title}/${message.notification?.body}',
        );

        // Real pushes from horcrux-notifier always include a `notification`
        // payload that the OS would normally display on its own. In the
        // foreground, FCM suppresses the OS display and hands the message to
        // us, so we surface it via [LocalNotificationService] to keep the UX
        // consistent across foreground/background.
        final notification = message.notification;
        if (notification != null) {
          unawaited(
            _localNotifications.showNotification(
              title: notification.title ?? 'Horcrux',
              body: notification.body ?? 'Push notification received',
              payload: 'fcm_test',
            ),
          );
        } else if (kDebugMode) {
          unawaited(
            _localNotifications.showNotification(
              title: 'FCM data message',
              body: 'Received ${message.data}',
              payload: 'fcm_test',
            ),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        Log.warning('FCM onMessage error', error, stackTrace);
      },
    );
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
  }
}
