import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

/// Zetetic advisory verification scenarios:
/// https://discuss.zetetic.net/t/important-advisory-sqlcipher-with-xcode-8-and-new-sdks/1688
///
/// `flutter test` on macOS/iOS hosts loads Apple's system SQLite, which is
/// **not** SQLCipher (`PRAGMA cipher_version` is empty). These checks are only
/// meaningful when a real SQLCipher library is loaded into the test process.
///
/// Loading strategy (first match wins):
/// 1. `SQLCIPHER_LIBRARY` env var — absolute path to the SQLCipher dylib /
///    framework binary (e.g. after `flutter build macos`:
///    `build/macos/Build/Products/Debug/SQLCipher/SQLCipher.framework/SQLCipher`)
/// 2. Well-known macOS build-product paths under the package root
/// 3. Android: [openCipherOnAndroid] when that loads a cipher-capable library
///
/// When none of those yield a non-empty `PRAGMA cipher_version`, the group is
/// skipped (not failed) so host/CI unit runs stay green while still executing
/// for real wherever SQLCipher is present.
void main() {
  final loadedFrom = _configureSqlCipherLibraryForTests();
  final sqlCipherAvailable = _probeCipherVersion();

  group(
    'SQLCipher encryption verification (Zetetic advisory)',
    skip: sqlCipherAvailable
        ? false
        : 'SQLCipher not loaded in this test process '
            '(PRAGMA cipher_version empty). flutter test uses system SQLite on '
            'macOS/iOS hosts. Set SQLCIPHER_LIBRARY to the SQLCipher framework '
            'binary (or run after flutter build macos so build products exist) '
            'to execute these checks for real. Loaded attempt: '
            '${loadedFrom ?? "none"}.',
    () {
      late Directory tempDir;
      late String dbPath;
      // 32-byte raw keys in the same `"x'<hex>'"` format as
      // DbKeyDerivation.deriveSqlCipherPragmaKey().
      final correctKey = _formatRawKeyForPragma(
        Uint8List.fromList(List<int>.generate(32, (i) => i)),
      );
      final incorrectKey = _formatRawKeyForPragma(
        Uint8List.fromList(List<int>.generate(32, (i) => 255 - i)),
      );

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync(
          'horcrux-sqlcipher-verify-',
        );
        dbPath = p.join(tempDir.path, 'verify.db');
        _createEncryptedDatabase(dbPath: dbPath, pragmaKey: correctKey);
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('1. opening with the correct key succeeds', () {
        final db = sqlite3.open(dbPath);
        addTearDown(db.dispose);

        db.execute('PRAGMA key = $correctKey;');
        final rows = db.select('SELECT value FROM probe ORDER BY id;');
        expect(rows, hasLength(1));
        expect(rows.first['value'], 'encrypted-ok');
      });

      test('2. opening with an incorrect key fails', () {
        final db = sqlite3.open(dbPath);
        addTearDown(db.dispose);

        db.execute('PRAGMA key = $incorrectKey;');
        expect(
          () => db.select('SELECT value FROM probe ORDER BY id;'),
          throwsA(isA<SqliteException>()),
        );
      });

      test('3. opening with no key fails', () {
        final db = sqlite3.open(dbPath);
        addTearDown(db.dispose);

        expect(
          () => db.select('SELECT value FROM probe ORDER BY id;'),
          throwsA(isA<SqliteException>()),
        );
      });

      test(
        '4. on-disk header is not plaintext SQLite format 3',
        () {
          final bytes = File(dbPath).readAsBytesSync();
          expect(bytes.length, greaterThanOrEqualTo(16));
          final header = bytes.sublist(0, 16);
          // Plain SQLite files begin with this exact 16-byte magic.
          final plaintextMagic = Uint8List.fromList(
            utf8.encode('SQLite format 3\x00'),
          );
          expect(
            header,
            isNot(equals(plaintextMagic)),
            reason: 'Database file header looks like plaintext SQLite; SQLCipher '
                'should produce encrypted (random-looking) first page bytes.',
          );
        },
      );
    },
  );
}

