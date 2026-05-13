import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'logger.dart';
import 'share_export_temp_file_support.dart';

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
          files: [XFile(file.path, mimeType: 'text/plain', name: fileName)],
          subject: 'Horcrux Vault: $vaultName',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } finally {
      await scheduleShareExportedFileCleanup(
        file,
        synchronousForTesting: synchronousExportCleanupForTesting,
        deletingLogLabel: 'export file',
      );
    }
  }

  /// Deletes every file under the export subdirectory. Call on app launch and
  /// terminate so vault plaintext never lingers on disk after the user leaves
  /// the app to complete a share.
  Future<void> clearExportDirectory() async {
    await sweepTemporaryExportSubdirectoryFiles(
      resolveExportDirectory: _exportDirectory,
      staleFileLogLabel: 'export file',
      sweepFailureMessage: 'Vault export directory sweep failed',
    );
  }

  Future<Directory> _exportDirectory() async {
    return ensureTemporaryExportSubdirectory(
      temporaryDirectory: _temporaryDirectory,
      subdirectoryName: _exportSubdirName,
    );
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
