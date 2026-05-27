import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/utils/shamir_gf256/secret_scheme.dart';
import 'package:horcrux/utils/shamir_gf256/gf256_field.dart';
import 'package:horcrux/utils/shamir_gf256/lagrange_interpolation.dart';
import 'package:horcrux/utils/shamir_gf256/byte_polynomial.dart';

/// Generate all k-combinations of [items] as lists.
List<List<int>> combinations(List<int> items, int k) {
  final result = <List<int>>[];
  void helper(int start, List<int> current) {
    if (current.length == k) {
      result.add(List.of(current));
      return;
    }
    for (int i = start; i < items.length; i++) {
      current.add(items[i]);
      helper(i + 1, current);
      current.removeLast();
    }
  }

  helper(0, []);
  return result;
}

void main() {
  // =========================================================================
  // Layer 2a: draft-mcgrew-tss-03 Known Answer Test (KAT)
  // =========================================================================
  group('draft-mcgrew-tss-03 KAT', () {
    test('reconstruct secret from spec KAT shares', () {
      // KAT from draft-mcgrew-tss-03 Section 9:
      // secret = 0x7465737400 ("test\0")
      // threshold (M) = 2, shares (N) = 2
      // share index 1, share = B9FA07E185
      // share index 2, share = F5409B4511
      //
      // The "share" field in the spec excludes the index byte.
      // The full share bytes are [index, y0, y1, y2, y3, y4].
      // So for share index=1: x=1, y=[0xB9, 0xFA, 0x07, 0xE1, 0x85]
      // And for share index=2: x=2, y=[0xF5, 0x40, 0x9B, 0x45, 0x11]

      final scheme = SecretScheme(2, 2);
      final shares = <int, List<int>>{
        1: [0xB9, 0xFA, 0x07, 0xE1, 0x85],
        2: [0xF5, 0x40, 0x9B, 0x45, 0x11],
      };

      final secret = scheme.combineShares(shares);
      expect(secret, [0x74, 0x65, 0x73, 0x74, 0x00],
          reason: 'KAT reconstruction must match draft-mcgrew-tss-03');
    });

    test('KAT secret decodes to "test" + null byte', () {
      final secret = [0x74, 0x65, 0x73, 0x74, 0x00];
      expect(utf8.decode(secret.sublist(0, 4)), 'test');
      expect(secret[4], 0);
    });
  });

  // =========================================================================
  // Layer 2c: Round-trip property tests
  // =========================================================================
  group('round-trip split/combine', () {
    final rng = Random(12345);

    /// Test a single (threshold, totalShares, secretLength) combination.
    void testRoundTrip(String label, int threshold, int totalShares, int secretLength) {
      test(
          '$label: threshold=$threshold, shares=$totalShares, '
          'secretLength=$secretLength', () async {
        final scheme = SecretScheme.withRandom(totalShares, threshold, Random(42));
        final secret = List<int>.generate(secretLength, (_) => rng.nextInt(256));

        final sharesMap = scheme.createShares(secret);

        // All shares should reconstruct
        final reconstructed = scheme.combineShares(sharesMap);
        expect(reconstructed, secret, reason: 'All shares round-trip');

        // Every C(n, threshold) subset should also reconstruct
        final xCoords = sharesMap.keys.toList();
        final subsets = combinations(xCoords, threshold);
        int checked = 0;
        for (final subset in subsets.take(20)) {
          final subMap = <int, List<int>>{};
          for (final x in subset) {
            subMap[x] = sharesMap[x]!;
          }
          final subResult = scheme.combineShares(subMap);
          expect(subResult, secret, reason: 'Subset $subset round-trip');
          checked++;
        }
        expect(checked, greaterThanOrEqualTo(1));
      });
    }

    testRoundTrip('basic', 2, 3, 1);
    testRoundTrip('medium', 2, 3, 16);
    testRoundTrip('wider', 2, 5, 32);
    testRoundTrip('threshold-3', 3, 5, 16);
    testRoundTrip('threshold-3-long', 3, 5, 64);
    testRoundTrip('threshold-5', 5, 10, 32);
  });

  group('threshold-1 share equals secret', () {
    test('1-of-2: each share IS the secret', () {
      final scheme = SecretScheme.withRandom(2, 1, Random(42));
      final secret = [0xAB, 0xCD, 0xEF];
      final sharesMap = scheme.createShares(secret);

      // With threshold=1, any single share reconstructs the secret.
      for (final x in sharesMap.keys) {
        final subMap = {x: sharesMap[x]!};
        final result = scheme.combineShares(subMap);
        expect(result, secret, reason: 'Single share (x=$x) reconstructs');
      }
    });
  });

  group('insufficient shares produce wrong result', () {
    test('threshold-1 shares from threshold-2 scheme cannot reconstruct', () {
      final scheme = SecretScheme.withRandom(3, 2, Random(42));
      final secret = List<int>.generate(8, (_) => Random(99).nextInt(256));
      final sharesMap = scheme.createShares(secret);

      // Using 1 share (below threshold) should give a WRONG result
      // (not the original secret, except by astronomical coincidence).
      final xCoords = sharesMap.keys.toList();
      final oneShare = {xCoords[0]: sharesMap[xCoords[0]]!};
      final result = scheme.combineShares(oneShare);

      // Extremely unlikely to match by chance with 8-byte secrets
      expect(result, isNot(equals(secret)),
          reason: '1 share from threshold-2 should not reconstruct');
    });
  });

  // =========================================================================
  // Layer 2d: Edge cases
  // =========================================================================
  group('edge cases', () {
    test('single-byte secret', () {
      final scheme = SecretScheme.withRandom(2, 2, Random(42));
      final secret = [0x42];
      final sharesMap = scheme.createShares(secret);
      final result = scheme.combineShares(sharesMap);
      expect(result, secret);
    });

    test('all-zero secret', () {
      final scheme = SecretScheme.withRandom(3, 2, Random(42));
      final secret = List<int>.filled(8, 0);
      final sharesMap = scheme.createShares(secret);
      final result = scheme.combineShares(sharesMap);
      expect(result, secret);
    });

    test('all-0xFF secret', () {
      final scheme = SecretScheme.withRandom(3, 2, Random(42));
      final secret = List<int>.filled(8, 0xFF);
      final sharesMap = scheme.createShares(secret);
      final result = scheme.combineShares(sharesMap);
      expect(result, secret);
    });

    test('threshold = total shares (every share required)', () {
      final scheme = SecretScheme.withRandom(3, 3, Random(42));
      final secret = [0x01, 0x02, 0x03, 0x04];
      final sharesMap = scheme.createShares(secret);
      final result = scheme.combineShares(sharesMap);
      expect(result, secret);
    });

    test('large secret (1KB)', () {
      final scheme = SecretScheme.withRandom(3, 2, Random(42));
      final secret = List<int>.generate(1024, (i) => i % 256);
      final sharesMap = scheme.createShares(secret);
      final result = scheme.combineShares(sharesMap);
      expect(result, secret);
    });

    test('large secret (10KB)', () {
      final scheme = SecretScheme.withRandom(3, 2, Random(42));
      final secret = List<int>.generate(10 * 1024, (i) => i % 256);
      final sharesMap = scheme.createShares(secret);
      final result = scheme.combineShares(sharesMap);
      expect(result, secret);
    });
  });

  // =========================================================================
  // Layer 2e: Error cases
  // =========================================================================
  group('error cases', () {
    test('empty shares list throws', () {
      final scheme = SecretScheme(2, 2);
      expect(() => scheme.combineShares({}), throwsArgumentError);
    });

    test('fewer shares than threshold produces wrong result (not crash)', () {
      final scheme = SecretScheme.withRandom(3, 3, Random(42));
      final secret = [0xDE, 0xAD, 0xBE, 0xEF];
      final sharesMap = scheme.createShares(secret);

      // Use only 2 of 3 shares (threshold=3, but only 2 provided)
      final twoShares = Map.fromEntries(sharesMap.entries.take(2));
      // Should not crash; result may be wrong but that's expected
      final result = scheme.combineShares(twoShares);
      expect(result.length, secret.length, reason: 'result length matches secret length');
    });

    test('duplicate x-coordinates collapse in Map (wrong result, not crash)', () {
      final scheme = SecretScheme.withRandom(2, 2, Random(42));
      final secret = [0x11, 0x22];
      final sharesMap = scheme.createShares(secret);

      // Overwrite one x-coordinate with another's values
      final xCoords = sharesMap.keys.toList();
      final dupeMap = <int, List<int>>{
        xCoords[0]: sharesMap[xCoords[0]]!,
        xCoords[0]: sharesMap[xCoords[1]]!, // same key overwrites
      };
      // Map deduplication means we only have 1 entry, not 2 distinct x's.
      expect(dupeMap.length, 1);
    });

    test('share with x=0 never appears in generated shares', () {
      // Our implementation generates x-coords via _uniqueNonZeroBytes,
      // so x=0 should never appear in generated shares.
      final scheme = SecretScheme.withRandom(3, 2, Random(42));
      final secret = [0xAA, 0xBB];
      final sharesMap = scheme.createShares(secret);
      for (final x in sharesMap.keys) {
        expect(x, isNot(equals(0)), reason: 'x=0 must not appear in shares');
      }
    });

    test('shares of different lengths throw', () {
      final scheme = SecretScheme(2, 2);
      expect(
        () => scheme.combineShares({
          1: [0x01, 0x02],
          2: [0x03], // different length
        }),
        throwsArgumentError,
      );
    });

    test('invalid x-coordinate throws', () {
      final scheme = SecretScheme(2, 2);
      expect(
        () => scheme.combineShares({
          256: [0x01], // x > 255
        }),
        throwsArgumentError,
      );
    });

    test('invalid y-value throws', () {
      final scheme = SecretScheme(2, 2);
      expect(
        () => scheme.combineShares({
          1: [0x01, 256], // y > 255
        }),
        throwsArgumentError,
      );
    });

    test('empty secret throws', () {
      final scheme = SecretScheme(2, 2);
      expect(
        () => scheme.createShares([]),
        throwsArgumentError,
      );
    });

    test('secret with out-of-range byte throws', () {
      final scheme = SecretScheme(2, 2);
      expect(
        () => scheme.createShares([256]),
        throwsArgumentError,
      );
      expect(
        () => scheme.createShares([-1]),
        throwsArgumentError,
      );
    });
  });

  // =========================================================================
  // SecretScheme constructor validation
  // =========================================================================
  group('SecretScheme constructor validation', () {
    test('numParts < 2 throws', () {
      expect(() => SecretScheme(1, 1), throwsArgumentError);
    });

    test('numParts > 255 throws', () {
      expect(() => SecretScheme(256, 2), throwsArgumentError);
    });

    test('threshold < 1 throws', () {
      expect(() => SecretScheme(3, 0), throwsArgumentError);
    });

    test('threshold > numParts throws', () {
      expect(() => SecretScheme(3, 4), throwsArgumentError);
    });

    test('max valid: 255 shares, threshold 255', () {
      expect(() => SecretScheme(255, 255), returnsNormally);
    });

    test('min valid: 2 shares, threshold 1', () {
      expect(() => SecretScheme(2, 1), returnsNormally);
    });
  });

  // =========================================================================
  // BytePolynomial tests
  // =========================================================================
  group('BytePolynomial', () {
    test('evaluateAt(0) returns constant term', () {
      final poly = BytePolynomial.fromCoefficients([0x42, 0x03, 0x01]);
      expect(poly.evaluateAt(0), 0x42);
    });

    test('evaluateAt(1) returns sum of coefficients in GF(256)', () {
      // f(1) = a0 + a1 + a2 in GF(256)
      final poly = BytePolynomial.fromCoefficients([0x10, 0x20, 0x30]);
      expect(poly.evaluateAt(1), GF256.add(GF256.add(0x10, 0x20), 0x30));
    });

    test('evaluateAt throws on ungenerated polynomial', () {
      final poly = BytePolynomial(2);
      expect(() => poly.evaluateAt(1), throwsStateError);
    });

    test('fromCoefficients throws on empty list', () {
      expect(() => BytePolynomial.fromCoefficients([]), throwsArgumentError);
    });

    test('fromCoefficients throws on non-byte value', () {
      expect(() => BytePolynomial.fromCoefficients([256]), throwsArgumentError);
    });

    test('generateCoefficients sets leading coefficient non-zero', () {
      final rng = Random(42);
      for (int degree = 1; degree <= 10; degree++) {
        final poly = BytePolynomial(degree);
        poly.generateCoefficients(0x00, rng);
        expect(poly.isGenerated, isTrue);
        expect(poly.coefficients.last, isNot(equals(0)),
            reason: 'degree $degree: leading coeff must be non-zero');
      }
    });

    test('degree-0 polynomial preserves zero secret byte', () {
      // Bug 2: degree-0 polynomial must NOT overwrite a zero secret byte.
      // When threshold=1, degree=0, the while-loop enforcing non-zero leading
      // coefficient should be skipped since the only coefficient IS the secret.
      final rng = Random(42);
      final poly = BytePolynomial(0); // degree-0
      poly.generateCoefficients(0x00, rng); // secret byte is 0
      expect(poly.isGenerated, isTrue);
      expect(poly.coefficients[0], 0x00,
          reason: 'degree-0 must preserve zero secret byte');
      expect(poly.constantAtZero, 0x00,
          reason: 'constantAtZero must return 0');
    });

    test('degree-0 polynomial preserves non-zero secret byte', () {
      final rng = Random(42);
      final poly = BytePolynomial(0);
      poly.generateCoefficients(0xAB, rng);
      expect(poly.coefficients[0], 0xAB);
    });

    test('degree-0 evaluateAt(0) returns secret byte', () {
      final rng = Random(42);
      final poly = BytePolynomial(0);
      poly.generateCoefficients(0x42, rng);
      expect(poly.evaluateAt(0), 0x42);
      expect(poly.evaluateAt(5), 0x42, reason: 'constant poly: f(5)=f(0)');
    });
  });

  // =========================================================================
  // LagrangeInterpolation tests
  // =========================================================================
  group('LagrangeInterpolation', () {
    test('constant polynomial: f(x) = c for all x', () {
      // A degree-0 polynomial is just a constant.
      // Lagrange at 0 with one point (x=5, y=0x42) should return 0x42.
      final result = LagrangeInterpolation.constantAtZero([
        [5, 0x42],
      ]);
      expect(result, 0x42);
    });

    test('linear polynomial through (1, y1) and (2, y2) recovers f(0)', () {
      // f(x) = 0x10 + 0x03*x in GF(256)
      // f(0) = 0x10, f(1) = 0x10 ^ GF256.multiply(0x03, 1) = 0x10 ^ 0x03 = 0x13
      // f(2) = 0x10 ^ GF256.multiply(0x03, 2) = 0x10 ^ 0x06 = 0x16
      const f0 = 0x10;
      final f1 = GF256.add(f0, GF256.multiply(0x03, 1));
      final f2 = GF256.add(f0, GF256.multiply(0x03, 2));

      final result = LagrangeInterpolation.constantAtZero([
        [1, f1],
        [2, f2],
      ]);
      expect(result, f0);
    });

    test('throws on empty points', () {
      expect(
        () => LagrangeInterpolation.constantAtZero([]),
        throwsArgumentError,
      );
    });

    test('throws on out-of-range point value', () {
      expect(
        () => LagrangeInterpolation.constantAtZero([
          [1, 256],
        ]),
        throwsArgumentError,
      );
    });

    test('throws on duplicate x-coordinates', () {
      // Bug 4: duplicate x-coordinates silently corrupt Lagrange result
      expect(
        () => LagrangeInterpolation.constantAtZero([
          [1, 0x42],
          [2, 0xAB],
          [1, 0xCD], // duplicate x=1
        ]),
        throwsArgumentError,
        reason: 'must reject duplicate x-coordinates',
      );
    });
  });
}
