import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../app_navigator.dart';
import '../models/nostr_kinds.dart';
import '../models/recovery_request.dart';
import '../models/share.dart';
import '../providers/key_provider.dart';
import '../providers/vault_provider.dart';
import '../screens/recovery_request_detail_screen.dart';
import '../screens/recovery_status_screen.dart';
import '../screens/vault_detail_screen.dart';
import '../utils/push_notification_text.dart';
import 'login_service.dart';
import 'logger.dart';
import 'ndk_service.dart' show RecoveryResponseEvent;
import 'notification_recency.dart';
import 'recovery_service.dart' show RecoveryService, recoveryServiceProvider;

/// True when the app is in [AppLifecycleState.resumed] (foreground).
///
/// Used by [LocalNotificationService] to suppress informational shard
/// notifications (kind 713) while the user already has the app open.
/// [WidgetsBinding.instance.lifecycleState] may be null during early startup;
/// that is treated as not resumed so notifications are not dropped.
bool _defaultLocalNotificationIsForegrounded() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == AppLifecycleState.resumed;
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  final vaultRepository = ref.watch(vaultRepositoryProvider);
  final loginService = ref.watch(loginServiceProvider);
  final appDatabase = ref.watch(appDatabaseProvider);
  final service = LocalNotificationService(
    vaultRepository: vaultRepository,
    loginService: loginService,
    appDatabase: appDatabase,
    getRecoveryService: () => ref.read(recoveryServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stable [RouteSettings.name] for the [VaultDetailScreen] route pushed by
/// notification taps. Exposed for tests and DevTools route inspection.
/// Uses a slash-style path so [Navigator] treats it as a relative URI when
/// it builds [RouteInformation] for system observers (a colon would parse as
/// a URI scheme and throw).
String vaultDetailRouteName(String vaultId) => '/vault_detail/$vaultId';

/// Stable [RouteSettings.name] for the [RecoveryStatusScreen] route pushed by
/// recovery-response notification taps.
String recoveryStatusRouteName(String recoveryRequestId) => '/recovery_status/$recoveryRequestId';

/// Stable [RouteSettings.name] for the [RecoveryRequestDetailScreen] route
/// pushed by recovery-request notification taps.
String recoveryRequestRouteName(String recoveryRequestId) => '/recovery_request/$recoveryRequestId';

/// Service that displays OS notifications to the user for things like recovery events.
///
/// All `notifyXxxProcessed` entry points are gated on [isEventRecent] against
/// [getFirstAppOpenUtc], so relay backfill of historical events does not spam
/// notifications after a fresh install. Upstream services may apply additional
/// domain filters (e.g. "initiator only hears peer responses") before calling
/// in, but recency is enforced here as the single source of truth.
class LocalNotificationService {
  final VaultRepository _vaultRepository;
  final LoginService _loginService;
  final AppDatabase _appDatabase;
  final RecoveryService Function() _getRecoveryService;
  final bool Function() _isForegrounded;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'horcrux_notifications';
  static const _channelName = 'Horcrux Notifications';
  static const _channelDescription = 'Notifications for vault events like recovery requests.';

  int _notificationCounter = 0;

  LocalNotificationService({
    required VaultRepository vaultRepository,
    required LoginService loginService,
    required AppDatabase appDatabase,
    required RecoveryService Function() getRecoveryService,
    bool Function()? isForegrounded,
  })  : _vaultRepository = vaultRepository,
        _loginService = loginService,
        _appDatabase = appDatabase,
        _getRecoveryService = getRecoveryService,
        _isForegrounded = isForegrounded ?? _defaultLocalNotificationIsForegrounded;

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
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
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

  /// Called by [NdkService] after a kind-713 shard-data event is processed successfully.
  ///
  /// Shows a local notification on the steward's device announcing that the
  /// owner has sent them a (re)distributed shard. [event] is the unwrapped
  /// rumor (not the outer gift wrap) so [Nip01Event.createdAt] and
  /// [Nip01Event.pubKey] identify the real sender and creation time.
  ///
  /// Recency-gated via [isEventRecent] so relay backfill of historical events
  /// does not spam notifications on first launch.
  Future<void> notifyShareDataProcessed({
    required Nip01Event event,
    required Share share,
  }) async {
    await _showShardNotification(
      kind: NostrKind.shareData,
      event: event,
      vaultId: share.vaultId,
    );
  }

  /// Called by [NdkService] after a kind-718 shard-confirmation event is processed successfully.
  ///
  /// Shows a local notification on the vault owner's device announcing that a
  /// steward has confirmed receipt of the latest shard. [event] is the
  /// unwrapped rumor.
  ///
  /// Recency-gated via [isEventRecent] to suppress relay backfill.
  Future<void> notifyShareConfirmationProcessed({
    required Nip01Event event,
    required String vaultId,
  }) async {
    await _showShardNotification(
      kind: NostrKind.shareConfirmation,
      event: event,
      vaultId: vaultId,
    );
  }

  /// Returns whether [pubkey] matches the current user's hex public key.
  ///
  /// Used to suppress local notifications for events the user themselves
  /// signed -- which happens whenever the user is a steward of their own
  /// vault, because the publish-to-stewards loop includes their own pubkey
  /// and the corresponding gift wrap round-trips through their own client.
  /// Returns `false` (i.e. "not self, do notify") if the lookup fails or no
  /// key has been initialized yet, so a transient secure-storage hiccup
  /// degrades to "show the notification" rather than swallowing it silently.
  Future<bool> _isCurrentUserPubkey(String pubkey) async {
    try {
      final current = await _loginService.getCurrentPublicKey();
      if (current == null || current.isEmpty) return false;
      return current.toLowerCase() == pubkey.toLowerCase();
    } catch (e, st) {
      Log.warning('LocalNotificationService: self-pubkey lookup failed', e, st);
      return false;
    }
  }

  /// Returns whether [eventUtc] is recent enough to notify for, logging a
  /// skip with [label] / [id] when it is not.
  Future<bool> _isRecentForNotification(
    DateTime eventUtc, {
    required String label,
    required String id,
  }) async {
    final firstOpen = await getFirstAppOpenUtc(database: _appDatabase);
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

  /// Reads the current OS-level notification permission state without prompting.
  ///
  /// Used to detect divergence between our persisted opt-in flag (which can
  /// survive an uninstall + reinstall via Android Auto Backup or iCloud
  /// SharedPreferences sync) and the OS, whose runtime permission can be
  /// reset by the package replacement. When the persisted flag claims
  /// "opted in" but this method returns `false`, callers should treat the
  /// user as not opted in and re-run the request flow.
  ///
  /// Returns `true` on platforms where the plugin does not expose a check
  /// (e.g. web, Linux, Windows) so we don't loop on uncertainty. Errors are
  /// swallowed and logged; the safe default is also `true` to avoid
  /// re-prompting based on a flaky probe.
  Future<bool> areOsNotificationsEnabled() async {
    try {
      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.areNotificationsEnabled();
        // Pre-Android-13 has no runtime gate; the plugin returns null.
        return granted ?? true;
      }

      final ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return _hasAnyEnabledOption(await ios.checkPermissions());
      }

      final macOS =
          _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
      if (macOS != null) {
        return _hasAnyEnabledOption(await macOS.checkPermissions());
      }

      return true;
    } catch (e, st) {
      Log.warning('areOsNotificationsEnabled probe failed', e, st);
      return true;
    }
  }

  bool _hasAnyEnabledOption(NotificationsEnabledOptions? options) {
    if (options == null) return false;
    return options.isAlertEnabled || options.isBadgeEnabled || options.isSoundEnabled;
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

    // When the user is a steward of their own vault, every shard distribution
    // and confirmation publish round-trips through their own client. Notifying
    // about an event the current user just signed would surface lines like
    // "Mac has confirmed they have the latest data..." on the device that
    // *is* Mac. Skip those before composing any text. See horcrux_app-3b0.
    if (await _isCurrentUserPubkey(event.pubKey)) {
      Log.debug(
        'Skipping ${kind.name} notification ${event.id}: '
        'event was signed by the current user',
      );
      return;
    }

    final eventUtc = DateTime.fromMillisecondsSinceEpoch(
      event.createdAt * 1000,
      isUtc: true,
    );
    if (!await _isRecentForNotification(eventUtc, label: kind.name, id: event.id)) {
      return;
    }

    if (kind == NostrKind.shareData && _isForegrounded()) {
      Log.debug(
        'Skipping ${kind.name} notification ${event.id}: app is in foreground',
      );
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
    const linuxDetails = LinuxNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    try {
      await _plugin.show(
        _notificationIdFromEpochAndCounter(),
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e, st) {
      // Showing notifications is best-effort (e.g. Linux without
      // org.freedesktop.Notifications). Must not fail vault/Nostr handling.
      Log.debug('Skipping local notification (display unavailable)', e, st);
    }
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
  /// All recovery- and shard-related taps reset the navigator stack to the
  /// root ([VaultListScreen]) and push [VaultDetailScreen] for the relevant
  /// vault underneath the destination, so popping always walks back through
  /// the right vault and then to the vault list — regardless of what was on
  /// screen when the notification arrived.
  ///
  /// - [NostrKind.recoveryRequest]: stack becomes
  ///   `[VaultList, VaultDetail, RecoveryRequestDetailScreen]` (steward sees
  ///   the request whose vault the notification refers to).
  /// - [NostrKind.recoveryResponse]: stack becomes
  ///   `[VaultList, VaultDetail, RecoveryStatusScreen]` (initiator lands on
  ///   the "Manage Recovery" screen for the request whose status just
  ///   changed). Falls back to [VaultDetailScreen] alone when the recovery
  ///   request can't be found locally.
  /// - [NostrKind.shareData] / [NostrKind.shareConfirmation]: stack becomes
  ///   `[VaultList, VaultDetail]` for [vaultId].
  ///
  /// [vaultId] is required for shard kinds and used as a fallback for recovery
  /// responses. Returns `true` if navigation succeeded, `false` if the target
  /// could not be found or required context (e.g. vaultId) is absent.
  Future<bool> navigateForKind(NostrKind kind, String id, {String? vaultId}) async {
    switch (kind) {
      case NostrKind.recoveryRequest:
        return _navigateToRecoveryRequest(id);
      case NostrKind.recoveryResponse:
        return _navigateToRecoveryStatus(id, fallbackVaultId: vaultId);
      case NostrKind.shareData:
      case NostrKind.shareConfirmation:
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
  ///
  /// Resets the stack down to the root route ([MaterialApp.home], i.e.
  /// [VaultListScreen]) before pushing so notification-driven vault opens do
  /// not leave unrelated screens underneath, while still letting the user pop
  /// back to the vault list.
  Future<void> navigateToVault(String vaultId) async {
    await _whenNavigatorReady(
      (nav) {
        unawaited(
          nav.pushAndRemoveUntil<void>(
            MaterialPageRoute<void>(
              settings: RouteSettings(name: vaultDetailRouteName(vaultId)),
              builder: (context) => VaultDetailScreen(vaultId: vaultId),
            ),
            (route) => route.isFirst,
          ),
        );
      },
      navigatorNotReadyWarning:
          'Notification tap: navigator not ready; skipped navigation to vault $vaultId',
    );
  }

  Future<bool> _navigateToRecoveryRequest(String recoveryRequestId) async {
    final request = await _getRecoveryService().getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      Log.warning(
          'Notification: recovery request $recoveryRequestId not found, skipping navigation');
      return false;
    }
    await _pushVaultThenScreenWhenReady(
      vaultId: request.vaultId,
      topScreenBuilder: (context) => RecoveryRequestDetailScreen(recoveryRequest: request),
      topScreenRouteName: recoveryRequestRouteName(recoveryRequestId),
      debugLabel: 'recovery request $recoveryRequestId',
    );
    return true;
  }

  /// Opens [RecoveryStatusScreen] for [recoveryRequestId] when the request is
  /// known locally; otherwise falls back to [navigateToVault] using
  /// [fallbackVaultId] if provided.
  Future<bool> _navigateToRecoveryStatus(
    String recoveryRequestId, {
    String? fallbackVaultId,
  }) async {
    final request = await _getRecoveryService().getRecoveryRequest(recoveryRequestId);
    if (request == null) {
      Log.warning(
        'Notification: recovery request $recoveryRequestId not found for response navigation',
      );
      if (fallbackVaultId == null || fallbackVaultId.isEmpty) return false;
      await navigateToVault(fallbackVaultId);
      return true;
    }
    await _pushVaultThenScreenWhenReady(
      vaultId: request.vaultId,
      topScreenBuilder: (context) => RecoveryStatusScreen(recoveryRequestId: recoveryRequestId),
      topScreenRouteName: recoveryStatusRouteName(recoveryRequestId),
      debugLabel: 'recovery status $recoveryRequestId',
    );
    return true;
  }

  /// Resets the navigator stack to the root, pushes [VaultDetailScreen] for
  /// [vaultId], then pushes the screen built by [topScreenBuilder] on top —
  /// final stack `[VaultListScreen, VaultDetail, <top screen>]`. Used by all
  /// recovery-tap paths so popping the destination lands on the correct vault
  /// and then the vault list, regardless of what was on screen when the
  /// notification arrived.
  Future<void> _pushVaultThenScreenWhenReady({
    required String vaultId,
    required WidgetBuilder topScreenBuilder,
    required String topScreenRouteName,
    required String debugLabel,
  }) async {
    await _whenNavigatorReady(
      (nav) {
        // Both calls mutate the stack synchronously; the futures they return
        // are pop notifications we deliberately drop (awaiting would block
        // here until the pushed route is popped, and the second push would
        // never fire while the first route is still on screen).
        //
        // Reset to the root route ([VaultListScreen] via [MaterialApp.home]),
        // push the relevant vault on top, then push the destination screen
        // on top of that.
        unawaited(
          nav.pushAndRemoveUntil<void>(
            MaterialPageRoute<void>(
              settings: RouteSettings(name: vaultDetailRouteName(vaultId)),
              builder: (context) => VaultDetailScreen(vaultId: vaultId),
            ),
            (route) => route.isFirst,
          ),
        );
        unawaited(
          nav.push<void>(
            MaterialPageRoute<void>(
              settings: RouteSettings(name: topScreenRouteName),
              builder: topScreenBuilder,
            ),
          ),
        );
      },
      navigatorNotReadyWarning:
          'Notification tap: navigator not ready; skipped navigation to $debugLabel '
          '(vault $vaultId)',
    );
  }

  /// Polls up to ~2s for [navigatorKey]'s [NavigatorState] to be mounted, then
  /// runs [action]. Logs [navigatorNotReadyWarning] if it never becomes ready.
  ///
  /// [action] should manipulate the navigator synchronously (e.g. `push`,
  /// `pushAndRemoveUntil`). Don't `await` the futures those calls return:
  /// they complete only when the pushed route is popped, which would block
  /// any subsequent stack work in the same callback.
  Future<void> _whenNavigatorReady(
    void Function(NavigatorState nav) action, {
    required String navigatorNotReadyWarning,
  }) async {
    const attempts = 40;
    const interval = Duration(milliseconds: 50);
    for (var i = 0; i < attempts; i++) {
      final nav = navigatorKey.currentState;
      if (nav != null && nav.mounted) {
        action(nav);
        return;
      }
      await Future<void>.delayed(interval);
    }
    Log.warning(navigatorNotReadyWarning);
  }

  void dispose() {}
}
