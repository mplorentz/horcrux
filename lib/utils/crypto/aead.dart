/// ChaCha20-Poly1305 AEAD wrapper used to seal vault content while only the
/// 32-byte content-encryption key is split via Shamir.
///
/// Bundle layout (the bytes carried in the share `blob` tag):
/// ```
/// [ nonce (12) || ciphertext (n) || poly1305 tag (16) ]
/// ```
///
/// The Poly1305 tag is the only integrity check on reconstructed vault
/// content: SSS by itself returns garbage on tampered or insufficient shares
/// with no signal, so callers MUST treat [AeadAuthenticationError] as
/// "shares are wrong or blob is tampered" and surface that to the user
/// instead of attempting to interpret the plaintext.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Thrown by [Aead.decrypt] when the Poly1305 tag fails to verify.
///
/// This is the integrity signal that plain SSS lacks: a tampered share, a
/// tampered blob, an under-threshold reconstruction, or shares from different
/// distributions will all manifest here.
class AeadAuthenticationError implements Exception {
  final String message;
  AeadAuthenticationError([
    this.message = 'AEAD authentication failed',
  ]);

  @override
  String toString() => 'AeadAuthenticationError: $message';
}

/// ChaCha20-Poly1305 AEAD with random 96-bit nonces.
///
/// Static-only helper. Each call constructs a fresh cipher instance;
/// pointycastle ciphers are stateful and not reusable across calls.
class Aead {
  /// 256-bit content-encryption key — what gets split via Shamir.
  static const keySize = 32;

  /// 96-bit per-message nonce, generated fresh on every [encrypt] call.
  static const nonceSize = 12;

  /// 128-bit Poly1305 authentication tag, appended to the ciphertext.
  static const tagSize = 16;

  /// Generate a fresh 32-byte CEK using [Random.secure] (or [random] for tests).
  static Uint8List generateKey([Random? random]) {
    final r = random ?? Random.secure();
    return _randomBytes(keySize, r);
  }

  /// Encrypt [plaintext] under [key] with a freshly-generated random nonce.
  ///
  /// Returns `nonce || ciphertext || tag`. The nonce is prepended so the
  /// bundle is self-contained — callers don't carry nonce as a separate
  /// field.
  static Uint8List encrypt(
    Uint8List key,
    Uint8List plaintext, {
    Random? random,
  }) {
    if (key.length != keySize) {
      throw ArgumentError('AEAD key must be $keySize bytes, got ${key.length}');
    }
    final nonce = _randomBytes(nonceSize, random ?? Random.secure());
    final cipher = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305());
    cipher.init(
      true,
      AEADParameters(KeyParameter(key), tagSize * 8, nonce, Uint8List(0)),
    );

    final output = Uint8List(plaintext.length + tagSize);
    var written = cipher.processBytes(
      plaintext,
      0,
      plaintext.length,
      output,
      0,
    );
    written += cipher.doFinal(output, written);

    final bundle = Uint8List(nonceSize + written);
    bundle.setRange(0, nonceSize, nonce);
    bundle.setRange(nonceSize, nonceSize + written, output, 0);
    return bundle;
  }

  /// Decrypt a bundle produced by [encrypt]. Throws [AeadAuthenticationError]
  /// when the Poly1305 tag does not verify; the caller MUST NOT treat any
  /// returned bytes as authentic on that path.
  ///
  /// Also throws [ArgumentError] for malformed inputs (wrong key size,
  /// truncated bundle) — those are programmer errors, not integrity failures.
  static Uint8List decrypt(Uint8List key, Uint8List bundle) {
    if (key.length != keySize) {
      throw ArgumentError('AEAD key must be $keySize bytes, got ${key.length}');
    }
    if (bundle.length < nonceSize + tagSize) {
      throw ArgumentError(
        'AEAD bundle too short: need ≥ ${nonceSize + tagSize} bytes, '
        'got ${bundle.length}',
      );
    }

    final nonce = bundle.sublist(0, nonceSize);
    final ctAndTag = bundle.sublist(nonceSize);

    final cipher = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305());
    cipher.init(
      false,
      AEADParameters(KeyParameter(key), tagSize * 8, nonce, Uint8List(0)),
    );

    final output = Uint8List(ctAndTag.length - tagSize);
    try {
      var written = cipher.processBytes(
        ctAndTag,
        0,
        ctAndTag.length,
        output,
        0,
      );
      written += cipher.doFinal(output, written);
      // doFinal returns the count actually written; for ChaCha20-Poly1305
      // this equals ctAndTag.length - tagSize so output is fully populated.
      return written == output.length ? output : output.sublist(0, written);
    } on ArgumentError catch (e) {
      // pointycastle signals tag mismatch via ArgumentError('mac check ...').
      // Translate to a dedicated type so call sites can distinguish "tampered
      // or wrong key" from genuine input-validation errors.
      final msg = e.message?.toString() ?? '';
      if (msg.contains('mac check')) {
        throw AeadAuthenticationError(
          'ChaCha20-Poly1305 tag mismatch (tampered share/blob, '
          'wrong key, or insufficient shares)',
        );
      }
      rethrow;
    }
  }

  static Uint8List _randomBytes(int n, Random random) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = random.nextInt(256);
    }
    return out;
  }
}
