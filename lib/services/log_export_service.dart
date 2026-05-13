import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_log_file_setup.dart';
import 'logger.dart';
import 'share_export_temp_file_support.dart';

/// Outcome of [LogExportService.shareLogs] for UI feedback.
enum LogExportOutcome {
  /// Share sheet was shown with a copy of the log file.
  shared,

  /// Log file is missing or empty.
  noLogs,

  /// Copy or share failed.
  failed,
}

final logExportServiceProvider = Provider<LogExportService>((ref) {
  return LogExportService();
});

/// Subdirectory under the OS temp dir for one-off log shares (swept on launch).
const _logExportSubdirName = 'log_exports';

class LogExportService {
  LogExportService({
    SharePlus? sharePlus,
    Future<Directory> Function()? temporaryDirectory,
    Future<File> Function()? resolvePersistedLogFile,
    this.synchronousExportCleanupForTesting = false,
  }) : _sharePlus = sharePlus ?? SharePlus.instance,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _resolvePersistedLogFile =
           resolvePersistedLogFile ?? resolvedPersistedLogFile;

  final SharePlus _sharePlus;
  final Future<Directory> Function() _temporaryDirectory;
  final Future<File> Function() _resolvePersistedLogFile;

  /// When true, deletes the shared copy in [shareLogs] before returning.
  /// Tests use this; production uses deferred cleanup on Apple platforms.
  final bool synchronousExportCleanupForTesting;

  /// Copies the persistent log to a timestamped file and opens the share sheet.
  Future<LogExportOutcome> shareLogs({Rect? sharePositionOrigin}) async {
    final source = await _resolvePersistedLogFile();
    if (!await source.exists()) {
      return LogExportOutcome.noLogs;
    }
    final byteLength = await source.length();
    if (byteLength == 0) {
      return LogExportOutcome.noLogs;
    }

    final dir = await _exportDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final fileName = 'horcrux-log-$stamp.txt';
    final dest = File('${dir.path}/$fileName');

    try {
      await source.copy(dest.path);
      Log.info('Log export share starting: $fileName ($byteLength bytes)');

      await _sharePlus.share(
        ShareParams(
          files: [XFile(dest.path, mimeType: 'text/plain', name: fileName)],
          subject: 'Horcrux debug logs',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      await scheduleShareExportedFileCleanup(
        dest,
        synchronousForTesting: synchronousExportCleanupForTesting,
        deletingLogLabel: 'log export file',
      );
      return LogExportOutcome.shared;
    } catch (e, st) {
      Log.warning('Log export failed', e, st);
      try {
        if (await dest.exists()) {
          await dest.delete();
        }
      } catch (_) {}
      return LogExportOutcome.failed;
    }
  }

  /// Deletes every file under the log export subdirectory.
  Future<void> clearLogExportDirectory() async {
    await sweepTemporaryExportSubdirectoryFiles(
      resolveExportDirectory: _exportDirectory,
      staleFileLogLabel: 'log export file',
      sweepFailureMessage: 'Log export directory sweep failed',
    );
  }

  Future<Directory> _exportDirectory() async {
    return ensureTemporaryExportSubdirectory(
      temporaryDirectory: _temporaryDirectory,
      subdirectoryName: _logExportSubdirName,
    );
  }
}
