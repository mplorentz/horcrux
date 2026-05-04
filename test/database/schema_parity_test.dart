import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI gate: any code change that affects the SQL schema produced by drift
/// must be matched by a fresh dump under `drift_schemas/`. Without this
/// gate, schema drift would silently slip into a release without a
/// corresponding migration step.
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
    final committed = File('drift_schemas/drift_schema_v1.json');
    expect(committed.existsSync(), isTrue,
        reason: 'drift_schemas/drift_schema_v1.json is missing. Run '
            '`dart run drift_dev schema dump lib/database/app_database.dart drift_schemas/`.');

    final tempDir = await Directory.systemTemp.createTemp('drift_schema_parity');
    try {
      final result = await Process.run(
        'dart',
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

      final fresh = File('${tempDir.path}/drift_schema_v1.json');
      expect(fresh.existsSync(), isTrue,
          reason: 'drift_dev did not emit drift_schema_v1.json');

      final committedJson =
          jsonDecode(await committed.readAsString()) as Object;
      final freshJson = jsonDecode(await fresh.readAsString()) as Object;

      expect(
        const JsonEncoder.withIndent('  ').convert(freshJson),
        const JsonEncoder.withIndent('  ').convert(committedJson),
        reason:
            'drift schema in code does not match drift_schemas/drift_schema_v1.json. '
            'Either re-dump (after bumping schemaVersion + adding a migration) '
            'or revert the unintended schema change.',
      );
    } finally {
      await tempDir.delete(recursive: true);
    }
  }, tags: 'drift-schema');
}
