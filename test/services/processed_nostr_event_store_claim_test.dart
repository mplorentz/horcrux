import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempSupportDir;

  setUp(() {
    tempSupportDir = Directory.systemTemp.createTempSync('horcrux_processed_store_');
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

  group('ProcessedNostrEventStore claims', () {
    test('second claimEvent for same id returns false until released', () async {
      final store = ProcessedNostrEventStore();
      const id = 'abc123';

      expect(await store.claimEvent(id), isTrue);
      expect(await store.claimEvent(id), isFalse);

      await store.releaseClaimedEvent(id);
      expect(await store.claimEvent(id), isTrue);
      await store.releaseClaimedEvent(id);
    });

    test('claimEvent returns false after recordProcessed', () async {
      final store = ProcessedNostrEventStore();
      const id = 'evt1';

      expect(await store.claimEvent(id), isTrue);
      await store.recordProcessed(id);
      expect(await store.claimEvent(id), isFalse);
    });

    test('recordProcessed clears claim without double-append', () async {
      final store = ProcessedNostrEventStore();
      const id = 'evt2';

      expect(await store.claimEvent(id), isTrue);
      await store.recordProcessed(id);
      expect(await store.contains(id), isTrue);
      await store.recordProcessed(id);
      expect(await store.contains(id), isTrue);
    });

    test('empty id is rejected', () async {
      final store = ProcessedNostrEventStore();
      expect(await store.claimEvent(''), isFalse);
    });
  });
}
