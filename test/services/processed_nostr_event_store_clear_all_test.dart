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

    test('deletes the WAL when records have not been flushed yet', () async {
      final store = ProcessedNostrEventStore();

      // recordProcessed appends to the WAL synchronously but only schedules a
      // debounced merge into the main log. Without a flushToDisk() the WAL is
      // the only on-disk artifact -- exactly the case where a missing WAL
      // cleanup in clearAll() would leak the previous identity's events.
      await store.recordProcessed('wal-only-1');
      await store.recordProcessed('wal-only-2');

      final walFile = File(p.join(tempSupportDir.path, 'processed_nostr_event_ids.wal'));
      final logFile = File(p.join(tempSupportDir.path, 'processed_nostr_event_ids.log'));
      expect(walFile.existsSync(), isTrue,
          reason: 'WAL must exist before clearAll for this test to be meaningful');
      expect(logFile.existsSync(), isFalse,
          reason: 'log should not exist yet -- nothing has been flushed/merged');

      await store.clearAll();

      expect(walFile.existsSync(), isFalse);
      expect(await store.contains('wal-only-1'), isFalse);
      expect(await store.contains('wal-only-2'), isFalse);
    });

    test('flushToDisk launched concurrently with clearAll is still suppressed', () async {
      // Regression for the race where flushToDisk reads the suppression flag
      // before clearAll's body has set it, then queues behind clearAll in the
      // serialization chain and recreates the cursors file once clearAll
      // returns. The flag check must live inside _serialized.
      final store = ProcessedNostrEventStore();

      await store.recordProcessed('event-A');
      await store.recordLastSeen('wss://relay.example/', 1700000000);
      await store.flushToDisk();

      final cursorsFile =
          File(p.join(tempSupportDir.path, 'nostr_relay_subscription_cursors.json'));
      expect(cursorsFile.existsSync(), isTrue);

      // Kick off clearAll first so it owns the front of the serialization
      // chain, then launch flushToDisk synchronously (no await between them)
      // so it sees the flag as still-false at the time of the call but ends
      // up queued behind clearAll. Awaiting them together drains both.
      final clearFuture = store.clearAll();
      final flushFuture = store.flushToDisk();
      await Future.wait([clearFuture, flushFuture]);

      expect(cursorsFile.existsSync(), isFalse,
          reason: 'queued flushToDisk must observe clearAll suppression');
    });

    test('flushToDisk is suppressed after clearAll until the next write', () async {
      final store = ProcessedNostrEventStore();

      await store.recordProcessed('event-A');
      await store.recordLastSeen('wss://relay.example/', 1700000000);
      await store.flushToDisk();

      final cursorsFile =
          File(p.join(tempSupportDir.path, 'nostr_relay_subscription_cursors.json'));
      expect(cursorsFile.existsSync(), isTrue);

      await store.clearAll();
      expect(cursorsFile.existsSync(), isFalse);

      // A dispose-time flush after clearAll must not resurrect the cursors
      // file from the now-empty in-memory map.
      await store.flushToDisk();
      expect(cursorsFile.existsSync(), isFalse);

      // Once a real write happens again the suppression lifts and flushes
      // resume normally.
      await store.recordLastSeen('wss://relay.example/', 1700000001);
      await store.flushToDisk();
      expect(cursorsFile.existsSync(), isTrue);
    });

    test('is safe to call before any state has been written', () async {
      final store = ProcessedNostrEventStore();
      await store.clearAll();
      expect(await store.contains('anything'), isFalse);
    });
  });
}
