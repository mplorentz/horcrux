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
    test('writes utf-8 file under vault_exports/, shares, and deletes', () async {
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
      expect(platform.lastParams!.text, body,
          reason: 'text recipients should get content inline, not via the file');
      expect(platform.lastParams!.files, hasLength(1));
      final xFile = platform.lastParams!.files!.single;
      expect(xFile.mimeType, 'text/plain');
      expect(xFile.name, 'my-vault.txt');
      expect(xFile.path, p.join(tempDir.path, 'vault_exports', 'my-vault.txt'));

      expect(File(xFile.path).existsSync(), isFalse);
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
      expect(
        File(
          p.join(tempDir.path, 'vault_exports', 'horcrux-recovered.txt'),
        ).existsSync(),
        isFalse,
      );
    });

    test('clearExportDirectory removes leftover files', () async {
      final service = VaultExportService(
        temporaryDirectory: () async => tempDir,
      );

      final exportDir = Directory(p.join(tempDir.path, 'vault_exports'));
      await exportDir.create(recursive: true);
      final stale1 = File(p.join(exportDir.path, 'my-vault.txt'));
      final stale2 = File(p.join(exportDir.path, 'other-vault.txt'));
      await stale1.writeAsString('secret-1');
      await stale2.writeAsString('secret-2');
      // A sibling file outside the export subdir must NOT be touched.
      final sibling = File(p.join(tempDir.path, 'unrelated.txt'));
      await sibling.writeAsString('keep me');

      await service.clearExportDirectory();

      expect(stale1.existsSync(), isFalse);
      expect(stale2.existsSync(), isFalse);
      expect(sibling.existsSync(), isTrue);
      expect(exportDir.existsSync(), isTrue);
    });

    test('clearExportDirectory is a no-op when directory is missing', () async {
      final service = VaultExportService(
        temporaryDirectory: () async => tempDir,
      );

      await service.clearExportDirectory();
    });
  });
}
