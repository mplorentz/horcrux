import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/database/app_database_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';

/// Logout closes the [AppDatabase] and invalidates [appDatabaseProvider]; the
/// repositories that hold a long-lived DB reference must rebuild against the
/// fresh database. Otherwise services that captured the old handle (e.g.
/// [VaultRepository], [VaultDetailRepository]) crash on the next access.
///
/// These tests simulate the logout flow by invalidating
/// [appDatabaseProvider] inside a [ProviderContainer] and verify that
/// dependent repositories are rebuilt against the freshly-constructed DB.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Each test deliberately rebuilds the AppDatabase to simulate a logout +
  // re-login. Drift's runtime warning about multiple databases is expected
  // here and would otherwise add noise to CI output.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('appDatabaseProvider invalidation', () {
    final databases = <AppDatabase>[];

    AppDatabase trackDb(AppDatabase db) {
      databases.add(db);
      return db;
    }

    tearDown(() async {
      for (final db in databases) {
        try {
          await db.close();
        } catch (_) {}
      }
      databases.clear();
    });

    test(
      'rebuilds vaultRepositoryProvider and vaultDetailRepositoryProvider '
      'when the database is invalidated',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWith(
              (ref) => trackDb(AppDatabase(NativeDatabase.memory())),
            ),
          ],
        );
        addTearDown(container.dispose);

        final firstDb = container.read(appDatabaseProvider);
        final firstRepo = container.read(vaultRepositoryProvider);
        final firstDetailRepo = container.read(vaultDetailRepositoryProvider);

        container.invalidate(appDatabaseProvider);

        final secondDb = container.read(appDatabaseProvider);
        final secondRepo = container.read(vaultRepositoryProvider);
        final secondDetailRepo = container.read(vaultDetailRepositoryProvider);

        expect(secondDb, isNot(same(firstDb)));
        expect(secondRepo, isNot(same(firstRepo)));
        expect(secondDetailRepo, isNot(same(firstDetailRepo)));
      },
    );

    test(
      'closing the previous database does not break the next session',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWith(
              (ref) => trackDb(AppDatabase(NativeDatabase.memory())),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Materialize the first repository so its stream subscription is
        // wired to the original database, then close that database the same
        // way LogoutService does.
        container.read(vaultRepositoryProvider);
        final firstDb = container.read(appDatabaseProvider);
        await firstDb.close();

        container.invalidate(appDatabaseProvider);

        // A held-onto reference to the closed database would throw
        // `StateError("Can't re-open a database after closing it")` on the
        // first DAO access. Reading and querying validates the swap.
        final repo = container.read(vaultRepositoryProvider);
        final vaults = await repo.getAllVaults();
        expect(vaults, isEmpty);
      },
    );

    test(
      'invalidating appDatabaseProvider after key appears clears a cached '
      'open failure (logout then login)',
      () {
        var keyPresent = false;

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWith((ref) {
              if (!keyPresent) {
                throw StateError(
                  'Cannot open AppDatabase: no Nostr private key in secure '
                  'storage. The user must complete login first.',
                );
              }
              return trackDb(AppDatabase(NativeDatabase.memory()));
            }),
          ],
        );
        addTearDown(container.dispose);

        expect(() => container.read(appDatabaseProvider), throwsStateError);

        keyPresent = true;
        expect(() => container.read(appDatabaseProvider), throwsStateError);

        container.invalidate(appDatabaseProvider);

        final db = container.read(appDatabaseProvider);
        expect(db, isA<AppDatabase>());
      },
    );
  });
}
