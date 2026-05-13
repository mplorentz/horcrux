import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/app_log_file_setup.dart';
import 'package:horcrux/services/log_export_service.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class RecordingSharePlatform extends SharePlatform {
  RecordingSharePlatform();

  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    lastParams = params;
    return const ShareResult('', ShareResultStatus.dismissed);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stripAnsiEscapes', () {
    test('removes SGR color sequences', () {
      expect(stripAnsiEscapes('\x1B[31mhello\x1B[0m'), 'hello');
    });

    test('removes 256-color sequences', () {
      expect(stripAnsiEscapes('\x1B[38;5;12mblue\x1B[0m'), 'blue');
    });
  });

  group('LogExportService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('log_export_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('shareLogs returns noLogs when file is missing', () async {
      final missing = File(p.join(tempDir.path, 'nope.log'));
      final service = LogExportService(
        resolvePersistedLogFile: () async => missing,
        temporaryDirectory: () async => tempDir,
        sharePlus: SharePlus.custom(RecordingSharePlatform()),
        synchronousExportCleanupForTesting: true,
      );

      expect(await service.shareLogs(), LogExportOutcome.noLogs);
    });

    test('shareLogs returns noLogs when file is empty', () async {
      final logFile = File(p.join(tempDir.path, 'horcrux.log'));
      await logFile.writeAsString('');
      final service = LogExportService(
        resolvePersistedLogFile: () async => logFile,
        temporaryDirectory: () async => tempDir,
        sharePlus: SharePlus.custom(RecordingSharePlatform()),
        synchronousExportCleanupForTesting: true,
      );

      expect(await service.shareLogs(), LogExportOutcome.noLogs);
    });

    test('shareLogs copies file, shares, and deletes temp copy', () async {
      final logFile = File(p.join(tempDir.path, 'horcrux.log'));
      const body = 'line1\nunicode: å';
      await logFile.writeAsString(body);
      final platform = RecordingSharePlatform();
      final service = LogExportService(
        resolvePersistedLogFile: () async => logFile,
        temporaryDirectory: () async => tempDir,
        sharePlus: SharePlus.custom(platform),
        synchronousExportCleanupForTesting: true,
      );

      final outcome = await service.shareLogs();
      expect(outcome, LogExportOutcome.shared);

      expect(platform.lastParams, isNotNull);
      expect(platform.lastParams!.subject, 'Horcrux debug logs');
      expect(platform.lastParams!.text, isNull);
      expect(platform.lastParams!.files, hasLength(1));
      final xFile = platform.lastParams!.files!.single;
      expect(xFile.mimeType, 'text/plain');
      expect(xFile.name.startsWith('horcrux-log-'), isTrue);
      expect(xFile.name.endsWith('.txt'), isTrue);
      expect(p.dirname(xFile.path), p.join(tempDir.path, 'log_exports'));
      expect(File(xFile.path).existsSync(), isFalse);
      expect(logFile.readAsStringSync(), body);
    });

    test('clearLogExportDirectory removes leftover files', () async {
      final service = LogExportService(
        temporaryDirectory: () async => tempDir,
      );

      final exportDir = Directory(p.join(tempDir.path, 'log_exports'));
      await exportDir.create(recursive: true);
      final stale = File(p.join(exportDir.path, 'horcrux-log-test.txt'));
      await stale.writeAsString('old');
      final sibling = File(p.join(tempDir.path, 'unrelated.txt'));
      await sibling.writeAsString('keep');

      await service.clearLogExportDirectory();

      expect(stale.existsSync(), isFalse);
      expect(sibling.existsSync(), isTrue);
      expect(exportDir.existsSync(), isTrue);
    });

    test('clearLogExportDirectory is a no-op when directory is missing', () async {
      final service = LogExportService(
        temporaryDirectory: () async => tempDir,
      );

      await service.clearLogExportDirectory();
    });
  });
}