/// Points `package:sqlite3` at a SQLCipher library when one can be found.
///
/// Returns a short description of what was configured, or `null` if nothing
/// was overridden (caller will still probe and skip).
String? _configureSqlCipherLibraryForTests() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    return 'openCipherOnAndroid';
  }

  final libraryPath = _resolveSqlCipherLibraryPath();
  if (libraryPath == null) return null;

  if (Platform.isMacOS) {
    open.overrideFor(
      OperatingSystem.macOS,
      () => DynamicLibrary.open(libraryPath),
    );
  } else if (Platform.isIOS) {
    open.overrideFor(
      OperatingSystem.iOS,
      () => DynamicLibrary.open(libraryPath),
    );
  } else if (Platform.isLinux) {
    open.overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open(libraryPath),
    );
  } else if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open(libraryPath),
    );
  } else {
    return null;
  }
  return libraryPath;
}

String? _resolveSqlCipherLibraryPath() {
  final fromEnv = Platform.environment['SQLCIPHER_LIBRARY'];
  if (fromEnv != null && fromEnv.isNotEmpty && File(fromEnv).existsSync()) {
    return fromEnv;
  }

  final root = _packageRoot();
  final candidates = <String>[
    if (Platform.isMacOS) ...[
      'build/macos/Build/Products/Debug/SQLCipher/SQLCipher.framework/SQLCipher',
      'build/macos/Build/Products/Debug/Horcrux.app/Contents/Frameworks/SQLCipher.framework/SQLCipher',
      'build/macos/Build/Products/Release/SQLCipher/SQLCipher.framework/SQLCipher',
      'build/macos/Build/Products/Release/Horcrux.app/Contents/Frameworks/SQLCipher.framework/SQLCipher',
    ],
    if (Platform.isLinux) ...[
      'build/linux/x64/debug/bundle/lib/libsqlcipher.so',
      'build/linux/arm64/debug/bundle/lib/libsqlcipher.so',
    ],
  ];

  for (final relative in candidates) {
    final absolute = p.join(root, relative);
    if (File(absolute).existsSync()) return absolute;
  }
  return null;
}

String _packageRoot() {
  // flutter test sets the CWD to the package root.
  final cwd = Directory.current.path;
  if (File(p.join(cwd, 'pubspec.yaml')).existsSync()) return cwd;

  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current.path;
    dir = parent;
  }
}

bool _probeCipherVersion() {
  try {
    final db = sqlite3.openInMemory();
    try {
      final rows = db.select('PRAGMA cipher_version;');
      if (rows.isEmpty) return false;
      final version = rows.first.values.first;
      return version is String && version.trim().isNotEmpty;
    } finally {
      db.dispose();
    }
  } on Object {
    return false;
  }
}

/// Matches [DbKeyDerivation]'s SQLCipher raw-key literal: `"x'<hex>'"`.
String _formatRawKeyForPragma(Uint8List key) {
  final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '"x\'$hex\'"';
}

void _createEncryptedDatabase({
  required String dbPath,
  required String pragmaKey,
}) {
  final db = sqlite3.open(dbPath);
  try {
    db.execute('PRAGMA key = $pragmaKey;');
    // Confirm we are actually on SQLCipher before writing — otherwise a
    // plaintext create would make scenario 4 vacuously wrong.
    final versionRows = db.select('PRAGMA cipher_version;');
    final version = versionRows.isEmpty ? null : versionRows.first.values.first;
    if (version == null || (version is String && version.trim().isEmpty)) {
      throw StateError(
        'Refusing to create verification DB: SQLCipher not active',
      );
    }
    db.execute('CREATE TABLE probe (id INTEGER PRIMARY KEY, value TEXT);');
    db.execute("INSERT INTO probe (value) VALUES ('encrypted-ok');");
  } finally {
    db.dispose();
  }
}
