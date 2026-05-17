import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/database/app_database_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';
import '../helpers/test_database.dart';

/// Tests for the "Continue Without Account" bug (horcrux_app-hjnr).
///
/// The "Continue Without Account" path in AccountChoiceScreen calls
/// `initializeKey()` followed by `initializeAppServices(ref)`, but skips
/// invalidating the key-dependent providers (`isLoggedInProvider`,
/// `currentPublicKeyProvider`, `currentPublicKeyBech32Provider`).
///
/// The fix replaces `initializeAppServices(ref)` with
/// `initializeAppAndRefreshKeys(ref)`, which also calls the three
/// `ref.invalidate(...)` calls needed to refresh the cached providers.
///
/// ⚠️ [LoginService._cachedKeyPair] is a **static** field.  Each test calls
/// [LoginService.resetCache] in setUp so provider state is fully isolated.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('Continue Without Account provider invalidation', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      LoginService.resetCache();
    });

    ProviderContainer makeContainer({AppDatabase? db}) {
      return ProviderContainer(
        overrides: [
          loginServiceProvider.overrideWith((ref) => LoginService()),
          if (db != null) appDatabaseProvider.overrideWithValue(db),
        ],
      );
    }

    test(
      'Test 1: the broken path — initializeKey without invalidation leaves '
      'providers stale',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        // Initially no key exists → providers return safe fallback values.
        expect(await container.read(isLoggedInProvider.future), false);
        expect(await container.read(currentPublicKeyProvider.future), null);

        // Simulate the "Continue Without Account" path: generate key but
        // DON'T invalidate providers (the bug).
        final loginService = container.read(loginServiceProvider);
        await loginService.initializeKey();

        // Providers still return the stale cached values because they were
        // never invalidated after the new key was written to secure storage.
        expect(await container.read(isLoggedInProvider.future), false);
        expect(await container.read(currentPublicKeyProvider.future), null);
      },
    );

    test(
      'Test 2: the fix — invalidating providers after initializeKey returns '
      'correct values',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        // Confirm initial state: no key.
        expect(await container.read(isLoggedInProvider.future), false);
        expect(await container.read(currentPublicKeyProvider.future), null);

        // Generate a key (same as the Continue Without Account path).
        final loginService = container.read(loginServiceProvider);
        await loginService.initializeKey();

        // Invalidate providers — this is what `initializeAppAndRefreshKeys`
        // does that `initializeAppServices` does not.
        container.invalidate(isLoggedInProvider);
        container.invalidate(currentPublicKeyProvider);
        container.invalidate(currentPublicKeyBech32Provider);

        // Now providers re-resolve and find the key.
        expect(await container.read(isLoggedInProvider.future), true);
        final pubkey = await container.read(currentPublicKeyProvider.future);
        expect(pubkey, isA<String>());
        expect(pubkey!.length, greaterThan(0));
        final pubkeyBech32 = await container.read(
          currentPublicKeyBech32Provider.future,
        );
        expect(pubkeyBech32, isA<String>());
        expect(pubkeyBech32!.length, greaterThan(0));
      },
    );

    test(
      'Test 3: database queries succeed after key initialization and provider '
      'invalidation',
      () async {
        final db = newTestDatabase();
        addTearDown(() => db.close());

        final container = makeContainer(db: db);
        addTearDown(container.dispose);

        // Confirm initial state: no key.
        expect(await container.read(isLoggedInProvider.future), false);

        // Generate key (same as Continue Without Account path).
        final loginService = container.read(loginServiceProvider);
        await loginService.initializeKey();

        // Invalidate providers (the fix).
        container.invalidate(isLoggedInProvider);
        container.invalidate(currentPublicKeyProvider);
        container.invalidate(currentPublicKeyBech32Provider);

        // Reading key-dependent providers should succeed.
        final isLoggedIn = await container.read(isLoggedInProvider.future);
        expect(isLoggedIn, true);

        // Database queries should work without StateError.
        final repo = container.read(vaultRepositoryProvider);
        final vaults = await repo.getAllVaults();
        expect(vaults, isEmpty);
      },
    );
  });
}
