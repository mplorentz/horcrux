import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/key_provider.dart';
import '../services/deep_link_service.dart';
import '../services/local_notification_service.dart';
import '../services/push_notification_receiver.dart';
import '../services/recovery_service.dart';
import '../services/relay_scan_service.dart';

/// Initializes app services (deep linking and relay scanning).
/// Optionally initializes a key if one doesn't exist.
///
/// Parameters:
/// - [ref] - WidgetRef to access providers
/// - [initializeKeyIfNeeded] - If true, generates a key if none exists (default: false)
///
/// Returns the initialized key pair if [initializeKeyIfNeeded] is true, null otherwise.
Future<void> initializeAppServices(
  WidgetRef ref, {
  bool initializeKeyIfNeeded = false,
}) async {
  // Optionally initialize key if needed (e.g., during onboarding)
  if (initializeKeyIfNeeded) {
    final loginService = ref.read(loginServiceProvider);
    await loginService.initializeKey();
  }

  // OS notification plugin before relay traffic: [RecoveryService] may call back into
  // [LocalNotificationService] as soon as subscriptions deliver events.
  final localNotificationService = ref.read(localNotificationServiceProvider);
  await localNotificationService.initialize();

  // Firebase Cloud Messaging is initialized lazily -- only after the user
  // opts into push notifications at vault creation, invitation acceptance,
  // or from settings. See [PushNotificationReceiver.optIn]. Users who haven't
  // opted in never have Firebase initialized on their device.
  await ref.read(pushNotificationReceiverProvider).maybeInitialize();

  // Recovery dedupe + notification timeline before relay traffic.
  await ref.read(recoveryServiceProvider).initialize();

  // Initialize deep linking
  final deepLinkService = ref.read(deepLinkServiceProvider);
  deepLinkService.setNavigatorKey(navigatorKey);
  await deepLinkService.initializeDeepLinking();

  // Initialize relay scanning service
  // This will auto-start scanning if there are enabled relays
  final relayScanService = ref.read(relayScanServiceProvider);
  await relayScanService.initialize();

  // Invalidate key-related providers to trigger rebuild (e.g., after onboarding)
  if (initializeKeyIfNeeded) {
    ref.invalidate(currentPublicKeyProvider);
    ref.invalidate(currentPublicKeyBech32Provider);
    ref.invalidate(isLoggedInProvider);
  }
}

/// Initializes app services and invalidates key providers after login/account creation
///
/// This is a convenience function that combines service initialization with
/// provider invalidation, commonly used after account creation or login.
///
/// Parameters:
/// - [ref] - WidgetRef to access providers
Future<void> initializeAppAndRefreshKeys(WidgetRef ref) async {
  await initializeAppServices(ref);

  // Invalidate providers to trigger rebuild
  ref.invalidate(currentPublicKeyProvider);
  ref.invalidate(currentPublicKeyBech32Provider);
  ref.invalidate(isLoggedInProvider);
}
