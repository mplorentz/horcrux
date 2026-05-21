import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';

import 'package:horcrux/services/publish_service.dart';

import '../helpers/test_database.dart';

/// Creates a minimal [Nip01Event] with a deterministic ID.
Nip01Event _makeEvent(String id) {
  return Nip01Event(
    id: id,
    pubKey: 'a' * 64,
    kind: 1059,
    tags: const [],
    content: 'test',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}

void main() {
  group('PublishService', () {
    test(
      'enqueueEvent resolves promptly even when the relay broadcast never settles',
      () async {
        final db = newTestDatabase();
        addTearDown(() async => db.close());

        // NDK supplier that throws on connect — simulates unreachable relay.
        final service = PublishService(
          getNdk: () async {
            throw StateError('Bad state: No element');
          },
          database: db,
        );
        await service.initialize();
        addTearDown(service.disposeSync);

        final event = _makeEvent('a' * 64);
        final stopwatch = Stopwatch()..start();

        final result =
            await service.enqueueEvent(event: event, relays: ['wss://dead.example.com']).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException(
            'enqueueEvent did not return within 5 seconds',
          ),
        );

        stopwatch.stop();

        // Should resolve almost immediately — well under 1 second.
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(result.eventId, event.id);

        // Relay rows are left pending for the background worker to retry.
        final relayRows = await db.outboxDao.relaysFor(event.id);
        expect(relayRows, hasLength(1));
        expect(relayRows.first.status, 'pending');
        expect(relayRows.first.relayUrl, 'wss://dead.example.com');
      },
    );

    test(
      'enqueueEvent persists outbox row and resolves before any broadcast attempt',
      () async {
        final db = newTestDatabase();
        addTearDown(() async => db.close());

        final service = PublishService(
          getNdk: () async {
            throw StateError('Bad state: No element');
          },
          database: db,
        );
        await service.initialize();
        addTearDown(service.disposeSync);

        final event = _makeEvent('b' * 64);

        // Call enqueueEvent and verify it returns before _processQueue fires.
        // Because _processQueue is scheduled via Future.microtask, awaiting the
        // result here means the microtask hasn't necessarily run yet.
        final result = await service.enqueueEvent(
          event: event,
          relays: ['wss://a.example.com', 'wss://b.example.com'],
        );

        expect(result.eventId, event.id);
        // successfulRelays is always empty immediately after enqueue.
        expect(result.successfulRelays, isEmpty);

        // Outbox row must exist.
        final outboxRow = await db.outboxDao.getById(event.id);
        expect(outboxRow, isNotNull);

        // Both relay rows persisted.
        final relayRows = await db.outboxDao.relaysFor(event.id);
        expect(relayRows, hasLength(2));
      },
    );

    test(
      'duplicate enqueue for same event ID returns promptly without re-inserting',
      () async {
        final db = newTestDatabase();
        addTearDown(() async => db.close());

        final service = PublishService(
          getNdk: () async => throw StateError('Bad state: No element'),
          database: db,
        );
        await service.initialize();
        addTearDown(service.disposeSync);

        final event = _makeEvent('c' * 64);

        final r1 = await service.enqueueEvent(
          event: event,
          relays: ['wss://x.example.com'],
        );
        final r2 = await service.enqueueEvent(
          event: event,
          relays: ['wss://x.example.com'],
        );

        expect(r1.eventId, event.id);
        expect(r2.eventId, event.id);

        // Still only one outbox row.
        final outboxRow = await db.outboxDao.getById(event.id);
        expect(outboxRow, isNotNull);
      },
    );

    test(
      'Bad state: No element from NDK is recorded as a per-relay failure, not a crash',
      () async {
        final db = newTestDatabase();
        addTearDown(() async => db.close());

        final service = PublishService(
          getNdk: () async => throw StateError('Bad state: No element'),
          database: db,
        );
        await service.initialize();
        addTearDown(service.disposeSync);

        final event = _makeEvent('d' * 64);
        await service.enqueueEvent(
          event: event,
          relays: ['wss://dead.example.com'],
        );

        // Let the microtask-scheduled worker run.
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final relayRows = await db.outboxDao.relaysFor(event.id);
        expect(relayRows, hasLength(1));
        // After one attempt the relay row is still pending (not fatal).
        expect(relayRows.first.attempts, 1);
        expect(relayRows.first.lastError, contains('Bad state'));
      },
    );
  });
}
