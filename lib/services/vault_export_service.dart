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
/// file URI. We delete the temp file on a best-effort basis after sharing.
/// Never log file contents.
final vaultExportServiceProvider = Provider<VaultExportService>((ref) {
  return VaultExportService();
});

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

  /// Writes [content] as UTF-8 `<slug>.txt` under the temp directory and opens
  /// the platform share sheet for that file.
  Future<void> shareVaultContent({
    required String vaultName,
    required String content,
    Rect? sharePositionOrigin,
  }) async {
    final dir = await _temporaryDirectory();
    final slug = exportFilenameStem(vaultName);
    final fileName = '$slug.txt';
    final file = File('${dir.path}/$fileName');

    try {
      await file.writeAsString(content, flush: true);
      final byteLength = utf8.encode(content).length;
      Log.info('Vault export share starting: $fileName ($byteLength bytes)');

      await _sharePlus.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'text/plain',
              name: fileName,
            ),
          ],
          subject: 'Horcrux Vault: $vaultName',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } finally {
      // macOS/iOS often complete [share] before the target app finishes reading the
      // temp path; deleting immediately drops the attachment. Defer cleanup on Apple
      // platforms (no extra sandbox entitlement required for sharing from temp).
      await _scheduleExportFileCleanup(file);
    }
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

    final delay = (Platform.isMacOS || Platform.isIOS) ? const Duration(seconds: 1) : Duration.zero;
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
