import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_navigator.dart';
import '../database/app_database_provider.dart';
import '../providers/key_provider.dart';
import '../services/ndk_service.dart';
import '../services/relay_scan_service.dart';
import '../services/deep_link_service.dart';
import '../services/local_notification_service.dart';
import '../services/push_notification_receiver.dart';
import '../services/recovery_service.dart';
import '../services/log_export_service.dart';
import '../services/vault_export_service.dart';

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

  // Sweep any vault plaintext that survived a previous run (e.g. crash, force-
  // quit, or share recipient that read-and-released after our cleanup window).
  await ref.read(vaultExportServiceProvider).clearExportDirectory();

  await ref.read(logExportServiceProvider).clearLogExportDirectory();

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
/// Also invalidates [appDatabaseProvider] so a post-logout failed open (no key
/// in secure storage while SQLCipher was touched) cannot leave a cached error
/// on the provider after the user imports a key.
///
/// Parameters:
/// - [ref] - WidgetRef to access providers
Future<void> initializeAppAndRefreshKeys(WidgetRef ref) async {
  // [LazyDatabase] caches a failed open (e.g. after logout when providers
  // rebuild before a new Nostr key exists). Invalidate so service init uses a
  // fresh connection after the key is in secure storage.
  ref.invalidate(appDatabaseProvider);
  ref.invalidate(ndkServiceProvider);
  ref.invalidate(relayScanServiceProvider);
  ref.invalidate(deepLinkServiceProvider);

  await initializeAppServices(ref);

  // Invalidate providers to trigger rebuild
  ref.invalidate(currentPublicKeyProvider);
  ref.invalidate(currentPublicKeyBech32Provider);
  ref.invalidate(isLoggedInProvider);
  ref.invalidate(appDatabaseProvider);
}
