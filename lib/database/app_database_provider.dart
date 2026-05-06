import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Singleton [AppDatabase] for the running app. Override in tests with
/// `appDatabaseProvider.overrideWithValue(testDb)` (see
/// `test/helpers/test_database.dart`). The provider intentionally constructs
/// the SQLCipher-backed connection lazily — opening it triggers DB key
/// derivation, which fails until the user has logged in.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.openDefault();
  ref.onDispose(() => db.close());
  return db;
});
