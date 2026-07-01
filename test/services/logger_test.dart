import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/logger.dart';
import 'package:logger/logger.dart';

/// A [LogOutput] that captures all output events for verification.
class CapturingLogOutput extends LogOutput {
  final List<String> lines = [];

  @override
  void output(OutputEvent event) {
    lines.addAll(event.lines);
  }
}

void main() {
  group('Log', () {
    test('writes to a configured output', () async {
      final output = CapturingLogOutput();
      Log.configureOutput(output);
      Log.info('hello from test');

      // Give the logger micro-task time to flush.
      await Future<void>.delayed(Duration.zero);

      expect(output.lines, isNotEmpty);
      expect(output.lines.any((l) => l.contains('hello from test')), isTrue);
    });

    test('output is empty when no message is logged', () async {
      final output = CapturingLogOutput();
      Log.configureOutput(output);
      // Do not log anything.
      expect(output.lines, isEmpty);
    });

    test('multiple log levels all reach the output', () async {
      final output = CapturingLogOutput();
      Log.configureOutput(output);
      Log.trace('trace msg');
      Log.debug('debug msg');
      Log.info('info msg');
      Log.warning('warn msg');
      Log.error('error msg');

      await Future<void>.delayed(Duration.zero);

      expect(
        output.lines.where((l) => l.contains('trace msg')),
        hasLength(1),
      );
      expect(
        output.lines.where((l) => l.contains('debug msg')),
        hasLength(1),
      );
      expect(
        output.lines.where((l) => l.contains('info msg')),
        hasLength(1),
      );
      expect(
        output.lines.where((l) => l.contains('warn msg')),
        hasLength(1),
      );
      expect(
        output.lines.where((l) => l.contains('error msg')),
        hasLength(1),
      );
    });
  });
}
