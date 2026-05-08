import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Singleton [AppDatabase] for the running app.
///
/// Always opens the SQLCipher-backed production database via
/// [AppDatabase.openDefault]. Tests override this provider with an in-memory
/// instance using `appDatabaseProvider.overrideWithValue(testDb)`; see
/// `test/helpers/test_database.dart` for the canonical helper.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.openDefault();
  ref.onDispose(() => db.close());
  return db;
});
