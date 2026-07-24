import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/connection.dart';

// This file intentionally does NOT open any database. [configureSqlCipherOpen]
// may register a process-global Android `package:sqlite3` open override; each
// test file runs in its own isolate, so registering it here cannot leak into
// other tests that open in-memory databases.
void main() {
  test('configureSqlCipherOpen is idempotent and does not throw', () {
    expect(configureSqlCipherOpen, returnsNormally);
    // Second call is a no-op thanks to the internal guard.
    expect(configureSqlCipherOpen, returnsNormally);
  });
}
