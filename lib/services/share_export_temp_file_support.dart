import 'dart:io';

import 'logger.dart';

/// Delay between the share sheet returning and deleting the temp file on
/// Apple platforms. Bridges the brief window where the share sheet has been
/// dismissed but the recipient app is still copying the file out of our temp
/// dir; deleting immediately drops the attachment for AirDrop / Messages /
/// Mail. share_plus has no API for "deleted-when-recipient-done" — see
/// https://github.com/fluttercommunity/plus_plugins/issues/974 and
/// https://github.com/fluttercommunity/plus_plugins/issues/1299, both closed
/// with the maintainer punting cleanup to consumers.
const Duration appleShareExportCleanupDelay = Duration(milliseconds: 900);

/// Ensures [subdirectoryName] exists under the OS temp directory.
Future<Directory> ensureTemporaryExportSubdirectory({
  required Future<Directory> Function() temporaryDirectory,
  required String subdirectoryName,
}) async {
  final temp = await temporaryDirectory();
  final dir = Directory('${temp.path}/$subdirectoryName');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Deletes [file] after share targets have had time to read it on Apple
/// platforms, or immediately when [synchronousForTesting] is true.
///
/// [deletingLogLabel] completes the phrase `Deleting <label>: <path>` (for
/// example `log export file` or `export file`).
Future<void> scheduleShareExportedFileCleanup(
  File file, {
  required bool synchronousForTesting,
  required String deletingLogLabel,
}) async {
  Future<void> deleteIfPresent() async {
    try {
      if (await file.exists()) {
        Log.info('Deleting $deletingLogLabel: ${file.path}');
        await file.delete();
      }
    } catch (_) {}
  }

  if (synchronousForTesting) {
    await deleteIfPresent();
    return;
  }

  final delay = (Platform.isMacOS || Platform.isIOS) ? appleShareExportCleanupDelay : Duration.zero;
  Future<void>.delayed(delay, deleteIfPresent);
}

/// Deletes every file under the directory returned by [resolveExportDirectory].
///
/// [staleFileLogLabel] completes `Sweeping stale <label>: <path>`.
Future<void> sweepTemporaryExportSubdirectoryFiles({
  required Future<Directory> Function() resolveExportDirectory,
  required String staleFileLogLabel,
  required String sweepFailureMessage,
}) async {
  try {
    final dir = await resolveExportDirectory();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      try {
        if (entity is File) {
          Log.info('Sweeping stale $staleFileLogLabel: ${entity.path}');
          await entity.delete();
        }
      } catch (_) {}
    }
  } catch (e, st) {
    Log.warning(sweepFailureMessage, e, st);
  }
}
