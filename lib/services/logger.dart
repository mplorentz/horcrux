import 'package:logger/logger.dart';

/// Custom printer that puts time inline with the log message
class InlineTimePrinter extends LogPrinter {
  final bool colors;
  final bool printEmojis;

  InlineTimePrinter({this.colors = true, this.printEmojis = true});

  @override
  List<String> log(LogEvent event) {
    final time = DateTime.now();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';

    final emoji = _getEmoji(event.level);
    final levelColor = _getLevelColor(event.level);

    String message = '$timeStr $emoji ${event.message}';

    if (colors) {
      message = '$levelColor$message\x1B[0m';
    }

    final output = <String>[message];

    // Add error information if present
    if (event.error != null) {
      final errorColor = colors ? levelColor : '';
      final resetColor = colors ? '\x1B[0m' : '';
      output.add('$errorColor  Error: ${event.error}$resetColor');
    }

    // Add stack trace if present
    if (event.stackTrace != null) {
      final traceColor = colors ? '\x1B[38;5;244m' : ''; // Gray
      final resetColor = colors ? '\x1B[0m' : '';
      final stackLines = event.stackTrace.toString().split('\n');
      for (final line in stackLines) {
        if (line.isNotEmpty) {
          output.add('$traceColor  $line$resetColor');
        }
      }
    }

    return output;
  }

  String _getEmoji(Level level) {
    if (!printEmojis) return '';

    switch (level) {
      case Level.trace:
        return '';
      case Level.debug:
        return '🐛';
      case Level.info:
        return '💡';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '⛔';
      case Level.fatal:
        return '👾';
      case Level.all:
        return '📋';
      default:
        return '';
    }
  }

  String _getLevelColor(Level level) {
    switch (level) {
      case Level.trace:
        return '\x1B[38;5;244m'; // Gray
      case Level.debug:
        return '\x1B[38;5;12m'; // Blue
      case Level.info:
        return '\x1B[38;5;12m'; // Blue
      case Level.warning:
        return '\x1B[38;5;208m'; // Orange
      case Level.error:
        return '\x1B[38;5;196m'; // Red
      case Level.fatal:
        return '\x1B[38;5;199m'; // Magenta
      case Level.all:
        return '\x1B[38;5;15m'; // White
      default:
        return '\x1B[38;5;15m'; // White
    }
  }
}

/// Centralized logging service for the Horcrux application.
///
/// This service provides a consistent logging interface throughout the app
/// with configurable log levels and formatting.
class Log {
  static final Logger _logger = Logger(
    printer: InlineTimePrinter(colors: true, printEmojis: true),
  );

  /// Log trace messages (most detailed level)
  static void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log debug messages
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log informational messages
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal failure messages
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
