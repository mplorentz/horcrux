import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'logger.dart';

/// Wraps system share sheet export for vault plaintext recovery material.
///
/// Plaintext briefly lands on disk because mobile share targets expect a real
/// file URI. Files are written into a dedicated subdirectory so we can sweep
/// them on app launch and terminate without disturbing other temp files.
/// Never log file contents.
final vaultExportServiceProvider = Provider<VaultExportService>((ref) {
  return VaultExportService();
});

/// Subdirectory under the OS temp dir where vault export files live. Isolated
/// so [VaultExportService.clearExportDirectory] can sweep it safely.
const _exportSubdirName = 'vault_exports';

/// Delay between [SharePlus.share] returning and deleting the temp file on
/// Apple platforms. Bridges the brief window where the share sheet has been
/// dismissed but the recipient app is still copying the file out of our temp
/// dir; deleting immediately drops the attachment for AirDrop / Messages /
/// Mail. share_plus has no API for "deleted-when-recipient-done" — see
/// https://github.com/fluttercommunity/plus_plugins/issues/974 and
/// https://github.com/fluttercommunity/plus_plugins/issues/1299, both closed
/// with the maintainer punting cleanup to consumers.
const _appleCleanupDelay = Duration(milliseconds: 900);

class VaultExportService {
  VaultExportService({
    SharePlus? sharePlus,
    Future<Directory> Function()? temporaryDirectory,
    this.synchronousExportCleanupForTesting = false,
  })  : _sharePlus = sharePlus ?? SharePlus.instance,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final SharePlus _sharePlus;
  final Future<Directory> Function() _temporaryDirectory;

  /// When true, deletes the export file in [shareVaultContent] before returning.
  /// Tests use this; production uses deferred cleanup on Apple platforms.
  final bool synchronousExportCleanupForTesting;

  /// Writes [content] as UTF-8 `<slug>.txt` under the export subdirectory and
  /// opens the platform share sheet for that file.
  Future<void> shareVaultContent({
    required String vaultName,
    required String content,
    Rect? sharePositionOrigin,
  }) async {
    final dir = await _exportDirectory();
    final slug = exportFilenameStem(vaultName);
    final fileName = '$slug.txt';
    final file = File('${dir.path}/$fileName');

    try {
      await file.writeAsString(content, flush: true);
      final byteLength = utf8.encode(content).length;
      Log.info('Vault export share starting: $fileName ($byteLength bytes)');

      // Pass [text] alongside [files] so recipients that handle text inline
      // (Notes, Messages, Mail body, Slack) get the bytes via pasteboard
      // semantics and skip the file path entirely. Recipients that want a
      // file (AirDrop, "Save to Files") still get the XFile and copy it out
      // of our sandbox before our cleanup window closes.
      await _sharePlus.share(
        ShareParams(
          text: content,
          files: [
            XFile(file.path, mimeType: 'text/plain', name: fileName),
          ],
          subject: 'Horcrux Vault: $vaultName',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } finally {
      await _scheduleExportFileCleanup(file);
    }
  }

  /// Deletes every file under the export subdirectory. Call on app launch and
  /// terminate so vault plaintext never lingers on disk after the user leaves
  /// the app to complete a share.
  Future<void> clearExportDirectory() async {
    try {
      final dir = await _exportDirectory();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        try {
          if (entity is File) {
            Log.info('Sweeping stale export file: ${entity.path}');
            await entity.delete();
          }
        } catch (_) {}
      }
    } catch (e, st) {
      Log.warning('Vault export directory sweep failed', e, st);
    }
  }

  Future<Directory> _exportDirectory() async {
    final temp = await _temporaryDirectory();
    final dir = Directory('${temp.path}/$_exportSubdirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _scheduleExportFileCleanup(File file) async {
    Future<void> deleteIfPresent() async {
      try {
        if (await file.exists()) {
          Log.info('Deleting export file: ${file.path}');
          await file.delete();
        }
      } catch (_) {}
    }

    if (synchronousExportCleanupForTesting) {
      await deleteIfPresent();
      return;
    }

    final delay = (Platform.isMacOS || Platform.isIOS) ? _appleCleanupDelay : Duration.zero;
    Future<void>.delayed(delay, deleteIfPresent);
  }
}

/// ASCII slug for export filenames; empty after sanitization -> horcrux-recovered.
String exportFilenameStem(String vaultName) {
  final trimmed = vaultName.trim();
  if (trimmed.isEmpty) {
    return 'horcrux-recovered';
  }
  final slug = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) {
    return 'horcrux-recovered';
  }
  return slug;
}
