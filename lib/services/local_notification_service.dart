import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/recovery_request.dart';
import '../providers/vault_provider.dart';
import '../utils/nostr_display.dart';
import 'logger.dart';
import 'ndk_service.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  final ndkService = ref.watch(ndkServiceProvider);
  final vaultRepository = ref.watch(vaultRepositoryProvider);
  final service = LocalNotificationService(
    ndkService: ndkService,
    vaultRepository: vaultRepository,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Service that displays OS notifications to the user for things like recovery requests.
class LocalNotificationService {
  final NdkService _ndkService;
  final VaultRepository _vaultRepository;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  StreamSubscription<RecoveryRequest>? _recoveryRequestSub;
  StreamSubscription<RecoveryResponseEvent>? _recoveryResponseSub;

  static const _channelId = 'horcrux_notifications';
  static const _channelName = 'Horcrux Notifications';
  static const _channelDescription = 'Notifications for vault events like recovery requests.';

  int _notificationCounter = 0;

  LocalNotificationService({
    required NdkService ndkService,
    required VaultRepository vaultRepository,
  })  : _ndkService = ndkService,
        _vaultRepository = vaultRepository;

  /// Android notification ids are 32-bit signed. [millisecondsSinceEpoch] alone does not fit,
  /// so we use the same bits as appending `"$ms$counter"` then folding into 31 positive bits.
  int _notificationIdFromEpochAndCounter() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final c = ++_notificationCounter;
    return '$ms$c'.hashCode & 0x7fffffff;
  }

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPlatformNotificationPermissions();

    _subscribeToEvents();
    Log.info('LocalNotificationService initialized');
  }

  /// Asks the OS for permission to show notifications.
  ///
  /// - **Android 13+:** `POST_NOTIFICATIONS` runtime dialog via the plugin. On older Android,
  ///   notifications are allowed by default (result may be null).
  /// - **iOS / macOS:** Requests alert, badge, and sound via the plugin.
  Future<void> _requestPlatformNotificationPermissions() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    if (androidGranted != null) {
      Log.info('Android POST_NOTIFICATIONS granted: $androidGranted');
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) {
      Log.info('iOS notification permissions granted: $iosGranted');
    }

    final macOS =
        _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    final macGranted = await macOS?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (macGranted != null) {
      Log.info('macOS notification permissions granted: $macGranted');
    }
  }

  void _subscribeToEvents() {
    _recoveryRequestSub = _ndkService.recoveryRequestStream.listen(_onRecoveryRequest);
    _recoveryResponseSub = _ndkService.recoveryResponseStream.listen(_onRecoveryResponse);
  }

  void _onRecoveryRequest(RecoveryRequest request) {
    unawaited(_showRecoveryRequestNotification(request));
  }

  Future<void> _showRecoveryRequestNotification(RecoveryRequest request) async {
    Log.info(
      'Showing notification for recovery request: ${request.id}',
    );
    final vault = await _vaultRepository.getVault(request.vaultId);
    final vaultName = vault?.name ?? 'a vault';
    final requester = displayNameFromPubkey(vault, request.initiatorPubkey);
    await showNotification(
      title: 'Recovery request',
      body: '$requester is requesting your key to vault "$vaultName".',
      payload: 'recovery_request:${request.id}',
    );
  }

  void _onRecoveryResponse(RecoveryResponseEvent response) {
    unawaited(_showRecoveryResponseNotification(response));
  }

  Future<void> _showRecoveryResponseNotification(RecoveryResponseEvent response) async {
    final status = response.approved ? 'approved' : 'denied';
    Log.info(
      'Showing notification for recovery response ($status): ${response.recoveryRequestId}',
    );
    final vault = await _vaultRepository.getVault(response.vaultId);
    final vaultName = vault?.name ?? 'your vault';
    final steward = displayNameFromPubkey(vault, response.senderPubkey);
    final body = response.approved
        ? '$steward approved recovery of "$vaultName".'
        : '$steward denied recovery of "$vaultName".';
    await showNotification(
      title: 'Recovery response',
      body: body,
      payload: 'recovery_response:${response.recoveryRequestId}',
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      _notificationIdFromEpochAndCounter(),
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    Log.info('Notification tapped with payload: $payload');

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // For now, tapping just brings the app to the foreground.
    // Navigation to specific screens will be added when we have
    // the routing infrastructure for deep-linking into recovery flows.
    if (kDebugMode) {
      Log.debug('Notification payload: $payload');
    }
  }

  void dispose() {
    _recoveryRequestSub?.cancel();
    _recoveryResponseSub?.cancel();
  }
}
