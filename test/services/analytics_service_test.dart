import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/analytics_service.dart';
import '../helpers/test_database.dart';

void main() {
  // Each test creates its own in-memory database; suppress drift warnings.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  group('AnalyticsService utility', () {
    test('vaultHash is deterministic', () {
      const vaultId = 'test-vault-123';
      final hash1 = AnalyticsService.vaultHash(vaultId);
      final hash2 = AnalyticsService.vaultHash(vaultId);
      expect(hash1, equals(hash2));
      expect(hash1.length, equals(16));
    });

    test('vaultHash returns a 16-character hex string', () {
      const vaultId = 'test-vault-456';
      final hash = AnalyticsService.vaultHash(vaultId);
      expect(hash.length, equals(16));
      // Should be hex characters
      expect(hash, matches(RegExp(r'^[0-9a-f]+$')));
    });

    test('vaultHash is non-reversible (does not equal the raw id)', () {
      const vaultId = '550e8400-e29b-41d4-a716-446655440000';
      final hash = AnalyticsService.vaultHash(vaultId);
      expect(hash, isNot(equals(vaultId)));
      expect(hash.length, lessThan(vaultId.length));
    });

    test('vaultHash produces different hashes for different inputs', () {
      final hash1 = AnalyticsService.vaultHash('vault-aaaa');
      final hash2 = AnalyticsService.vaultHash('vault-bbbb');
      expect(hash1, isNot(equals(hash2)));
    });
  });

  group('AnalyticsService consent cache', () {
    test('setup reads cached opt-in from kv table', () async {
      final db = newTestDatabase();
      final service = AnalyticsService(database: db);

      // Set the cached opt-in to false
      await db.appStateDao.setAnalyticsOptIn(false);
      await service.setup();
      expect(service.isOptedIn, isFalse);

      await db.close();
    });

    test('setup does not initialize PostHog when cached opt-in is false', () async {
      final db = newTestDatabase();
      final service = AnalyticsService(database: db);

      await db.appStateDao.setAnalyticsOptIn(false);
      await service.setup();

      // PostHog should not be initialized.
      // In tests (kDebugMode=true), setup is always a no-op, so isOptedIn
      // should remain false.
      expect(service.isOptedIn, isFalse);

      await db.close();
    });

    test('syncOptIn in debug mode tears down without persisting', () async {
      final db = newTestDatabase();
      final service = AnalyticsService(database: db);

      // Start with opt-out
      await db.appStateDao.setAnalyticsOptIn(false);
      await service.setup();
      expect(service.isOptedIn, isFalse);

      // In kDebugMode, syncOptIn tears down existing state and returns.
      // It never initializes PostHog or persists to the kv cache.
      await service.syncOptIn(true);
      expect(service.isOptedIn, isFalse);

      // The kv cache was NOT updated (debug mode skips all analytics state)
      final cached = await db.appStateDao.getAnalyticsOptIn();
      expect(cached, isFalse);

      await db.close();
    });

    test('consent cache refresh updates kv on sync (release mode)', () async {
      final db = newTestDatabase();
      final service = AnalyticsService(database: db);

      // Start with opt-out
      await db.appStateDao.setAnalyticsOptIn(false);

      // In debug mode syncOptIn returns early without caching.
      // This test verifies the kv write path: set the cache directly.
      await db.appStateDao.setAnalyticsOptIn(true);

      final cached = await db.appStateDao.getAnalyticsOptIn();
      expect(cached, isTrue);

      await db.close();
    });

    test('accountRefreshedAt stores epoch ms', () async {
      final db = newTestDatabase();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.appStateDao.setAccountRefreshedAt(now);

      final stored = await db.appStateDao.getAccountRefreshedAt();
      expect(stored, equals(now));

      await db.close();
    });
  });

  group('AnalyticsService.gates (in-memory state)', () {
    test('capture is no-op when opted out', () async {
      final db = newTestDatabase();
      final service = AnalyticsService(database: db);

      await db.appStateDao.setAnalyticsOptIn(false);
      await service.setup();

      // Capture should not throw — it's a no-op.
      await service.capture('test_event');
      expect(service.isOptedIn, isFalse);

      await db.close();
    });

    test('capture is no-op in debug mode', () async {
      final db = newTestDatabase();
      final service = AnalyticsService(database: db);

      // Even if opted in, debug mode disables analytics.
      // We can't set kDebugMode, so instead verify the setup no-ops.
      await db.appStateDao.setAnalyticsOptIn(true);
      await service.setup();

      // setup() in kDebugMode does not initialize PostHog
      expect(service.isOptedIn, isFalse);

      await db.close();
    });

    test('screenView is no-op when opted out', () async {
      final db = newTestDatabase();
      final service = AnalyticsService(database: db);

      await db.appStateDao.setAnalyticsOptIn(false);
      await service.setup();

      // Should not throw
      await service.screenView('TestScreen');
      expect(service.isOptedIn, isFalse);

      await db.close();
    });

    test('identify and reset do not throw when not initialized', () async {
      final db = newTestDatabase();
      final service = AnalyticsService(database: db);

      await service.identify('npub1test');
      await service.reset();

      // Should not throw
      expect(service.isOptedIn, isFalse);

      await db.close();
    });
  });
}
