import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/nostr_kinds.dart';

void main() {
  group('NostrKind', () {
    test('enum values have correct integer mappings', () {
      expect(NostrKind.seal.value, 13);
      expect(NostrKind.giftWrap.value, 1059);
      expect(NostrKind.httpAuth.value, 27235);
      expect(NostrKind.shareData.value, 713);
      expect(NostrKind.recoveryRequest.value, 714);
      expect(NostrKind.recoveryResponse.value, 715);
    });

    test('fromValue returns correct enum for valid values', () {
      expect(NostrKind.fromValue(13), NostrKind.seal);
      expect(NostrKind.fromValue(1059), NostrKind.giftWrap);
      expect(NostrKind.fromValue(27235), NostrKind.httpAuth);
      expect(NostrKind.fromValue(713), NostrKind.shareData);
      expect(NostrKind.fromValue(714), NostrKind.recoveryRequest);
      expect(NostrKind.fromValue(715), NostrKind.recoveryResponse);
    });

    test('fromValue returns null for invalid values', () {
      expect(NostrKind.fromValue(999), isNull);
      expect(NostrKind.fromValue(1), isNull);
      expect(NostrKind.fromValue(4), isNull);
    });

    test('isCustom correctly identifies Horcrux custom kinds', () {
      expect(NostrKind.seal.isCustom, isFalse);
      expect(NostrKind.giftWrap.isCustom, isFalse);
      expect(NostrKind.httpAuth.isCustom, isFalse);
      expect(NostrKind.shareData.isCustom, isTrue);
      expect(NostrKind.recoveryRequest.isCustom, isTrue);
      expect(NostrKind.recoveryResponse.isCustom, isTrue);
    });

    test('isStandard correctly identifies standard NIP kinds', () {
      expect(NostrKind.seal.isStandard, isTrue);
      expect(NostrKind.giftWrap.isStandard, isTrue);
      expect(NostrKind.httpAuth.isStandard, isTrue);
      expect(NostrKind.shareData.isStandard, isFalse);
      expect(NostrKind.recoveryRequest.isStandard, isFalse);
      expect(NostrKind.recoveryResponse.isStandard, isFalse);
    });

    test('toString returns formatted string', () {
      expect(NostrKind.seal.toString(), 'NostrKind.seal(13)');
      expect(NostrKind.giftWrap.toString(), 'NostrKind.giftWrap(1059)');
      expect(NostrKind.shareData.toString(), 'NostrKind.shareData(713)');
      expect(
        NostrKind.recoveryRequest.toString(),
        'NostrKind.recoveryRequest(714)',
      );
      expect(
        NostrKind.recoveryResponse.toString(),
        'NostrKind.recoveryResponse(715)',
      );
    });

    test('toInt extension method works correctly', () {
      expect(NostrKind.seal.toInt(), 13);
      expect(NostrKind.giftWrap.toInt(), 1059);
      expect(NostrKind.httpAuth.toInt(), 27235);
      expect(NostrKind.shareData.toInt(), 713);
      expect(NostrKind.recoveryRequest.toInt(), 714);
      expect(NostrKind.recoveryResponse.toInt(), 715);
    });

    test('all enum values are unique', () {
      final values = NostrKind.values.map((k) => k.value).toList();
      final uniqueValues = values.toSet();
      expect(
        values.length,
        uniqueValues.length,
        reason: 'All NostrKind values should be unique',
      );
    });
  });
}
