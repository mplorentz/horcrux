import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/login_service.dart';
import '../services/logout_service.dart';
import '../services/processed_nostr_event_store.dart';

/// Provider for LoginService
/// Riverpod automatically ensures this is a singleton - only one instance exists
final loginServiceProvider = Provider<LoginService>((ref) {
  final loginService = LoginService();
  // When the secure-storage read path detects corruption (e.g. keystore key is
  // gone after a debug-over-release install or Auto Backup restore), wipe the
  // durable caches that still reference the now-unrecoverable identity before
  // we fall through to onboarding and generate a fresh key.
  loginService.onSecureStorageReadFailure = () async {
    await wipeLocalDataForCorruptedSecureStorage(
      processedNostrEventStore: ref.read(processedNostrEventStoreProvider),
    );
  };
  return loginService;
});

/// FutureProvider for the current public key in hex format
/// This will automatically cache the result and only re-fetch when invalidated
final currentPublicKeyProvider = FutureProvider<String?>((ref) async {
  final loginService = ref.watch(loginServiceProvider);
  return await loginService.getCurrentPublicKey();
});

/// FutureProvider for the current public key in bech32 format (npub)
/// This will automatically cache the result and only re-fetch when invalidated
final currentPublicKeyBech32Provider = FutureProvider<String?>((ref) async {
  final loginService = ref.watch(loginServiceProvider);
  return await loginService.getCurrentPublicKeyBech32();
});

/// FutureProvider that checks if user is logged in (has a stored private key)
/// Returns true if a key exists, false otherwise
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final loginService = ref.watch(loginServiceProvider);
  final keyPair = await loginService.getStoredNostrKey();
  return keyPair != null;
});
