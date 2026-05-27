/// Polynomial over GF(256) represented by unsigned byte coefficients.
///
/// Forked from [dart_ssss](https://github.com/gching/dart_ssss) (MIT license).
library;

import 'dart:math';
import 'gf256_field.dart';

/// A polynomial over GF(256) with byte-valued coefficients.
///
/// Coefficients are stored with index 0 = f(0) (the constant / secret byte)
/// and index [degree] = the leading coefficient (non-zero).
class BytePolynomial {
  /// The polynomial coefficients where `coefficients[0] = f(0)`.
  late final List<int> _coefficients;

  /// The degree of the polynomial.
  late final int _degree;

  /// Whether coefficients have been generated or provided.
  bool _generated = false;

  /// Create a polynomial of the given [degree].
  BytePolynomial(int degree) : _degree = degree;

  /// Create a polynomial from explicit [coefficients].
  BytePolynomial.fromCoefficients(List<int> coefficients) {
    if (coefficients.isEmpty) {
      throw ArgumentError('Coefficients cannot be empty');
    }
    if (!_allBytes(coefficients)) {
      throw ArgumentError('All coefficients must be bytes (0–255)');
    }
    _degree = _highestDegree(coefficients);
    _coefficients = List<int>.of(coefficients, growable: false);
    _generated = true;
  }

  /// The polynomial degree.
  int get degree => _degree;

  /// Whether coefficients have been set.
  bool get isGenerated => _generated;

  /// The constant term f(0) — the secret byte.
  int get constantAtZero => _generated ? _coefficients[0] : -1;

  /// A copy of the coefficient list.
  List<int> get coefficients => List<int>.of(_coefficients);

  /// Generate random coefficients with [constantVal] at f(0).
  ///
  /// The leading coefficient is guaranteed non-zero (required by SSS).
  /// [random] must be cryptographically secure.
  void generateCoefficients(int constantVal, Random random) {
    if (constantVal < 0 || constantVal > 255) {
      throw ArgumentError('Constant must be a byte (0–255)');
    }

    _coefficients = List<int>.filled(_degree + 1, 0);
    _coefficients[0] = constantVal;

    for (int i = 1; i < _coefficients.length; i++) {
      _coefficients[i] = random.nextInt(256);
    }

    // The leading coefficient must be non-zero (skip for degree-0 where the
    // only coefficient IS the secret byte).
    if (_degree > 0) {
      while (_coefficients.last == 0) {
        _coefficients[_coefficients.length - 1] = random.nextInt(256);
      }
    }

    _generated = true;
  }

  /// Evaluate the polynomial at [x] using Horner's method.
  int evaluateAt(int x) {
    if (x < 0 || x > 255) {
      throw ArgumentError('x must be a byte (0–255)');
    }
    if (!_generated) {
      throw StateError('Polynomial coefficients have not been generated');
    }
    if (x == 0) return constantAtZero;

    int result = 0;
    for (int i = _coefficients.length - 1; i >= 0; i--) {
      result = GF256.add(GF256.multiply(result, x), _coefficients[i]);
    }
    return result;
  }

  /// Check that all values in [vals] are bytes.
  static bool _allBytes(List<int> vals) => vals.every((v) => v >= 0 && v <= 255);

  /// Find the highest degree with a non-zero coefficient.
  static int _highestDegree(List<int> coefficients) {
    for (int i = coefficients.length - 1; i > 0; i--) {
      if (coefficients[i] > 0) return i;
    }
    return 0;
  }
}
