import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../app_navigator.dart';
import '../models/nostr_kinds.dart';
import '../models/recovery_request.dart';
import '../models/shard_data.dart';
import '../providers/vault_provider.dart';
import '../utils/push_notification_text.dart';
import 'logger.dart';
import 'ndk_service.dart' show RecoveryResponseEvent;
import 'notification_recency.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  final vaultRepository = ref.watch(vaultRepositoryProvider);
  final service = LocalNotificationService(vaultRepository: vaultRepository);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Service that displays OS notifications to the user for things like recovery events.
///
/// All `notifyXxxProcessed` entry points are gated on [isEventRecent] against
/// [getFirstAppOpenUtc], so relay backfill of historical events does not spam
/// notifications after a fresh install. Upstream services may apply additional
/// domain filters (e.g. "initiator only hears peer responses") before calling
/// in, but recency is enforced here as the single source of truth.
class LocalNotificationService {
  final VaultRepository _vaultRepository;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'horcrux_notifications';
  static const _channelName = 'Horcrux Notifications';
  static const _channelDescription = 'Notifications for vault events like recovery requests.';

  int _notificationCounter = 0;

  LocalNotificationService({required VaultRepository vaultRepository})
      : _vaultRepository = vaultRepository;

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

    Log.info('LocalNotificationService initialized');
  }

  /// Called by [RecoveryService] after a recovery request event is processed successfully.
  ///
  /// Recency-gated via [isEventRecent] using the inner event creation time
  /// (falling back to [RecoveryRequest.requestedAt]) so relay backfill does
  /// not surface historical requests as notifications.
  Future<void> notifyRecoveryRequestProcessed(RecoveryRequest request) async {
    final anchor = request.eventCreationTime ?? request.requestedAt;
    if (!await _isRecentForNotification(anchor, label: 'recovery request', id: request.id)) {
      return;
    }
    await _showRecoveryRequestNotification(request);
  }

  /// Called by [RecoveryService] after a recovery response event is processed successfully.
  ///
  /// Recency-gated via [isEventRecent] using [RecoveryResponseEvent.createdAt];
  /// responses without an inner creation time are treated as non-recent.
  Future<void> notifyRecoveryResponseProcessed(RecoveryResponseEvent response) async {
    final anchor = response.createdAt;
    if (anchor == null ||
        !await _isRecentForNotification(
          anchor,
          label: 'recovery response',
          id: response.recoveryRequestId,
        )) {
      return;
    }
    await _showRecoveryResponseNotification(response);
  }

  /// Called by [NdkService] after a kind-1337 shard-data event is processed successfully.
  ///
  /// Shows a local notification on the steward's device announcing that the
  /// owner has sent them a (re)distributed shard. [event] is the unwrapped
  /// rumor (not the outer gift wrap) so [Nip01Event.createdAt] and
  /// [Nip01Event.pubKey] identify the real sender and creation time.
  ///
  /// Recency-gated via [isEventRecent] so relay backfill of historical events
  /// does not spam notifications on first launch.
  Future<void> notifyShardDataProcessed({
    required Nip01Event event,
    required ShardData shardData,
  }) async {
    await _showShardNotification(
      kind: NostrKind.shardData,
      event: event,
      vaultId: shardData.vaultId,
    );
  }

  /// Called by [NdkService] after a kind-1342 shard-confirmation event is processed successfully.
  ///
  /// Shows a local notification on the vault owner's device announcing that a
  /// steward has confirmed receipt of the latest shard. [event] is the
  /// unwrapped rumor.
  ///
  /// Recency-gated via [isEventRecent] to suppress relay backfill.
  Future<void> notifyShardConfirmationProcessed({
    required Nip01Event event,
    required String vaultId,
  }) async {
    await _showShardNotification(
      kind: NostrKind.shardConfirmation,
      event: event,
      vaultId: vaultId,
    );
  }

  /// Returns whether [eventUtc] is recent enough to notify for, logging a
  /// skip with [label] / [id] when it is not.
  Future<bool> _isRecentForNotification(
    DateTime eventUtc, {
    required String label,
    required String id,
  }) async {
    final firstOpen = await getFirstAppOpenUtc();
    if (isEventRecent(eventUtc, firstOpen)) return true;
    Log.debug('Skipping $label notification $id: event predates first app open');
    return false;
  }

  /// Asks the OS for permission to show notifications.
  ///
  /// - **Android 13+:** `POST_NOTIFICATIONS` runtime dialog via the plugin. On older Android,
  ///   notifications are allowed by default (result may be null).
  ///
  /// iOS and macOS are handled by [PushNotificationReceiver._requestNotificationPermission]
  /// using `FirebaseMessaging.requestPermission()` instead, because Firebase's
  /// swizzled `UNUserNotificationCenterDelegate` causes this plugin to return
  /// `false` even when the user has granted permission on those platforms.
  Future<bool> requestPlatformNotificationPermissions() async {
    var anyPromptFailed = false;

    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    if (androidGranted != null) {
      Log.info('Android POST_NOTIFICATIONS granted: $androidGranted');
      if (!androidGranted) anyPromptFailed = true;
    }

    return !anyPromptFailed;
  }

  Future<void> _showRecoveryRequestNotification(RecoveryRequest request) async {
    Log.info(
      'Showing notification for recovery request: ${request.id}',
    );
    final vault = await _vaultRepository.getVault(request.vaultId);
    final text = composeNotificationText(
      kind: NostrKind.recoveryRequest,
      vault: vault,
      senderPubkey: request.initiatorPubkey,
    );
    if (text == null) return;
    await showNotification(
      title: text.title,
      body: text.body,
      payload: 'recovery_request:${request.id}',
    );
  }

  Future<void> _showShardNotification({
    required NostrKind kind,
    required Nip01Event event,
    required String? vaultId,
  }) async {
    if (vaultId == null || vaultId.isEmpty) {
      Log.debug('Skipping ${kind.name} notification: missing vault id');
      return;
    }

    final eventUtc = DateTime.fromMillisecondsSinceEpoch(
      event.createdAt * 1000,
      isUtc: true,
    );
    if (!await _isRecentForNotification(eventUtc, label: kind.name, id: event.id)) {
      return;
    }

    final vault = await _vaultRepository.getVault(vaultId);
    final text = composeNotificationText(
      kind: kind,
      vault: vault,
      senderPubkey: event.pubKey,
    );
    if (text == null) return;

    Log.info('Showing notification for ${kind.name} event: ${event.id}');
    await showNotification(
      title: text.title,
      body: text.body,
      payload: '${kind.name}:${event.id}',
    );
  }

  Future<void> _showRecoveryResponseNotification(RecoveryResponseEvent response) async {
    final status = response.approved ? 'approved' : 'denied';
    Log.info(
      'Showing notification for recovery response ($status): ${response.recoveryRequestId}',
    );
    final vault = await _vaultRepository.getVault(response.vaultId);
    final text = composeNotificationText(
      kind: NostrKind.recoveryResponse,
      vault: vault,
      senderPubkey: response.senderPubkey,
      recoveryApproved: response.approved,
    );
    if (text == null) return;
    await showNotification(
      title: text.title,
      body: text.body,
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

  void dispose() {}
}
