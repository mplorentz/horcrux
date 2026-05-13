import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/connection.dart';
import 'logger.dart';
import 'processed_nostr_event_store.dart';

const FlutterSecureStorage _wipeStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: true),
);

/// Deletes all secure-storage entries for the active app identity.
///
/// Used by both explicit logout and corruption-recovery wipe paths.
Future<void> clearSecureStorageForWipe({
  FlutterSecureStorage? storage,
}) async {
  final target = storage ?? _wipeStorage;
  await target.deleteAll();
}

/// Wipes durable on-disk caches that reference the active Nostr identity.
///
/// Call when secure-storage decryption fails (e.g. installing the debug build
/// over the release build, or Android Auto Backup restoring SharedPreferences /
/// application support files into a process whose keystore key is gone). The
/// previous private key is unrecoverable, so any caches keyed off it -- the
/// processed Nostr event log/WAL/cursors, vault metadata in SharedPreferences,
/// and any half-written ciphertext in secure storage -- must be discarded
/// before generating a fresh identity.
///
/// Unlike `LogoutService.logout`, this does not stop relay scanning or tear
/// down service caches: it is intended for the cold-start corruption path
/// where no services have been initialised yet.
///
/// Lives in its own file (rather than alongside `LogoutService`) so the login
/// path can wire it without importing logout's provider, which would create a
/// cycle with `key_provider.dart`.
Future<void> wipeLocalDataForCorruptedSecureStorage({
  required ProcessedNostrEventStore processedNostrEventStore,
  Future<void> Function()? deleteDatabaseFiles,
  Future<void> Function()? clearSecureStorage,
}) async {
  Log.warning('Wiping local caches due to corrupted secure storage');

  try {
    await processedNostrEventStore.clearAll();
  } catch (e, st) {
    Log.error('Failed to clear processed Nostr event store during corruption wipe', e, st);
  }

  // TODO(hvc-2em): Remove once VaultShareService recovery_shard_data is migrated to drift.
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (e, st) {
    Log.error('Failed to clear SharedPreferences during corruption wipe', e, st);
  }

  try {
    await (deleteDatabaseFiles ?? deleteSqlCipherDatabaseFiles)();
  } catch (e, st) {
    Log.error('Failed to delete SQLCipher files during corruption wipe', e, st);
  }

  try {
    await (clearSecureStorage ?? clearSecureStorageForWipe)();
  } catch (e, st) {
    Log.error('Failed to deleteAll secure storage during corruption wipe', e, st);
  }
}

/// True if [error] is a `PlatformException` whose underlying Java exception
/// indicates the Android Keystore key used to encrypt secure-storage data is
/// gone (debug build over release, OS reset, Auto Backup restore without the
/// keystore entry, etc.).
///
/// Such errors are permanent: the ciphertext can never be decrypted again and
/// any caches keyed off it are stale. Use this to decide whether to invoke
/// [wipeLocalDataForCorruptedSecureStorage] vs. just logging and falling back.
///
/// Transient failures (`NullPointerException`, `KeyStoreException`,
/// `ServiceSpecificException`, etc.) are deliberately treated as recoverable
/// here: the FlutterSecureStorage plugin's `resetOnError: true` already gives
/// it a chance to recover from those internally, and we do not want to wipe
/// the user's vault data on what may be a one-shot init race.
bool isPermanentSecureStorageReadFailure(Object error) {
  if (error is! PlatformException) return false;
  final haystack = [
    error.message ?? '',
    error.details?.toString() ?? '',
  ].join(' ').toLowerCase();
  // Java exception class names appear in the PlatformException message string
  // produced by the Android implementation of flutter_secure_storage. The
  // `bad_decrypt` token shows up inside the OpenSSL error wrapped by
  // BadPaddingException on some devices.
  const markers = [
    'badpaddingexception',
    'invalidkeyexception',
    'unrecoverablekeyexception',
    'bad_decrypt',
  ];
  return markers.any(haystack.contains);
}
