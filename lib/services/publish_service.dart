import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import 'logger.dart';

typedef NdkSupplier = Future<Ndk> Function();

enum PublishRelayStatus { pending, success, failed }

class PublishRelayState {
  final PublishRelayStatus status;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String? lastError;

  const PublishRelayState({
    required this.status,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
  });

  PublishRelayState copyWith({
    PublishRelayStatus? status,
    int? attempts,
    DateTime? nextAttemptAt,
    String? lastError,
  }) {
    return PublishRelayState(
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'attempts': attempts,
      'nextAttemptAt': nextAttemptAt?.toIso8601String(),
      'lastError': lastError,
    };
  }

  factory PublishRelayState.fromJson(Map<String, dynamic> json) {
    return PublishRelayState(
      status: PublishRelayStatus.values.firstWhere(
        (value) => value.name == (json['status'] as String? ?? 'pending'),
        orElse: () => PublishRelayStatus.pending,
      ),
      attempts: json['attempts'] as int? ?? 0,
      nextAttemptAt:
          json['nextAttemptAt'] != null ? DateTime.tryParse(json['nextAttemptAt'] as String) : null,
      lastError: json['lastError'] as String?,
    );
  }
}

class PublishQueueItem {
  final String id;
  final Nip01Event event;
  final List<String> relays;
  final DateTime createdAt;
  final Map<String, PublishRelayState> relayStates;

