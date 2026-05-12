import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Singleton [AppDatabase] for the running app.
///
/// Always opens the SQLCipher-backed production database via
/// [AppDatabase.openDefault]. Tests override this provider with an in-memory
/// instance using `appDatabaseProvider.overrideWithValue(testDb)`; see
/// `test/helpers/test_database.dart` for the canonical helper.
///
/// Repositories that wrap this provider should reach for it with
/// `ref.watch(appDatabaseProvider)` (not `ref.read`). Logout invalidates the
/// provider after closing the database; watching ensures the dependent
/// repositories rebuild against the freshly-opened database in the next
/// session instead of holding the previous (closed) handle.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.openDefault();
  ref.onDispose(() async {
    try {
      await db.close();
    } on StateError {
      // Logout closes the DB before invalidating this provider; ignore the
      // second close from provider disposal.
    }
  });
  return db;
});
