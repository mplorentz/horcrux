import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/connection.dart';
import 'package:path/path.dart' as p;

void main() {
  group('deleteSqlCipherDatabaseFiles', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('horcrux-connection-test');
      dbPath = p.join(tempDir.path, dbFileName);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('deletes db, wal, and shm siblings', () async {
      final dbFile = File(dbPath);
      final walFile = File('$dbPath-wal');
      final shmFile = File('$dbPath-shm');
      await dbFile.writeAsString('db');
      await walFile.writeAsString('wal');
      await shmFile.writeAsString('shm');

      await deleteSqlCipherDatabaseFiles(supportDirectory: tempDir);

      expect(await dbFile.exists(), isFalse);
      expect(await walFile.exists(), isFalse);
      expect(await shmFile.exists(), isFalse);
    });

    test('is a no-op when files do not exist', () async {
      await deleteSqlCipherDatabaseFiles(supportDirectory: tempDir);

      expect(await File(dbPath).exists(), isFalse);
      expect(await File('$dbPath-wal').exists(), isFalse);
      expect(await File('$dbPath-shm').exists(), isFalse);
    });
  });
}
