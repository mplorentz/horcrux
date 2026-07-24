import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/connection.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

// Runs against the plain system SQLite that `flutter test` loads on the host
// (no SQLCipher), so `PRAGMA cipher_version` is empty and the failsafe must
// throw — including on an unkeyed connection, matching production order
// (verify before PRAGMA key). This proves the connection setup fails closed
// instead of silently operating on an unencrypted database.
void main() {
  test('verifySqlCipherActive throws when SQLCipher is not the active library', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.dispose);

    expect(
      () => verifySqlCipherActive(db),
      throwsA(isA<StateError>()),
    );
  });
}
