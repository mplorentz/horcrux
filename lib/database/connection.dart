import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
// `sqlite3` is pulled in transitively by sqlcipher_flutter_libs; we import the
// `Database` type directly so the pragma-application helper has a precise
// signature, and `open` so we can point package:sqlite3 at SQLCipher on
// Android. Adding it as a direct dep would just track the version
// sqlcipher_flutter_libs already pins.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

import '../services/logger.dart';
import 'db_key.dart';

/// Guards against registering the `package:sqlite3` open overrides more than
/// once. [open.overrideFor] is global process state; repeated registration is
/// harmless but pointless.
bool _sqlCipherOpenConfigured = false;

/// Ensures `package:sqlite3` loads SQLCipher where a Dart open override is
/// required, so drift never opens a plain-SQLite database by accident.
///
/// - **Android**: loads the bundled `libsqlcipher.so` via [openCipherOnAndroid]
///   (the default loader would pick `libsqlite3.so`).
/// - **iOS/macOS**: no Dart open override. Apple platforms rely on Podfile
///   `OTHER_LDFLAGS` ordering (`-framework SQLCipher` first) so
///   `DynamicLibrary.process()` resolves SQLCipher instead of system SQLite.
///   See sqlcipher_flutter_libs docs and the Zetetic advisory:
///   https://discuss.zetetic.net/t/important-advisory-sqlcipher-with-xcode-8-and-new-sdks/1688
///
/// Idempotent and safe to call from both `main()` and the lazy database opener.
/// Callers that need the old-Android workaround must still await
/// [applyWorkaroundToOpenSqlCipherOnOldAndroidVersions] separately, since it is
/// async and this function is not.
void configureSqlCipherOpen() {
  if (_sqlCipherOpenConfigured) return;
  _sqlCipherOpenConfigured = true;

  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}

/// Filename for the SQLCipher database under the application support
/// directory. Sibling files `<dbFileName>-wal` and `<dbFileName>-shm` must
/// also be removed during logout/wipe (see Phase 5 acceptance).
const String dbFileName = 'horcrux.db';

/// Returns the SQLCipher database path under application support.
///
/// [supportDirectory] exists for tests that need deterministic temporary
/// directories without mocking platform channels.
Future<String> resolveSqlCipherDatabasePath({Directory? supportDirectory}) async {
  final dir = supportDirectory ?? await getApplicationSupportDirectory();
  return p.join(dir.path, dbFileName);
}

/// Deletes the SQLCipher database file and its `-wal` / `-shm` siblings.
///
/// This is a best-effort cleanup used by logout and corruption wipe paths.
/// Missing files are ignored so repeated cleanup calls are harmless.
Future<void> deleteSqlCipherDatabaseFiles({Directory? supportDirectory}) async {
  final dbPath = await resolveSqlCipherDatabasePath(
    supportDirectory: supportDirectory,
  );
  final files = <String>[
    dbPath,
    '$dbPath-wal',
    '$dbPath-shm',
  ];
  for (final filePath in files) {
    final file = File(filePath);
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, st) {
      Log.error('Failed to delete SQLCipher file $filePath', e, st);
    }
  }
}

/// Opens the SQLCipher-backed drift connection used in production.
///
/// Pinned pragmas — see "Stack" in `docs/data_layer_refactor_plan.md`:
/// - `cipher_page_size = 4096`
/// - `cipher_kdf_algorithm = PBKDF2_HMAC_SHA512` (irrelevant when raw key is
///   used, but pinned in case derivation strategy changes)
/// - `cipher_use_hmac = ON` (default)
/// - `cipher_memory_security = ON` where supported
/// - `secure_delete = ON` so deleted share-material pages are zeroed
///
/// The connection sets `closeStreamsSynchronously: true` so drift cleans up
/// query streams in the same microtask the subscription is cancelled. That
/// matters at logout: when [appDatabaseProvider] is invalidated, Riverpod
/// disposes the dependent repositories first; without synchronous stream
/// cleanup, drift would leave a `Timer.zero` pending past the database
/// close and produce "pending timers" failures in widget tests.
DatabaseConnection openSqlCipherConnection({DbKeyDerivation? keyDerivation}) {
  final derivation = keyDerivation ?? DbKeyDerivation();
  final lazy = LazyDatabase(() async {
    // Belt-and-suspenders: on Android, ensure package:sqlite3 loads
    // libsqlcipher.so even if the app entrypoint did not call
    // [configureSqlCipherOpen] (e.g. integration tests that open the DB
    // directly). No-op on Apple platforms (Podfile linker ordering).
    configureSqlCipherOpen();
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

    final dbPath = await resolveSqlCipherDatabasePath();
    final pragmaKey = await derivation.deriveSqlCipherPragmaKey();
    if (pragmaKey == null) {
      throw StateError(
        'Cannot open AppDatabase: no Nostr private key in secure storage. '
        'The user must complete login first.',
      );
    }

    Log.info('Opening SQLCipher database at $dbPath');
    return NativeDatabase(
      File(dbPath),
      setup: (rawDb) {
        _applyKeyAndPragmas(rawDb, pragmaKey);
      },
    );
  });
  return DatabaseConnection(lazy, closeStreamsSynchronously: true);
}

/// Applies the SQLCipher key and the v1 pragma set to a raw [Database].
/// Extracted so tests using a non-encrypted in-memory DB can skip it.
///
/// The key PRAGMA is executed first; any failure is re-thrown as a
/// [StateError] with a sanitised message so key material cannot propagate
/// through exception messages into crash reporters or logs.
void _applyKeyAndPragmas(Database rawDb, String pragmaKey) {
  try {
    rawDb.execute("PRAGMA key = $pragmaKey;");
  } on Object catch (e) {
    // Do NOT include e.toString() — it contains the full SQL statement with
    // the raw key embedded, which would leak key material into crash reports.
    throw StateError(
      'SQLCipher PRAGMA key failed (${e.runtimeType}). '
      'This is a fatal configuration error.',
    );
  }
  rawDb.execute('PRAGMA cipher_page_size = 4096;');
  rawDb.execute("PRAGMA cipher_kdf_algorithm = 'PBKDF2_HMAC_SHA512';");
  rawDb.execute('PRAGMA cipher_use_hmac = ON;');
  rawDb.execute('PRAGMA cipher_memory_security = ON;');
  rawDb.execute('PRAGMA secure_delete = ON;');
  rawDb.execute('PRAGMA foreign_keys = ON;');
}
