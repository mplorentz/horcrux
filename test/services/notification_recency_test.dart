import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/notification_recency.dart';

void main() {
  group('isEventRecent', () {
    final firstOpen = DateTime.utc(2026, 4, 1, 12, 0);

    test('matches slack window', () {
      expect(
        isEventRecent(DateTime.utc(2026, 3, 1), firstOpen),
        isFalse,
      );
      expect(
        isEventRecent(DateTime.utc(2026, 4, 1, 11, 30), firstOpen),
        isTrue,
      );
      expect(
        isEventRecent(DateTime.utc(2026, 4, 1, 13), firstOpen),
        isTrue,
      );
    });

    test('slack is one hour before first open', () {
      expect(eventRecencySlack, const Duration(hours: 1));
    });
  });
}
