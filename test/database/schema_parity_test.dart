import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Dart CLI path suitable for `dart run drift_dev ...`.
///
/// Under `flutter test`, [Platform.resolvedExecutable] is typically the test VM
/// (`flutter_tester`), not the Dart SDK `dart` binary. Running `dart run` via
/// that executable hangs indefinitely (wrong CLI semantics).
String dartCliExecutablePath() {
  final resolved = Platform.resolvedExecutable;
  final basename = p.basename(resolved);
  if (basename == 'dart' || basename == 'dart.exe') {
    return resolved;
  }

  // flutter/bin/cache/dart-sdk/bin/dart
  var dir = p.dirname(resolved);
  for (var i = 0; i < 8; i++) {
    final candidate = p.join(dir, 'dart-sdk', 'bin', 'dart');
    if (File(candidate).existsSync()) {
      return candidate;
    }
    final parent = p.dirname(dir);
    if (parent == dir) {
      break;
    }
    dir = parent;
  }

  // Last resort: rely on PATH (CI may have dart on PATH even when tests run
  // under flutter_tester).
  return 'dart';
}

/// CI gate: any code change that affects the SQL schema produced by drift
/// must be matched by a fresh dump under `drift_schemas/`.
///
/// **What this does *not* enforce:** you can still edit drift table classes,
/// re-run `drift_dev schema dump`, and overwrite `drift_schema_vN.json` while
/// leaving `AppDatabase.schemaVersion` at `N` — parity would pass and existing
/// installs would never run `onUpgrade`. **Pull requests** also run the
/// **Drift schema version** workflow (`.github/workflows/drift-schema-version.yml`
/// → `scripts/check-drift-schema-version-bump.sh`), which requires that any
/// *semantic* change to committed files under `drift_schemas/` is accompanied
/// by an edit to the `schemaVersion` line in `lib/database/app_database.dart`.
///
/// **Local fix when this fails**:
///
/// ```bash
/// flutter pub run build_runner build --delete-conflicting-outputs
/// dart run drift_dev schema dump lib/database/app_database.dart drift_schemas/
/// git add drift_schemas/
/// ```
///
/// If the schema change is intentional, also bump `AppDatabase.schemaVersion`,
/// add a `from{N}To{N+1}` migration step to `MigrationStrategy.onUpgrade`,
/// and add a migration test alongside this one.
void main() {
  test('drift_schemas/ contains the dump matching the current schema', () async {
    // Re-dump into a temp dir and diff against the committed file. We shell
    // out to `dart run drift_dev schema dump` so this test exercises the same
    // tool a developer would run locally — drift_dev does not (yet) expose a
    // public Dart API for this.
    final committed = File('drift_schemas/drift_schema_v5.json');
    expect(committed.existsSync(), isTrue,
        reason: 'drift_schemas/drift_schema_v5.json is missing. Run '
            '`dart run drift_dev schema dump lib/database/app_database.dart drift_schemas/`.');

    final tempDir = await Directory.systemTemp.createTemp('drift_schema_parity');
    try {
      final dartCli = dartCliExecutablePath();
      final result = await Process.run(
        dartCli,
        [
          'run',
          'drift_dev',
          'schema',
          'dump',
          'lib/database/app_database.dart',
          tempDir.path,
        ],
      );
      expect(result.exitCode, 0,
          reason: 'drift_dev schema dump failed:\n${result.stdout}\n${result.stderr}');

      final fresh = File('${tempDir.path}/drift_schema_v5.json');
      expect(fresh.existsSync(), isTrue, reason: 'drift_dev did not emit drift_schema_v5.json');

      final committedJson = jsonDecode(await committed.readAsString()) as Object;
      final freshJson = jsonDecode(await fresh.readAsString()) as Object;

      expect(
        const JsonEncoder.withIndent('  ').convert(freshJson),
        const JsonEncoder.withIndent('  ').convert(committedJson),
        reason: 'drift schema in code does not match drift_schemas/drift_schema_v5.json. '
            'Either re-dump (after bumping schemaVersion + adding a migration) '
            'or revert the unintended schema change.',
      );
    } finally {
      await tempDir.delete(recursive: true);
    }
  },
      // Default 30s is too tight on GitHub macOS runners: cold `dart run
      // drift_dev schema dump` can exceed that while analyzing the project.
      timeout: const Timeout(Duration(minutes: 5)),
      tags: 'drift-schema');
}
