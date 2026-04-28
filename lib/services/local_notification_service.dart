import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../app_navigator.dart';
import '../models/nostr_kinds.dart';
import '../models/recovery_request.dart';
import '../models/shard_data.dart';
import '../providers/vault_provider.dart';
import '../screens/recovery_request_detail_screen.dart';
import '../screens/recovery_status_screen.dart';
import '../screens/vault_detail_screen.dart';
import '../utils/push_notification_text.dart';
import 'logger.dart';
import 'ndk_service.dart' show RecoveryResponseEvent;
import 'notification_recency.dart';
import 'recovery_service.dart' show RecoveryService, recoveryServiceProvider;

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  final vaultRepository = ref.watch(vaultRepositoryProvider);
  final service = LocalNotificationService(
    vaultRepository: vaultRepository,
    getRecoveryService: () => ref.read(recoveryServiceProvider),
  );
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
  final RecoveryService Function() _getRecoveryService;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'horcrux_notifications';
  static const _channelName = 'Horcrux Notifications';
  static const _channelDescription = 'Notifications for vault events like recovery requests.';

  int _notificationCounter = 0;

  LocalNotificationService({
    required VaultRepository vaultRepository,
    required RecoveryService Function() getRecoveryService,
  })  : _vaultRepository = vaultRepository,
        _getRecoveryService = getRecoveryService;

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
  /// - **iOS / macOS:** Requests alert, badge, and sound via the plugin.
  Future<bool> requestPlatformNotificationPermissions() async {
    var anyPromptFailed = false;

    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    if (androidGranted != null) {
      Log.info('Android POST_NOTIFICATIONS granted: $androidGranted');
      if (!androidGranted) anyPromptFailed = true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) {
      Log.info('iOS notification permissions granted: $iosGranted');
      if (!iosGranted) anyPromptFailed = true;
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
      if (!macGranted) anyPromptFailed = true;
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
      payload: '${NostrKind.recoveryRequest.value}:${request.id}',
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
      payload: '${kind.value}:${event.id}:$vaultId',
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
      payload:
          '${NostrKind.recoveryResponse.value}:${response.recoveryRequestId}:${response.vaultId}',
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

    final firstColon = payload.indexOf(':');
    if (firstColon == -1) return;

    final kindValue = int.tryParse(payload.substring(0, firstColon));
    if (kindValue == null) return;

    final kind = NostrKind.fromValue(kindValue);
    if (kind == null) return;

    final rest = payload.substring(firstColon + 1);
    final secondColon = rest.indexOf(':');
    final id = secondColon == -1 ? rest : rest.substring(0, secondColon);
    final vaultId = secondColon == -1 ? null : rest.substring(secondColon + 1);

    final resolvedVaultId = (vaultId?.isEmpty ?? true) ? null : vaultId;
    unawaited(() async {
      try {
        await navigateForKind(kind, id, vaultId: resolvedVaultId);
      } catch (e, st) {
        Log.warning('Notification tap: navigation failed for kind $kind, payload: $payload', e, st);
      }
    }());
  }

  /// Navigates to the appropriate screen for the given [kind] and [id].
  ///
  /// [vaultId] is required for shard kinds to open [VaultDetailScreen].
  /// Returns `true` if navigation succeeded, `false` if the target could not
  /// be found or required context (e.g. vaultId) is absent.
  Future<bool> navigateForKind(NostrKind kind, String id, {String? vaultId}) async {
    switch (kind) {
      case NostrKind.recoveryRequest:
        return _navigateToRecoveryRequest(id);
      case NostrKind.recoveryResponse:
        return _navigateToRecoveryStatus(id);
      case NostrKind.shardData:
      case NostrKind.shardConfirmation:
        if (vaultId == null || vaultId.isEmpty) {
          Log.debug('No vaultId for $kind notification tap, skipping navigation');
          return false;
        }
        await navigateToVault(vaultId);
        return true;
      default:
        Log.debug('No navigation handler for kind $kind');
        return false;
    }
  }

  /// Navigates to [VaultDetailScreen] for [vaultId], waiting up to 2 s for
  /// the navigator to become ready.
  Future<void> navigateToVault(String vaultId) async {
    await _pushRouteWhenReady(
      (context) => VaultDetailScreen(vaultId: vaultId),
      debugLabel: 'vault $vaultId',
    );
  }

  Future<bool> _navigateToRecoveryStatus(String recoveryRequestId) async {
    await _pushRouteWhenReady(
      (context) => RecoveryStatusScreen(recoveryRequestId: recoveryRequestId),
      debugLabel: 'recovery status $recoveryRequestId',
    );
    return true;
  }

  Future<bool> _navigateToRecoveryRequest(String recoveryRequestId) async {
    final request = await _getRecoveryService().getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      Log.warning(
          'Notification: recovery request $recoveryRequestId not found, skipping navigation');
      return false;
    }
    await _pushRouteWhenReady(
      (context) => RecoveryRequestDetailScreen(recoveryRequest: request),
      debugLabel: 'recovery request $recoveryRequestId',
    );
    return true;
  }

  Future<void> _pushRouteWhenReady(WidgetBuilder builder, {String? debugLabel}) async {
    for (var i = 0; i < 40; i++) {
      final nav = navigatorKey.currentState;
      if (nav != null && nav.mounted) {
        await nav.push(MaterialPageRoute<void>(builder: builder));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    Log.warning(
      'Notification tap: navigator not ready; skipped navigation${debugLabel != null ? " to $debugLabel" : ""}',
    );
  }

  void dispose() {}
}
