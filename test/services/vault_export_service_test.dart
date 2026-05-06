import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/vault_export_service.dart';
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

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vault_export_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('exportFilenameStem', () {
    test('slugifies vault names', () {
      expect(exportFilenameStem('My Vault!'), 'my-vault');
    });

    test('empty or whitespace falls back', () {
      expect(exportFilenameStem(''), 'horcrux-recovered');
      expect(exportFilenameStem('   '), 'horcrux-recovered');
    });

    test('only punctuation falls back', () {
      expect(exportFilenameStem('!!!'), 'horcrux-recovered');
    });
  });

  group('VaultExportService', () {
    test('writes utf-8 file, shares, and deletes temp file', () async {
      final platform = RecordingSharePlatform();
      final service = VaultExportService(
        sharePlus: SharePlus.custom(platform),
        temporaryDirectory: () async => tempDir,
        synchronousExportCleanupForTesting: true,
      );

      const body = 'line1\nline2\nunicode: å';
      await service.shareVaultContent(vaultName: 'My Vault!', content: body);

      expect(platform.lastParams, isNotNull);
      expect(platform.lastParams!.subject, 'Horcrux Vault: My Vault!');
      expect(platform.lastParams!.files, hasLength(1));
      final xFile = platform.lastParams!.files!.single;
      expect(xFile.mimeType, 'text/plain');
      expect(xFile.name, 'my-vault.txt');

      final diskPath = p.join(tempDir.path, 'my-vault.txt');
      expect(File(diskPath).existsSync(), isFalse);
    });

    test('uses fallback filename when vault name empty', () async {
      final platform = RecordingSharePlatform();
      final service = VaultExportService(
        sharePlus: SharePlus.custom(platform),
        temporaryDirectory: () async => tempDir,
        synchronousExportCleanupForTesting: true,
      );

      await service.shareVaultContent(vaultName: ' ', content: 'x');

      expect(platform.lastParams!.files!.single.name, 'horcrux-recovered.txt');
      expect(File(p.join(tempDir.path, 'horcrux-recovered.txt')).existsSync(), isFalse);
    });
  });
}
