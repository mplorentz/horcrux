import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/utils/shamir_gf256/gf256_field.dart';

void main() {
  // =========================================================================
  // Layer 1a: EXP/LOG table validation against draft-mcgrew-tss-03
  // =========================================================================
  group('GF256 EXP table', () {
    test('has exactly 255 entries (indices 0..254)', () {
      expect(GF256.exp3.length, 255);
    });

    test('EXP[0] = 0x01 (multiplicative identity)', () {
      expect(GF256.exp3[0], 0x01);
    });

    test('EXP[8] = 0x1a (spec-called-out value)', () {
      expect(GF256.exp3[8], 0x1a);
    });

    test('EXP[1] = 0x03 (generator g=3)', () {
      expect(GF256.exp3[1], 0x03);
    });

    test('all EXP entries are in 0x00–0xFF', () {
      for (int i = 0; i < GF256.exp3.length; i++) {
        expect(GF256.exp3[i], greaterThanOrEqualTo(0));
        expect(GF256.exp3[i], lessThanOrEqualTo(255),
            reason: 'EXP[$i] = ${GF256.exp3[i]}');
      }
    });

    test('EXP table covers all non-zero bytes (bijection check)', () {
      // Every non-zero byte appears exactly once in EXP[0..254].
      // EXP[255] = EXP[0] = 1 because 3^255 = 1 in GF(256).
      final seen = List<int>.filled(256, 0);
      for (int i = 0; i < 255; i++) {
        seen[GF256.exp3[i]]++;
      }
      for (int v = 1; v < 256; v++) {
        expect(seen[v], 1,
            reason: 'byte $v appears ${seen[v]} times in EXP[0..254]');
      }
    });

    test('EXP[254] * 3 == EXP[0] (periodicity: 3^255 == 3^0)', () {
      // 3^255 = 1 in GF(256), so exp3[254]*3 mod poly should equal exp3[0].
      // We can verify via the multiply function.
      expect(GF256.multiply(GF256.exp3[254], 3), GF256.exp3[0]);
    });
  });

  group('GF256 LOG table', () {
    test('has exactly 256 entries', () {
      expect(GF256.log3.length, 256);
    });

    test('LOG[1] = 0 (3^0 = 1)', () {
      expect(GF256.log3[1], 0);
    });

    test('LOG[8] = 75 (spec-called-out value: 3^75 = 8)', () {
      expect(GF256.log3[8], 75);
    });

    test('LOG[0] = 0xFF (undefined sentinel)', () {
      expect(GF256.log3[0], 0xFF);
    });

    test('all LOG entries are in 0x00–0xFF', () {
      for (int i = 0; i < GF256.log3.length; i++) {
        expect(GF256.log3[i], greaterThanOrEqualTo(0));
        expect(GF256.log3[i], lessThanOrEqualTo(255),
            reason: 'LOG[$i] = ${GF256.log3[i]}');
      }
    });

    test('LOG and EXP are inverse for all non-zero bytes', () {
      for (int v = 1; v < 256; v++) {
        expect(GF256.exp3[GF256.log3[v]], v,
            reason: 'EXP[LOG[$v]] != $v');
      }
    });

    test('LOG[EXP[i] mod 255] == i for i in 0..254', () {
      for (int i = 0; i < 255; i++) {
        expect(GF256.log3[GF256.exp3[i]], i,
            reason: 'LOG[EXP[$i]] != $i');
      }
    });
  });

  // =========================================================================
  // Layer 1b: Field operation properties
  // =========================================================================
  group('GF256.add', () {
    test('add is XOR', () {
      final rng = Random(42);
      for (int i = 0; i < 10; i++) {
        final a = rng.nextInt(256);
        final b = rng.nextInt(256);
        expect(GF256.add(a, b), a ^ b, reason: 'add($a, $b)');
      }
    });

    test('add is self-inverse: a + a = 0 for all a in 0..255', () {
      for (int a = 0; a < 256; a++) {
        expect(GF256.add(a, a), 0, reason: 'add($a, $a)');
      }
    });

    test('add is commutative', () {
      final rng = Random(42);
      for (int i = 0; i < 10; i++) {
        final a = rng.nextInt(256);
        final b = rng.nextInt(256);
        expect(GF256.add(a, b), GF256.add(b, a), reason: 'add($a, $b)');
      }
    });

    test('add returns values in 0..255', () {
      for (int a = 0; a < 256; a += 37) {
        for (int b = 0; b < 256; b += 41) {
          final r = GF256.add(a, b);
          expect(r, greaterThanOrEqualTo(0));
          expect(r, lessThanOrEqualTo(255));
        }
      }
    });
  });

  group('GF256.sub', () {
    test('sub equals add (XOR)', () {
      final rng = Random(42);
      for (int i = 0; i < 10; i++) {
        final a = rng.nextInt(256);
        final b = rng.nextInt(256);
        expect(GF256.sub(a, b), GF256.add(a, b), reason: 'sub($a, $b)');
      }
    });
  });

  group('GF256.multiply', () {
    test('multiply by identity: a * 1 == a for all a', () {
      for (int a = 0; a < 256; a++) {
        expect(GF256.multiply(a, 1), a, reason: 'multiply($a, 1)');
      }
    });

    test('multiply by zero: a * 0 == 0 for all a', () {
      for (int a = 0; a < 256; a++) {
        expect(GF256.multiply(a, 0), 0, reason: 'multiply($a, 0)');
      }
    });

    test('multiply is commutative', () {
      final rng = Random(42);
      for (int i = 0; i < 10; i++) {
        final a = rng.nextInt(256);
        final b = rng.nextInt(256);
        expect(GF256.multiply(a, b), GF256.multiply(b, a),
            reason: 'multiply($a, $b)');
      }
    });

    test('multiply returns values in 0..255', () {
      final rng = Random(42);
      for (int i = 0; i < 100; i++) {
        final a = rng.nextInt(256);
        final b = rng.nextInt(256);
        final r = GF256.multiply(a, b);
        expect(r, greaterThanOrEqualTo(0));
        expect(r, lessThanOrEqualTo(255), reason: 'multiply($a, $b) = $r');
      }
    });

    test('multiply via EXP/LOG: a*b == EXP[(LOG[a]+LOG[b]) mod 255]', () {
      final rng = Random(42);
      for (int i = 0; i < 10; i++) {
        int a = rng.nextInt(256);
        int b = rng.nextInt(256);
        if (a == 0 || b == 0) continue;
        final expected = GF256.exp3[(GF256.log3[a] + GF256.log3[b]) % 255];
        expect(GF256.multiply(a, b), expected, reason: 'multiply($a, $b)');
      }
    });
  });

  group('GF256.divide', () {
    test('divide(a, 1) == a for all non-zero a', () {
      for (int a = 1; a < 256; a++) {
        expect(GF256.divide(a, 1), a, reason: 'divide($a, 1)');
      }
    });

    test('divide(0, b) == 0 for all non-zero b', () {
      for (int b = 1; b < 256; b++) {
        expect(GF256.divide(0, b), 0, reason: 'divide(0, $b)');
      }
    });

    test('divide is multiply-inverse: divide(a*b, b) == a', () {
      final rng = Random(42);
      for (int i = 0; i < 10; i++) {
        int a = rng.nextInt(255) + 1; // 1..255
        int b = rng.nextInt(255) + 1; // 1..255
        expect(GF256.divide(GF256.multiply(a, b), b), a,
            reason: 'divide(multiply($a, $b), $b)');
      }
    });

    test('a * inv(a) == 1 for all non-zero a', () {
      for (int a = 1; a < 256; a++) {
        // inv(a) = EXP[(255 - LOG[a]) % 255]
        final inv = GF256.exp3[(255 - GF256.log3[a]) % 255];
        expect(GF256.multiply(a, inv), 1, reason: 'a=$a, inv=$inv');
      }
    });
  });

  group('GF256 input validation', () {
    test('add throws on out-of-range input', () {
      expect(() => GF256.add(256, 0), throwsArgumentError);
      expect(() => GF256.add(-1, 0), throwsArgumentError);
      expect(() => GF256.add(0, 256), throwsArgumentError);
    });

    test('multiply throws on out-of-range input', () {
      expect(() => GF256.multiply(256, 1), throwsArgumentError);
      expect(() => GF256.multiply(1, -1), throwsArgumentError);
    });

    test('divide throws on out-of-range input', () {
      expect(() => GF256.divide(256, 1), throwsArgumentError);
      expect(() => GF256.divide(1, 256), throwsArgumentError);
    });
  });
}