  const PublishQueueItem({
    required this.id,
    required this.event,
    required this.relays,
    required this.createdAt,
    required this.relayStates,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event.toJson(),
      'relays': relays,
      'createdAt': createdAt.toIso8601String(),
      'relayStates': relayStates.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory PublishQueueItem.fromJson(Map<String, dynamic> json) {
    final relayStatesJson = json['relayStates'] as Map<String, dynamic>? ?? {};
    final relayStates = relayStatesJson.map(
      (key, value) => MapEntry(
        key,
        PublishRelayState.fromJson(value as Map<String, dynamic>),
      ),
    );

    final eventJson = json['event'] as Map<String, dynamic>;
    final event = Nip01Event.fromJson(eventJson);

    return PublishQueueItem(
      id: json['id'] as String,
      event: event,
      relays: (json['relays'] as List<dynamic>? ?? []).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      relayStates: relayStates,
    );
  }
}

class PublishQueueResult {
  final String? eventId;
  final List<String> successfulRelays;
  final List<String> failedRelays;

  const PublishQueueResult({
    required this.eventId,
    required this.successfulRelays,
    required this.failedRelays,
  });

  bool get allRelaysSucceeded => failedRelays.isEmpty && successfulRelays.isNotEmpty;
}

/// Persists publish work in the `outbox` / `outbox_relays` tables and drains it
/// with periodic retries (replacing the legacy SharedPreferences queue).
class PublishService {
  PublishService({
    required NdkSupplier getNdk,
    required AppDatabase database,
  })  : _getNdk = getNdk,
        _db = database;

  static const _legacyPrefsKey = 'publish_queue_items_v2';
  static const _maxAttemptsPerRelay = 15;
  static const _baseBackoffSeconds = 2;
  static const _maxBackoff = Duration(days: 1);

  final NdkSupplier _getNdk;
  final AppDatabase _db;

  final Map<String, Completer<PublishQueueResult>> _completers = {};
  Timer? _workerTimer;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _disposed = false;

  Future<void> initialize() async {
    if (_isInitialized || _disposed) {
      return;
    }

    await _migrateLegacyPrefsQueueIfNeeded();
    if (_disposed) {
      return;
    }
    _startWorker();
    _isInitialized = true;

    final pending = await _db
        .customSelect(
          "SELECT COUNT(*) AS c FROM outbox_relays WHERE status = 'pending'",
        )
        .getSingle();
    final c = pending.data['c'] as int? ?? 0;
    Log.info('PublishService initialized ($c pending outbox relay row(s))');
  }

  Future<PublishQueueResult> enqueueEvent({
    required Nip01Event event,
    required List<String> relays,
    String? vaultId,
  }) async {
    await _ensureInitialized();

    if (relays.isEmpty) {
      throw ArgumentError('Cannot enqueue publish with no relays');
    }

    final dedupedRelays = relays.toSet().toList();
    final id = event.id;

    final existingCompleter = _completers[id];
    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    final existingRow = await _db.outboxDao.getById(id);
    if (existingRow != null) {
      final c = Completer<PublishQueueResult>();
      _completers[id] = c;
      _scheduleImmediateWork();
      return c.future;
    }

    final completer = Completer<PublishQueueResult>();
    _completers[id] = completer;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final jsonStr = json.encode(event.toJson());

      await _db.transaction(() async {
        await _db.into(_db.outbox).insert(
              OutboxCompanion.insert(
                id: id,
                vaultId: vaultId != null ? Value(vaultId) : const Value.absent(),
                kind: event.kind,
                eventId: event.id,
                createdAt: now,
                eventJson: jsonStr,
              ),
            );

        for (final url in dedupedRelays) {
          await _db.into(_db.outboxRelays).insert(
                OutboxRelaysCompanion.insert(
                  outboxId: id,
                  relayUrl: url,
                  status: 'pending',
                ),
              );
        }
      });
    } catch (e, st) {
      _completers.remove(id);
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
      Log.error('enqueueEvent: failed to persist outbox for $id', e, st);
      rethrow;
    }

    _scheduleImmediateWork();
    return completer.future;
  }

  Future<void> onRelayReconnected(String relayUrl) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.outboxRelays)
          ..where((r) => r.relayUrl.equals(relayUrl) & r.status.equals('pending')))
        .write(OutboxRelaysCompanion(nextAttemptAt: Value(now)));
    _scheduleImmediateWork();
  }

  /// Cancels the periodic worker immediately. Safe to call multiple times.
  ///
  /// Riverpod may run [ref.onDispose] callbacks synchronously without awaiting
  /// async teardown, so tests and short-lived containers must stop timers here
  /// before the async [dispose] future runs.
  void disposeSync() {
    _disposed = true;
    _workerTimer?.cancel();
    _workerTimer = null;
  }

  Future<void> dispose() async {
    disposeSync();
  }

  Future<void> _ensureInitialized() async {
    if (_disposed) {
      throw StateError('PublishService is disposed');
    }
    if (_isInitialized) return;
    await initialize();
    if (_disposed) {
      throw StateError('PublishService is disposed');
    }
  }

  void _startWorker() {
    if (_disposed) {
      return;
    }
    _workerTimer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) => _processQueue(),
    );
  }

  void _scheduleImmediateWork() {
    Future.microtask(_processQueue);
  }

  Future<void> _processQueue() async {
    if (_disposed) {
      return;
    }
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final due = await _db.outboxDao.dueRelays(nowMs: nowMs);

      for (final relayRow in due) {
        await _processOneRelay(relayRow, nowMs: nowMs);
      }
    } catch (e, stackTrace) {
      Log.error('Error processing publish outbox', e, stackTrace);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processOneRelay(OutboxRelayRow relayRow, {required int nowMs}) async {
    final out = await _db.outboxDao.getById(relayRow.outboxId);
    if (out == null) {
      return;
    }

    Nip01Event event;
    try {
      event = Nip01Event.fromJson(json.decode(out.eventJson) as Map<String, dynamic>);
    } catch (e, st) {
      Log.error('Outbox ${out.id}: invalid event_json', e, st);
      await _markRelayFailed(
        relayRow: relayRow,
        attempts: relayRow.attempts + 1,
        error: 'Invalid stored event JSON',
        terminal: true,
      );
      await _finalizeOutboxIfComplete(out.id);
      return;
    }

    final outcome = await _broadcastToRelay(
      event: event,
      relayUrl: relayRow.relayUrl,
    );

    final attempts = relayRow.attempts + 1;
    if (outcome.success) {
      await (_db.update(_db.outboxRelays)
            ..where(
              (r) => r.outboxId.equals(relayRow.outboxId) & r.relayUrl.equals(relayRow.relayUrl),
            ))
          .write(
        OutboxRelaysCompanion(
          status: const Value('success'),
          attempts: Value(attempts),
          nextAttemptAt: const Value(null),
          lastError: const Value(null),
        ),
      );
    } else {
      final backoffDelay = _backoffForAttempt(attempts);
      final terminal = attempts >= _maxAttemptsPerRelay;
      final nextMs = terminal ? null : nowMs + backoffDelay.inMilliseconds;
      await _markRelayFailed(
        relayRow: relayRow,
        attempts: attempts,
        error: outcome.message,
        terminal: terminal,
        nextAttemptAtMs: nextMs,
      );
    }

    await _finalizeOutboxIfComplete(out.id);
  }

  Future<void> _markRelayFailed({
    required OutboxRelayRow relayRow,
    required int attempts,
    required String? error,
    required bool terminal,
    int? nextAttemptAtMs,
  }) async {
    await (_db.update(_db.outboxRelays)
          ..where(
            (r) => r.outboxId.equals(relayRow.outboxId) & r.relayUrl.equals(relayRow.relayUrl),
          ))
        .write(
      OutboxRelaysCompanion(
        status: Value(terminal ? 'failed' : 'pending'),
        attempts: Value(attempts),
        nextAttemptAt: Value(nextAttemptAtMs),
        lastError: Value(error),
      ),
    );
  }

  Future<void> _finalizeOutboxIfComplete(String outboxId) async {
    final relays = await _db.outboxDao.relaysFor(outboxId);
    if (relays.isEmpty) {
      return;
    }

    final allDone = relays.every(
      (r) => r.status == 'success' || r.status == 'failed' || r.attempts >= _maxAttemptsPerRelay,
    );
    if (!allDone) {
      return;
    }

    final out = await _db.outboxDao.getById(outboxId);
    if (out == null) {
      return;
    }

    final successfulRelays =
        relays.where((r) => r.status == 'success').map((r) => r.relayUrl).toList();
    final failedRelays = relays.where((r) => r.status == 'failed').map((r) => r.relayUrl).toList();

    final result = PublishQueueResult(
      eventId: out.eventId,
      successfulRelays: successfulRelays,
      failedRelays: failedRelays,
    );

    final completer = _completers.remove(outboxId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }

    await _db.outboxDao.deleteOutboxCascade(outboxId);
  }

  Future<_RelayAttemptOutcome> _broadcastToRelay({
    required Nip01Event event,
    required String relayUrl,
  }) async {
    try {
      final ndk = await _getNdk();
      final response = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relayUrl],
      );

      final results = await response.broadcastDoneFuture;
      final matchingResults = results.where((result) => result.relayUrl == relayUrl).toList();
      final relayResult = matchingResults.isNotEmpty
          ? matchingResults.first
          : (results.isNotEmpty ? results.first : null);

      if (relayResult == null) {
        return _RelayAttemptOutcome(
          success: false,
          message: 'No relay response for $relayUrl',
        );
      }

      return _RelayAttemptOutcome(
        success: relayResult.broadcastSuccessful,
        message: relayResult.msg,
      );
    } catch (e) {
      final message = e.toString();
      if (message.contains('Bad state: No element')) {
        try {
          final ndk = await _getNdk();
          final response = ndk.broadcast.broadcast(nostrEvent: event);
          final results = await response.broadcastDoneFuture;
          final success = results.any((result) => result.broadcastSuccessful);
          final fallbackMessage = results.isNotEmpty ? results.first.msg : '';
          return _RelayAttemptOutcome(
            success: success,
            message: success ? '' : (fallbackMessage.isNotEmpty ? fallbackMessage : message),
          );
        } catch (fallbackError) {
          return _RelayAttemptOutcome(
            success: false,
            message: fallbackError.toString(),
          );
        }
      }

      return _RelayAttemptOutcome(
        success: false,
        message: message,
      );
    }
  }

  Duration _backoffForAttempt(int attempt) {
    final seconds = _baseBackoffSeconds * pow(2, max(0, attempt - 1));
    final delay = Duration(seconds: seconds.toInt());
    if (delay > _maxBackoff) return _maxBackoff;
    return delay;
  }

  Future<void> _migrateLegacyPrefsQueueIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_legacyPrefsKey);
      if (data == null || data.isEmpty) {
        return;
      }

      final decoded = json.decode(data) as List<dynamic>;
      var migrated = 0;
      for (final entry in decoded) {
        final item = PublishQueueItem.fromJson(entry as Map<String, dynamic>);
        final existing = await _db.outboxDao.getById(item.id);
        if (existing != null) {
          continue;
        }
        final createdMs = item.createdAt.millisecondsSinceEpoch;
        final jsonStr = json.encode(item.event.toJson());
        await _db.transaction(() async {
          await _db.into(_db.outbox).insert(
                OutboxCompanion.insert(
                  id: item.id,
                  kind: item.event.kind,
                  eventId: item.event.id,
                  createdAt: createdMs,
                  eventJson: jsonStr,
                ),
              );
          final relayUrls = {...item.relays, ...item.relayStates.keys};
          for (final relay in relayUrls) {
            final st = item.relayStates[relay] ??
                const PublishRelayState(status: PublishRelayStatus.pending, attempts: 0);
            final statusName = switch (st.status) {
              PublishRelayStatus.success => 'success',
              PublishRelayStatus.failed => 'failed',
              PublishRelayStatus.pending => 'pending',
            };
            await _db.into(_db.outboxRelays).insert(
                  OutboxRelaysCompanion.insert(
                    outboxId: item.id,
                    relayUrl: relay,
                    status: statusName,
                    attempts: Value(st.attempts),
                    nextAttemptAt: Value(st.nextAttemptAt?.millisecondsSinceEpoch),
                    lastError: Value(st.lastError),
                  ),
                );
          }
        });
        migrated++;
      }

      await prefs.remove(_legacyPrefsKey);
      if (migrated > 0) {
        Log.info('Migrated $migrated publish queue item(s) from SharedPreferences to outbox');
      }
    } catch (e, st) {
      Log.warning('Legacy publish queue migration skipped/failed', e, st);
    }
  }
}

class _RelayAttemptOutcome {
  final bool success;
  final String? message;

  _RelayAttemptOutcome({
    required this.success,
    required this.message,
  });
}
