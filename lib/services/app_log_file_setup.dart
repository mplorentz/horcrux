import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'logger.dart';

/// Subdirectory under application support where the persistent log file lives.
const appLogSubdirectoryName = 'logs';

/// Append-only log filename under [appLogSubdirectoryName].
const appLogFileName = 'horcrux.log';

final _ansiEscape = RegExp(r'\x1B\[[0-9;]*m');

/// Removes ANSI SGR sequences so file logs stay readable plain text.
String stripAnsiEscapes(String line) => line.replaceAll(_ansiEscape, '');

/// Delegates to [inner] after stripping ANSI escape codes from each line.
class AnsiStrippingLogOutput extends LogOutput {
  AnsiStrippingLogOutput(this._inner);

  final LogOutput _inner;

  @override
  Future<void> init() => _inner.init();

  @override
  void output(OutputEvent event) {
    final stripped = event.lines.map(stripAnsiEscapes).toList(growable: false);
    _inner.output(OutputEvent(event.origin, stripped));
  }

  @override
  Future<void> destroy() => _inner.destroy();
}

/// Resolved path to the persistent Horcrux log file (may not exist yet).
Future<File> resolvedPersistedLogFile() async {
  final dir = await getApplicationSupportDirectory();
  final logDir = Directory('${dir.path}/$appLogSubdirectoryName');
  if (!await logDir.exists()) {
    await logDir.create(recursive: true);
  }
  return File('${logDir.path}/$appLogFileName');
}

/// Routes logs to the console (with color) and to an append-only plain-text file.
Future<void> initializeAppLogFile() async {
  final file = await resolvedPersistedLogFile();
  Log.configureOutput(
    MultiOutput([
      ConsoleOutput(),
      AnsiStrippingLogOutput(
        FileOutput(file: file, overrideExisting: false),
      ),
    ]),
  );
}
