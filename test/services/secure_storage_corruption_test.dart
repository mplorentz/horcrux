import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/secure_storage_corruption.dart';

void main() {
  group('isPermanentSecureStorageReadFailure', () {
    test('false for non-PlatformException errors', () {
      expect(isPermanentSecureStorageReadFailure(Exception('boom')), isFalse);
      expect(isPermanentSecureStorageReadFailure(StateError('nope')), isFalse);
      expect(isPermanentSecureStorageReadFailure('plain string'), isFalse);
    });

    test('true for BadPaddingException-wrapped PlatformException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, javax.crypto.BadPaddingException: '
            'error:1e000065:Cipher functions:OPENSSL_internal:BAD_DECRYPT',
      );
      expect(isPermanentSecureStorageReadFailure(err), isTrue);
    });

    test('true for InvalidKeyException-wrapped PlatformException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, java.security.InvalidKeyException: Failed',
      );
      expect(isPermanentSecureStorageReadFailure(err), isTrue);
    });

    test('true for UnrecoverableKeyException-wrapped PlatformException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, '
            'java.security.UnrecoverableKeyException: Failed to obtain information about private key',
      );
      expect(isPermanentSecureStorageReadFailure(err), isTrue);
    });

    test('false for transient KeyStoreException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, java.security.KeyStoreException: '
            'AndroidKeyStore not found',
      );
      expect(isPermanentSecureStorageReadFailure(err), isFalse);
    });

    test('false for transient NullPointerException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, java.lang.NullPointerException',
      );
      expect(isPermanentSecureStorageReadFailure(err), isFalse);
    });

    test('false for transient ServiceSpecificException', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'Exception encountered, read, android.os.ServiceSpecificException: code 7',
      );
      expect(isPermanentSecureStorageReadFailure(err), isFalse);
    });

    test('checks details as well as message', () {
      final err = PlatformException(
        code: 'Exception encountered',
        message: 'something generic',
        details: 'wrapped: javax.crypto.BadPaddingException',
      );
      expect(isPermanentSecureStorageReadFailure(err), isTrue);
    });

    test('false for PlatformException with no useful payload', () {
      final err = PlatformException(code: 'Unknown');
      expect(isPermanentSecureStorageReadFailure(err), isFalse);
    });
  });
}
