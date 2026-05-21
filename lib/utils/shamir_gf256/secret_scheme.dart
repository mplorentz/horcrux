/// Shamir's Secret Sharing Scheme over GF(256).
///
/// Splits a secret byte-sequence into N shares with threshold T, and
/// reconstructs the secret from any T of those shares.
///
/// Forked from [dart_ssss](https://github.com/gching/dart_ssss) (MIT license).
library;

import 'dart:collection';
import 'dart:math';
import 'byte_polynomial.dart';
import 'lagrange_interpolation.dart';

/// Implements Shamir's Secret Sharing over GF(256).
///
/// Maximum shares: 255 (x=0 is reserved for the secret).
/// Minimum threshold: 1.
class SecretScheme {
  final int _numParts;
  final int _threshold;
  final Random _random;

  /// Create a scheme that splits a secret into [numParts] shares, requiring
  /// at least [threshold] shares to reconstruct.
  ///
  /// Uses [Random.secure()] for coefficient generation.
  SecretScheme(this._numParts, this._threshold) : _random = Random.secure() {
    _validate();
  }

  /// Constructor with an explicit [random] source (for testing with seed).
  SecretScheme.withRandom(this._numParts, this._threshold, this._random) {
    _validate();
  }

  int get numParts => _numParts;
  int get threshold => _threshold;

  /// Split [secret] into N shares (where N = [numParts]).
  ///
  /// Returns a map of `{ x: [y₀, y₁, ..., yₙ₋₁] }` where each key is the
  /// share index (x-coordinate) and each value is the corresponding
  /// polynomial evaluation for every byte of the secret.
  Map<int, List<int>> createShares(List<int> secret) {
    if (secret.isEmpty) {
      throw ArgumentError('Secret must contain at least one byte');
    }
    if (!secret.every((b) => b >= 0 && b <= 255)) {
      throw ArgumentError('All secret bytes must be in 0–255');
    }

    final xCoords = _uniqueNonZeroBytes(_numParts);
    final shares = HashMap<int, List<int>>();
    for (final x in xCoords) {
      shares[x] = List<int>.filled(secret.length, 0);
    }

    final degree = _threshold - 1;
    for (int i = 0; i < secret.length; i++) {
      final poly = BytePolynomial(degree);
      poly.generateCoefficients(secret[i], _random);

      for (final x in xCoords) {
        shares[x]![i] = poly.evaluateAt(x);
      }
    }

    return shares;
  }

  /// Reconstruct the secret from [shares] (a map of x → y-byte-list).
  ///
  /// Returns the original secret bytes.
  /// **No integrity check** — malformed or insufficient shares produce garbage.
  List<int> combineShares(Map<int, List<int>> shares) {
    if (shares.isEmpty) {
      throw ArgumentError('At least one share is required');
    }

    // Validate x coordinates
    for (final x in shares.keys) {
      if (x < 0 || x > 255) {
        throw ArgumentError('Invalid x-coordinate: $x');
      }
    }

    // Validate y coordinates and check length consistency
    int? yLength;
    for (final yList in shares.values) {
      if (!yList.every((b) => b >= 0 && b <= 255)) {
        throw ArgumentError('All share values must be bytes (0–255)');
      }
      yLength ??= yList.length;
      if (yList.length != yLength) {
        throw ArgumentError('All shares must have the same byte length');
      }
    }

    final secret = List<int>.filled(yLength!, 0);
    for (int i = 0; i < secret.length; i++) {
      final points = <List<int>>[];
      for (final entry in shares.entries) {
        points.add([entry.key, entry.value[i]]);
      }
      secret[i] = LagrangeInterpolation.constantAtZero(points);
    }

    return secret;
  }

  /// Generate [count] unique non-zero byte values.
  List<int> _uniqueNonZeroBytes(int count) {
    final seen = <int>{};
    final result = List<int>.filled(count, 0);
    int idx = 0;
    while (idx < count) {
      final v = _random.nextInt(256);
      if (v == 0) continue;
      if (!seen.add(v)) continue;
      result[idx] = v;
      idx++;
    }
    return result;
  }

  void _validate() {
    if (_numParts < 2 || _numParts > 255) {
      throw ArgumentError('numParts must be 2–255, got $_numParts');
    }
    if (_threshold < 1) {
      throw ArgumentError('threshold must be ≥ 1, got $_threshold');
    }
    if (_threshold > _numParts) {
      throw ArgumentError(
        'threshold ($_threshold) cannot exceed numParts ($_numParts)',
      );
    }
  }
}
