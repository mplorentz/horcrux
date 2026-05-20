import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/logger.dart';

void main() {
  group('Log ring buffer', () {
    setUp(() {
      // The Log class uses a static list, so we need to clear it between tests.
      // Since _recentLogs is private, we'll use the public recentLogs() method
      // to verify behavior. The buffer persists across tests within the same
      // process, so we track counts.
    });

    test('recentLogs returns an unmodifiable list', () {
      final logs = Log.recentLogs();
      expect(() => logs.add('should fail'), throwsA(isA<UnsupportedError>()));
    });

    test('log messages are captured in the ring buffer', () {
      final countBefore = Log.recentLogs().length;
      Log.info('Test ring buffer capture');
      final logs = Log.recentLogs();
      expect(logs.length, greaterThan(countBefore));
      expect(logs.any((l) => l.contains('Test ring buffer capture')), isTrue);
    });

    test('log errors are captured in the ring buffer', () {
      final countBefore = Log.recentLogs().length;
      Log.error('Test error capture', Exception('test'));
      final logs = Log.recentLogs();
      expect(logs.length, greaterThan(countBefore));
      // Error message is captured; the error detail goes on a separate line
      final errorEntries = logs.where((l) => l.contains('Test error capture')).toList();
      expect(errorEntries, isNotEmpty);
    });

    test('ring buffer is bounded to 50 entries', () {
      // Clear the buffer by adding enough entries to push out old ones
      for (int i = 0; i < 55; i++) {
        Log.debug('Ring buffer overflow test $i');
      }
      final logs = Log.recentLogs();
      // The buffer should not exceed 50 entries total
      expect(logs.length, lessThanOrEqualTo(50));
      // The newest entry should be present after overflow
      expect(logs.any((l) => l.contains('Ring buffer overflow test 54')), isTrue);
    });

    test('different log levels are captured', () {
      Log.info('level test info');
      Log.debug('level test debug');
      final logs = Log.recentLogs();
      expect(logs.any((l) => l.contains('level test info')), isTrue);
      expect(logs.any((l) => l.contains('level test debug')), isTrue);
    });
  });
}
