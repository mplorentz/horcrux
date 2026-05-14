import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/utils/date_time_extensions.dart';

Share _validRealShare() {
  return Share(
    payload: 'not-empty-payload',
    threshold: 2,
    shareIndex: 0,
    totalShares: 3,
    primeMod: 'abc',
    creatorPubkey: 'a' * 64,
    createdAt: secondsSinceEpoch(),
    vaultId: 'vault-1',
  );
}

void main() {
  group('Share.isManifest', () {
    test('true only for empty payload and shareIndex -1', () {
      final m = Share(
        payload: '',
        threshold: 2,
        shareIndex: -1,
        totalShares: 3,
        primeMod: 'abc',
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(m.isManifest, isTrue);

      expect(_validRealShare().isManifest, isFalse);
      expect(
        Share(
          payload: '',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          primeMod: 'abc',
          creatorPubkey: 'a' * 64,
          createdAt: secondsSinceEpoch(),
        ).isManifest,
        isFalse,
      );
    });
  });

  group('Share.isValid', () {
    test('accepts manifest-shaped share', () {
      final m = Share(
        payload: '',
        threshold: 2,
        shareIndex: -1,
        totalShares: 3,
        primeMod: 'abc',
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
        stewards: [
          {'name': 'Bob', 'pubkey': 'b' * 64},
        ],
      );
      expect(m.isValid, isTrue);
    });

    test('rejects empty payload unless manifest', () {
      final bad = Share(
        payload: '',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        primeMod: 'abc',
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(bad.isValid, isFalse);
    });

    test('rejects manifest with wrong shareIndex', () {
      final bad = Share(
        payload: 'x',
        threshold: 2,
        shareIndex: -2,
        totalShares: 3,
        primeMod: 'abc',
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(bad.isValid, isFalse);
    });

    test('rejects manifest with shareIndex -1 but non-empty payload', () {
      final bad = Share(
        payload: 'x',
        threshold: 2,
        shareIndex: -1,
        totalShares: 3,
        primeMod: 'abc',
        creatorPubkey: 'a' * 64,
        createdAt: secondsSinceEpoch(),
      );
      expect(bad.isValid, isFalse);
    });
  });
}
