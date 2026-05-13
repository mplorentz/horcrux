import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/database/app_database_provider.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';
import 'package:horcrux/services/share_distribution_service.dart';

import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('horcrux_app-76m NdkService / ShareDistributionService providers', () {
    final databases = <AppDatabase>[];

    AppDatabase trackDb(AppDatabase db) {
      databases.add(db);
      return db;
    }

    List<Override> testOverrides() => [
          processedNostrEventStoreProvider.overrideWith((ref) {
            final store = ProcessedNostrEventStore();
            ref.onDispose(() {
              // Skip [flushToDisk]: it races test tearDown when the temp support
              // directory is deleted while async I/O is still in flight.
            });
            return store;
          }),
          appDatabaseProvider.overrideWith(
            (ref) => trackDb(newTestDatabase()),
          ),
        ];

    late Directory tempSupportDir;

    setUp(() {
      tempSupportDir = Directory.systemTemp.createTempSync('horcrux_ndk_cycle_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return tempSupportDir.path;
          }
          return null;
        },
      );
    });

    tearDown(() async {
      for (final db in databases) {
        try {
          await db.close();
        } catch (_) {}
      }
      databases.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      if (tempSupportDir.existsSync()) {
        tempSupportDir.deleteSync(recursive: true);
      }
    });

    test(
      'ndkServiceProvider can read shareDistributionServiceProvider '
      'without CircularDependencyError',
      () {
        final container = ProviderContainer(
          overrides: testOverrides(),
        );
        addTearDown(container.dispose);

        final ndk = container.read(ndkServiceProvider);
        expect(
          () => ndk.debugReadShareDistributionServiceForTesting(),
          returnsNormally,
        );
        expect(
          ndk.debugReadShareDistributionServiceForTesting(),
          isA<ShareDistributionService>(),
        );
      },
    );

    test(
      'invalidating appDatabaseProvider rebuilds ndkServiceProvider '
      'and shareDistributionServiceProvider',
      () {
        final container = ProviderContainer(
          overrides: testOverrides(),
        );
        addTearDown(container.dispose);

        final db1 = container.read(appDatabaseProvider);
        final ndk1 = container.read(ndkServiceProvider);
        final share1 = ndk1.debugReadShareDistributionServiceForTesting();

        container.invalidate(appDatabaseProvider);

        final db2 = container.read(appDatabaseProvider);
        final ndk2 = container.read(ndkServiceProvider);
        final share2 = ndk2.debugReadShareDistributionServiceForTesting();

        expect(db2, isNot(same(db1)));
        expect(ndk2, isNot(same(ndk1)));
        expect(share2, isNot(same(share1)));
      },
    );
  });
}
