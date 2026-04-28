import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempSupportDir;

  setUp(() {
    tempSupportDir = Directory.systemTemp.createTempSync('horcrux_processed_store_clear_');
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

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null);
    if (tempSupportDir.existsSync()) {
      tempSupportDir.deleteSync(recursive: true);
    }
  });

  group('ProcessedNostrEventStore.clearAll', () {
    test('removes processed ids, claims, cursors and on-disk files', () async {
      final store = ProcessedNostrEventStore();

      await store.recordProcessed('event-1');
      await store.recordProcessed('event-2');
      await store.recordLastSeen('wss://relay.example/', 1700000000);
      expect(await store.claimEvent('claim-1'), isTrue);
      await store.flushToDisk();

      final logFile = File(p.join(tempSupportDir.path, 'processed_nostr_event_ids.log'));
      final cursorsFile =
          File(p.join(tempSupportDir.path, 'nostr_relay_subscription_cursors.json'));
      expect(logFile.existsSync(), isTrue);
      expect(cursorsFile.existsSync(), isTrue);

      // Drop a stale cursors .tmp file to make sure clearAll picks it up too.
      final staleTmp =
          File(p.join(tempSupportDir.path, 'nostr_relay_subscription_cursors.json.tmp'));
      await staleTmp.writeAsString('stale');
      expect(staleTmp.existsSync(), isTrue);

      await store.clearAll();

      expect(logFile.existsSync(), isFalse);
      expect(cursorsFile.existsSync(), isFalse);
      expect(staleTmp.existsSync(), isFalse);
      expect(await store.contains('event-1'), isFalse);
      expect(await store.contains('event-2'), isFalse);
      expect(await store.getLastSeen('wss://relay.example/'), isNull);
      // Released claim slot is reusable again.
      expect(await store.claimEvent('claim-1'), isTrue);
    });

    test('is safe to call before any state has been written', () async {
      final store = ProcessedNostrEventStore();
      await store.clearAll();
      expect(await store.contains('anything'), isFalse);
    });
  });
}
