import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/utils/crypto/aead.dart';

void main() {
  group('Aead', () {
    test('round-trip recovers plaintext', () {
      final key = Aead.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('hello vault'));
      final bundle = Aead.encrypt(key, plaintext);
      final recovered = Aead.decrypt(key, bundle);
      expect(recovered, equals(plaintext));
    });

    test('generateKey returns 32 bytes', () {
      expect(Aead.generateKey().length, equals(Aead.keySize));
    });

    test('encrypt rejects non-32-byte keys', () {
      expect(
        () => Aead.encrypt(Uint8List(16), Uint8List.fromList([1, 2, 3])),
        throwsArgumentError,
      );
    });

    test('decrypt rejects non-32-byte keys', () {
      expect(
        () => Aead.decrypt(Uint8List(16), Uint8List(40)),
        throwsArgumentError,
      );
    });

    test('decrypt rejects bundles smaller than nonce+tag', () {
      final key = Aead.generateKey();
      expect(
        () => Aead.decrypt(key, Uint8List(Aead.nonceSize + Aead.tagSize - 1)),
        throwsArgumentError,
      );
    });

    test('bundle layout: nonce || ciphertext || tag', () {
      final key = Aead.generateKey();
      final plaintext = Uint8List.fromList(List<int>.generate(40, (i) => i));
      final bundle = Aead.encrypt(key, plaintext);
      // Bundle is nonce(12) + ct(40) + tag(16) = 68
      expect(
        bundle.length,
        equals(Aead.nonceSize + plaintext.length + Aead.tagSize),
      );
    });

    test('encrypting the same plaintext twice yields different ciphertexts', () {
      // Nonce is random per-call, so identical plaintexts must not produce
      // identical bundles. (Catches the "forgot to regenerate nonce" bug.)
      final key = Aead.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('same input'));
      final a = Aead.encrypt(key, plaintext);
      final b = Aead.encrypt(key, plaintext);
      expect(a, isNot(equals(b)));
      // But both decrypt back to the same plaintext.
      expect(Aead.decrypt(key, a), equals(plaintext));
      expect(Aead.decrypt(key, b), equals(plaintext));
    });

    test('tampered ciphertext throws AeadAuthenticationError', () {
      final key = Aead.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('hello'));
      final bundle = Aead.encrypt(key, plaintext);
      // Flip a bit in the ciphertext region (after the 12-byte nonce, before
      // the 16-byte tag).
      final tampered = Uint8List.fromList(bundle);
      tampered[Aead.nonceSize] ^= 0x01;
      expect(
        () => Aead.decrypt(key, tampered),
        throwsA(isA<AeadAuthenticationError>()),
      );
    });

    test('tampered tag throws AeadAuthenticationError', () {
      final key = Aead.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('hello'));
      final bundle = Aead.encrypt(key, plaintext);
      final tampered = Uint8List.fromList(bundle);
      tampered[tampered.length - 1] ^= 0x01;
      expect(
        () => Aead.decrypt(key, tampered),
        throwsA(isA<AeadAuthenticationError>()),
      );
    });

    test('tampered nonce throws AeadAuthenticationError', () {
      final key = Aead.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('hello'));
      final bundle = Aead.encrypt(key, plaintext);
      final tampered = Uint8List.fromList(bundle);
      tampered[0] ^= 0x01;
      expect(
        () => Aead.decrypt(key, tampered),
        throwsA(isA<AeadAuthenticationError>()),
      );
    });

    test('wrong key throws AeadAuthenticationError', () {
      final key1 = Aead.generateKey();
      final key2 = Aead.generateKey();
      final bundle = Aead.encrypt(key1, Uint8List.fromList(utf8.encode('hi')));
      expect(
        () => Aead.decrypt(key2, bundle),
        throwsA(isA<AeadAuthenticationError>()),
      );
    });

    test('handles empty plaintext', () {
      final key = Aead.generateKey();
      final bundle = Aead.encrypt(key, Uint8List(0));
      // No payload, just nonce + tag.
      expect(bundle.length, equals(Aead.nonceSize + Aead.tagSize));
      expect(Aead.decrypt(key, bundle), equals(Uint8List(0)));
    });

    test('handles large plaintext (4 KiB)', () {
      // Exercise the BUF_SIZE-aligned path inside pointycastle by going well
      // past the internal 64-byte buffer.
      final key = Aead.generateKey();
      final plaintext = Uint8List.fromList(
        List<int>.generate(4096, (i) => i & 0xff),
      );
      final bundle = Aead.encrypt(key, plaintext);
      expect(Aead.decrypt(key, bundle), equals(plaintext));
    });

    test('generateKey uses provided Random for determinism in tests', () {
      // Sanity check: two seeded sequences from the same seed match.
      final k1 = Aead.generateKey(Random(42));
      final k2 = Aead.generateKey(Random(42));
      expect(k1, equals(k2));
    });
  });
}
