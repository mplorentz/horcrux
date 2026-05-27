import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/database/app_database_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/deep_link_service.dart';
import 'package:horcrux/services/invitation_service.dart';

/// [DeepLinkService] outlives [appDatabaseProvider] invalidation (logout /
/// login). The lazy [InvitationService] lookup must not return a service still
/// bound to a closed database.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('deepLinkServiceProvider', () {
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
      'lazy invitation lookup uses the current database after invalidation',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWith(
              (ref) => trackDb(AppDatabase(NativeDatabase.memory())),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Same callback shape as [deepLinkServiceProvider].
        InvitationService lookup() => container.read(invitationServiceProvider);

        final deepLink = container.read(deepLinkServiceProvider);
        container.read(vaultRepositoryProvider);
        final firstDb = container.read(appDatabaseProvider);
        await firstDb.close();

        container.invalidate(appDatabaseProvider);

        // Simulates _processLink resolving InvitationService at tap time.
        final vaults = await lookup().repository.getAllVaults();
        expect(vaults, isEmpty);

        // Provider instance stays stable; only the lookup target changes.
        expect(container.read(deepLinkServiceProvider), same(deepLink));
      },
    );
  });
}
