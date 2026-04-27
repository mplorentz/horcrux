import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/utils/date_time_extensions.dart';

void main() {
  group('DateTimeExtension.secondsSinceEpoch', () {
    test('returns floor of ms/1000 for a fixed UTC instant', () {
      final t = DateTime.utc(2026, 4, 21, 12, 0, 0);
      // 2026-04-21T12:00:00Z → 1776772800 (verified via
      // `date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "2026-04-21T12:00:00Z" +%s`).
      expect(t.secondsSinceEpoch, 1776772800);
    });

    test('truncates sub-second precision (floor, not round)', () {
      final t = DateTime.fromMillisecondsSinceEpoch(1776772800999, isUtc: true);
      expect(t.secondsSinceEpoch, 1776772800);
    });

    test('is timezone-independent: local vs UTC yield the same integer', () {
      final local = DateTime(2026, 4, 21, 12, 0, 0);
      expect(local.secondsSinceEpoch, local.toUtc().secondsSinceEpoch);
    });

    test('epoch itself is zero', () {
      expect(
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).secondsSinceEpoch,
        0,
      );
    });

    test('matches manual ms/1000 for DateTime.now()', () {
      final now = DateTime.now();
      expect(now.secondsSinceEpoch, now.millisecondsSinceEpoch ~/ 1000);
    });
  });

  group('secondsSinceEpoch()', () {
    test('returns a value close to DateTime.now().secondsSinceEpoch', () {
      final before = DateTime.now().secondsSinceEpoch;
      final result = secondsSinceEpoch();
      final after = DateTime.now().secondsSinceEpoch;
      expect(result, greaterThanOrEqualTo(before));
      expect(result, lessThanOrEqualTo(after));
    });
  });
}
