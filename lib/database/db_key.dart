import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/login_service.dart';
import '../services/logger.dart';

/// Derives the SQLCipher whole-DB encryption key from the user's Nostr private
/// key already held in [FlutterSecureStorage], plus a per-install random salt.
///
/// HKDF-SHA-256 (RFC 5869) with:
/// - **IKM**: hex-decoded Nostr private key (32 bytes).
/// - **Salt**: 32 random bytes generated on first launch and persisted to
///   [FlutterSecureStorage] under [saltStorageKey]. Lost salt = lost DB.
/// - **Info**: ASCII bytes of [info] — versioned so future re-derivations are
///   unambiguous.
/// - **Output**: 32 bytes, formatted as `x'<hex>'` for SQLCipher's `PRAGMA
///   key`. Passing it as a raw key skips SQLCipher's redundant KDF (HKDF
///   already provides domain separation).
class DbKeyDerivation {
  static const String saltStorageKey = 'db_key_salt';
  static const String info = 'horcrux/db-key/v1';
  static const int saltLengthBytes = 32;
  static const int derivedKeyLengthBytes = 32;

  /// Allows tests to substitute an in-memory secure-storage stub. Defaults to
  /// the same Android options [LoginService] uses so a corrupted keystore is
  /// reset rather than left half-broken.
  final FlutterSecureStorage _storage;
  final LoginService _loginService;

  DbKeyDerivation({
    LoginService? loginService,
    FlutterSecureStorage? storage,
  })  : _loginService = loginService ?? LoginService(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
            );

  /// Returns the 32-byte derived key, or `null` if the user has no Nostr key
  /// yet (e.g. pre-login). Callers must treat that as "DB cannot be opened
  /// yet" rather than synthesizing a placeholder key.
  Future<Uint8List?> deriveKey() async {
    final keyPair = await _loginService.getStoredNostrKey();
    if (keyPair == null) {
      Log.info('DB key: no Nostr key in secure storage; cannot derive yet');
      return null;
    }

    final privateKey = keyPair.privateKey;
    if (privateKey == null || privateKey.isEmpty) {
      Log.info('DB key: KeyPair has no private key; cannot derive');
      return null;
    }
    final ikm = _hexDecode(privateKey);
    if (ikm.length != 32) {
      throw StateError(
        'Nostr private key has unexpected length ${ikm.length} (expected 32)',
      );
    }

    final salt = await _readOrCreateSalt();
    return _hkdfSha256(
        ikm: ikm, salt: salt, info: ascii.encode(info), length: derivedKeyLengthBytes);
  }

  /// Returns the SQLCipher-compatible literal `"x'<hex>'"` for the derived key
  /// (double-quoted string, raw-key format). Returns `null` when [deriveKey]
  /// returns `null`.
  Future<String?> deriveSqlCipherPragmaKey() async {
    final key = await deriveKey();
    if (key == null) return null;
    return _formatRawKeyForPragma(key);
  }

  Future<Uint8List> _readOrCreateSalt() async {
    final existing = await _storage.read(key: saltStorageKey);
    if (existing != null && existing.isNotEmpty) {
      final bytes = base64Decode(existing);
      if (bytes.length == saltLengthBytes) {
        return Uint8List.fromList(bytes);
      }
      Log.error(
        'DB key salt has unexpected length ${bytes.length}; regenerating '
        '(this orphans any existing DB ciphertext on disk)',
      );
    }

    final salt = _randomBytes(saltLengthBytes);
    await _storage.write(key: saltStorageKey, value: base64Encode(salt));
    Log.info('DB key: generated fresh salt (length $saltLengthBytes)');
    return salt;
  }

  /// Test-only hook: clears the persisted salt.
  Future<void> deleteSalt() => _storage.delete(key: saltStorageKey);

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }

  static Uint8List _hexDecode(String hex) {
    final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (clean.length.isOdd) {
      throw FormatException('Hex string must have even length: $hex');
    }
    final out = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  /// HKDF-SHA-256 (RFC 5869) — extract then expand.
  static Uint8List _hkdfSha256({
    required Uint8List ikm,
    required Uint8List salt,
    required Uint8List info,
    required int length,
  }) {
    final prk = Hmac(sha256, salt).convert(ikm).bytes;
    const hashLen = 32; // SHA-256 digest length in bytes
    final blocks = (length + hashLen - 1) ~/ hashLen;
    final t = <int>[];
    var prev = <int>[];
    for (var i = 1; i <= blocks; i++) {
      final mac = Hmac(sha256, prk);
      final input = <int>[...prev, ...info, i];
      prev = mac.convert(input).bytes;
      t.addAll(prev);
    }
    return Uint8List.fromList(t.sublist(0, length));
  }

  /// SQLCipher raw-key format: a double-quoted string wrapping `x'hexhex'`.
  /// Outer double quotes are required — bare blob literals (`x'...'`) are not
  /// valid pragma-values in SQLite's grammar and cause a syntax error.
  /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/
  static String _formatRawKeyForPragma(Uint8List key) {
    final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '"x\'$hex\'"';
  }
}
