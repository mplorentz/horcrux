/// Horcrux GF(256) Shamir Secret Sharing implementation.
///
/// Forked from [dart_ssss](https://github.com/gching/dart_ssss) (MIT license).
///
/// Uses the Rijndael polynomial x⁸+x⁴+x³+x+1 (0x11b) — the same field as AES,
/// SLIP-0039, ERC-3450, and draft-mcgrew-tss.
library;

export 'secret_scheme.dart';
export 'gf256_field.dart';
export 'lagrange_interpolation.dart';
export 'byte_polynomial.dart';
