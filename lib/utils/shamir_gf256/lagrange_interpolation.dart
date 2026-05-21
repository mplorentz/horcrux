/// Lagrange interpolation over GF(256) — evaluates f(0) from a set of points.
///
/// Forked from [dart_ssss](https://github.com/gching/dart_ssss) (MIT license).
library;

import 'gf256_field.dart';

/// Lagrange interpolation over GF(256).
///
/// Given a set of (x, y) points, computes the constant term f(0) by
/// interpolating the polynomial at x=0.
class LagrangeInterpolation {
  LagrangeInterpolation._();

  /// Compute f(0) from the given [points] using Lagrange interpolation.
  ///
  /// Each point is `[x, y]` where both values are bytes.
  static int constantAtZero(List<List<int>> points) {
    _validate(points);

    const int xTarget = 0;
    int result = 0;

    for (int i = 0; i < points.length; i++) {
      final xI = points[i][0];
      final yI = points[i][1];
      int lagrange = 1;

      for (int j = 0; j < points.length; j++) {
        if (i == j) continue;
        final xJ = points[j][0];
        lagrange = GF256.multiply(
          lagrange,
          GF256.divide(GF256.sub(xTarget, xJ), GF256.sub(xI, xJ)),
        );
      }

      result = GF256.add(result, GF256.multiply(yI, lagrange));
    }

    return result;
  }

  static void _validate(List<List<int>> points) {
    if (points.isEmpty) {
      throw ArgumentError('At least one point is required');
    }
    for (final p in points) {
      if (p.length != 2) {
        throw ArgumentError('Each point must be [x, y]');
      }
      for (final v in p) {
        if (v < 0 || v > 255) {
          throw ArgumentError('All point values must be bytes (0–255)');
        }
      }
    }
  }
}
