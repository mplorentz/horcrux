import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  PublishQueueItem copyWith({
    Map<String, PublishRelayState>? relayStates,
  }) {
    return PublishQueueItem(
      id: id,
      event: event,
      relays: relays,
      createdAt: createdAt,
      relayStates: relayStates ?? this.relayStates,
    );
  }

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

/// The job of the PublishService is to do everything we can to make sure all events get
/// persisted to relays regardless of network conditions. We accomplish this by writing events
/// to disk and retrying the publishing operation many times over several days.
class PublishService {
  PublishService({
    required NdkSupplier getNdk,
  }) : _getNdk = getNdk;

  static const _storageKey = 'publish_queue_items_v2';
  static const _maxAttemptsPerRelay = 15;
  static const _baseBackoffSeconds = 2;
  static const _maxBackoff = Duration(days: 1);

  final NdkSupplier _getNdk;

  final Map<String, PublishQueueItem> _queue = {};
  final Map<String, Completer<PublishQueueResult>> _completers = {};
  Timer? _workerTimer;
  bool _isProcessing = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadQueue();
    _startWorker();
    _isInitialized = true;
    Log.info('PublishService initialized with ${_queue.length} pending item(s)');
    if (_queue.isNotEmpty) {
      Log.trace('PublishService: Loaded queue items: ${_queue.keys.toList()}');
      for (final item in _queue.values) {
        Log.trace(
          'PublishService: Queue item ${item.id}: event=${item.event.id.substring(0, 8)}..., '
          'relays=${item.relays.length}, '
          'created=${item.createdAt.toIso8601String()}',
        );
      }
    }
  }

  Future<PublishQueueResult> enqueueEvent({
    required Nip01Event event,
    required List<String> relays,
  }) async {
    await _ensureInitialized();

    if (relays.isEmpty) {
      throw ArgumentError('Cannot enqueue publish with no relays');
    }

    final dedupedRelays = relays.toSet().toList();
    Log.trace(
      'PublishService: Enqueuing event ${event.id.substring(0, 8)}... (kind ${event.kind}) '
      'to ${dedupedRelays.length} relay(s): ${dedupedRelays.join(", ")}',
    );

    final relayStates = {
      for (final relay in dedupedRelays)
        relay: const PublishRelayState(
          status: PublishRelayStatus.pending,
          attempts: 0,
        ),
    };

    final item = PublishQueueItem(
      id: event.id,
      event: event,
      relays: dedupedRelays,
      createdAt: DateTime.now(),
      relayStates: relayStates,
    );

    final completer = Completer<PublishQueueResult>();
    _queue[item.id] = item;
    _completers[item.id] = completer;

    Log.trace('PublishService: Queue item ${item.id.substring(0, 8)}... created, queue size: ${_queue.length}');
    await _persistQueue();
    _scheduleImmediateWork();

    return completer.future;
  }

  void onRelayReconnected(String relayUrl) {
    Log.trace('PublishService: Relay reconnected: $relayUrl');
    int updatedCount = 0;
    for (final entry in _queue.entries) {
      final item = entry.value;
      final state = item.relayStates[relayUrl];
      if (state == null || state.status == PublishRelayStatus.success) continue;
      final updatedRelayStates = Map<String, PublishRelayState>.from(item.relayStates);
      updatedRelayStates[relayUrl] = state.copyWith(
        nextAttemptAt: DateTime.now(),
      );
      _queue[entry.key] = item.copyWith(relayStates: updatedRelayStates);
      updatedCount++;
      Log.trace(
        'PublishService: Updated queue item ${item.id.substring(0, 8)}...: relay $relayUrl '
        '(attempt ${state.attempts}, status ${state.status.name}) -> ready for retry',
      );
    }

    if (updatedCount > 0) {
      Log.trace(
          'PublishService: Scheduled immediate work for $updatedCount item(s) after relay reconnect');
    }
    _scheduleImmediateWork();
  }

  Future<void> dispose() async {
    _workerTimer?.cancel();
    _workerTimer = null;
    await _persistQueue();
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await initialize();
  }

  void _startWorker() {
    _workerTimer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) => _processQueue(),
    );
  }

  void _scheduleImmediateWork() {
    // Run asynchronously to avoid deep call stacks
    Log.trace('PublishService: Scheduling immediate queue processing');
    Future.microtask(_processQueue);
  }

  Future<void> _processQueue() async {
    if (_isProcessing) {
      Log.trace('PublishService: Queue processing already in progress, skipping');
      return;
    }
    _isProcessing = true;

    try {
      final now = DateTime.now();
      final completedIds = <String>[];

      final pendingItems = List<PublishQueueItem>.from(_queue.values);
      Log.trace('PublishService: Processing queue: ${pendingItems.length} item(s)');

      for (final item in pendingItems) {
        final pendingRelays = item.relayStates.entries.where(
          (entry) {
            final state = entry.value;
            return switch (state.status) {
              PublishRelayStatus.success => false,
              PublishRelayStatus.failed => false,
              PublishRelayStatus.pending => state.attempts < _maxAttemptsPerRelay &&
                  (state.nextAttemptAt == null || !state.nextAttemptAt!.isAfter(now)),
            };
          },
        ).toList();

        Log.trace(
          'PublishService: Queue item ${item.id}: ${pendingRelays.length} pending relay(s) '
          'out of ${item.relayStates.length} total',
        );

        if (pendingRelays.isEmpty) {
          if (_isFinished(item)) {
            Log.trace(
                'PublishService: Queue item ${item.id} is finished, marking for completion');
            completedIds.add(item.id);
          }
          continue;
        }

        for (final relayEntry in pendingRelays) {
          final relayUrl = relayEntry.key;
          final state = relayEntry.value;
          Log.trace(
            'PublishService: Broadcasting item ${item.id} to relay $relayUrl '
            '(attempt ${state.attempts + 1}/$_maxAttemptsPerRelay)',
          );

          final outcome = await _broadcastToRelay(
            event: item.event,
            relayUrl: relayUrl,
          );

          Log.trace(
            'PublishService: Broadcast result for item ${item.id} to $relayUrl: '
            'success=${outcome.success}, message=${outcome.message}',
          );

          _updateRelayState(
            itemId: item.id,
            relayUrl: relayUrl,
            success: outcome.success,
            error: outcome.message,
          );
        }

        if (_isFinished(_queue[item.id]!)) {
          Log.trace('PublishService: Queue item ${item.id} finished after processing');
          completedIds.add(item.id);
        }
      }

      if (completedIds.isNotEmpty) {
        Log.trace('PublishService: Completing ${completedIds.length} queue item(s)');
        for (final id in completedIds) {
          final completedItem = _queue.remove(id);
          final completer = _completers.remove(id);
          if (completedItem == null) continue;
          final successfulRelays = completedItem.relayStates.entries
              .where((entry) => entry.value.status == PublishRelayStatus.success)
              .map((entry) => entry.key)
              .toList();
          final failedRelays = completedItem.relayStates.entries
              .where((entry) => entry.value.status == PublishRelayStatus.failed)
              .map((entry) => entry.key)
              .toList();

          Log.trace(
            'PublishService: Queue item $id completed: '
            'event=${completedItem.event.id.substring(0, 8)}..., '
            'successful=${successfulRelays.length}, failed=${failedRelays.length}',
          );

          final result = PublishQueueResult(
            eventId: completedItem.event.id,
            successfulRelays: successfulRelays,
            failedRelays: failedRelays,
          );

          if (completer != null && !completer.isCompleted) {
            completer.complete(result);
            Log.trace('PublishService: Completed future for queue item $id');
          }
        }
      } else {
        Log.trace('PublishService: No items completed in this processing cycle');
      }
    } catch (e, stackTrace) {
      Log.error('Error processing publish queue', e);
      Log.debug('Publish queue processing stack', stackTrace);
    } finally {
      await _persistQueue();
      _isProcessing = false;
      Log.trace(
          'PublishService: Queue processing cycle complete, queue size: ${_queue.length}');
    }
  }

  Future<_RelayAttemptOutcome> _broadcastToRelay({
    required Nip01Event event,
    required String relayUrl,
  }) async {
    Log.trace(
        'PublishService: Broadcasting event ${event.id.substring(0, 8)}... to relay $relayUrl');
    try {
      final ndk = await _getNdk();
      final response = ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [relayUrl],
      );

      final results = await response.broadcastDoneFuture;
      Log.trace('PublishService: Received ${results.length} broadcast result(s)');
      final matchingResults = results.where((result) => result.relayUrl == relayUrl).toList();
      final relayResult = matchingResults.isNotEmpty
          ? matchingResults.first
          : (results.isNotEmpty ? results.first : null);

      if (relayResult == null) {
        Log.trace('PublishService: No relay response found for $relayUrl');
        return _RelayAttemptOutcome(
          success: false,
          message: 'No relay response for $relayUrl',
        );
      }

      Log.trace(
        'PublishService: Relay $relayUrl response: success=${relayResult.broadcastSuccessful}, '
        'message=${relayResult.msg}',
      );
      return _RelayAttemptOutcome(
        success: relayResult.broadcastSuccessful,
        message: relayResult.msg,
      );
    } catch (e) {
      final message = e.toString();
      Log.trace('PublishService: Broadcast error to $relayUrl: $message');
      if (message.contains('Bad state: No element')) {
        Log.trace('PublishService: Attempting fallback broadcast without specific relay');
        try {
          final ndk = await _getNdk();
          final response = ndk.broadcast.broadcast(nostrEvent: event);
          final results = await response.broadcastDoneFuture;
          final success = results.any((result) => result.broadcastSuccessful);
          final fallbackMessage = results.isNotEmpty ? results.first.msg : '';
          Log.trace('PublishService: Fallback broadcast result: success=$success');
          return _RelayAttemptOutcome(
            success: success,
            message: success ? '' : (fallbackMessage.isNotEmpty ? fallbackMessage : message),
          );
        } catch (fallbackError) {
          Log.trace('PublishService: Fallback broadcast also failed: $fallbackError');
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

  void _updateRelayState({
    required String itemId,
    required String relayUrl,
    required bool success,
    required String? error,
  }) {
    final item = _queue[itemId];
    if (item == null) {
      Log.trace('PublishService: Cannot update relay state: item $itemId not found in queue');
      return;
    }

    final existing = item.relayStates[relayUrl] ??
        const PublishRelayState(
          status: PublishRelayStatus.pending,
          attempts: 0,
        );

    final updatedRelayStates = Map<String, PublishRelayState>.from(item.relayStates);

    if (success) {
      Log.trace(
        'PublishService: Queue item $itemId: relay $relayUrl succeeded '
        '(attempt ${existing.attempts + 1})',
      );
      updatedRelayStates[relayUrl] = existing.copyWith(
        status: PublishRelayStatus.success,
        attempts: existing.attempts + 1,
        nextAttemptAt: null,
        lastError: null,
      );
      _queue[itemId] = item.copyWith(relayStates: updatedRelayStates);
      return;
    }

    final attempts = existing.attempts + 1;
    final backoffDelay = _backoffForAttempt(attempts);
    final nextAttempt = attempts >= _maxAttemptsPerRelay ? null : DateTime.now().add(backoffDelay);

    final newStatus =
        attempts >= _maxAttemptsPerRelay ? PublishRelayStatus.failed : PublishRelayStatus.pending;

    Log.trace(
      'PublishService: Queue item $itemId: relay $relayUrl failed '
      '(attempt $attempts/$_maxAttemptsPerRelay, status=$newStatus)',
    );
    if (nextAttempt != null) {
      Log.trace(
        'PublishService: Queue item $itemId: scheduling retry for $relayUrl at '
        '${nextAttempt.toIso8601String()} (backoff: ${backoffDelay.inSeconds}s)',
      );
    } else {
      Log.trace(
          'PublishService: Queue item $itemId: relay $relayUrl exceeded max attempts, marking as failed');
    }

    updatedRelayStates[relayUrl] = existing.copyWith(
      status: newStatus,
      attempts: attempts,
      nextAttemptAt: nextAttempt,
      lastError: error,
    );
    _queue[itemId] = item.copyWith(relayStates: updatedRelayStates);
  }

  bool _isFinished(PublishQueueItem item) {
    return item.relayStates.values.every(
      (state) =>
          state.status == PublishRelayStatus.success ||
          state.status == PublishRelayStatus.failed ||
          state.attempts >= _maxAttemptsPerRelay,
    );
  }

  Duration _backoffForAttempt(int attempt) {
    final seconds = _baseBackoffSeconds * pow(2, max(0, attempt - 1));
    final delay = Duration(seconds: seconds.toInt());
    if (delay > _maxBackoff) return _maxBackoff;
    return delay;
  }

  Future<void> _persistQueue() async {
    try {
      Log.trace('PublishService: Persisting queue: ${_queue.length} item(s)');
      final prefs = await SharedPreferences.getInstance();
      final serialized = json.encode(_queue.values.map((item) => item.toJson()).toList());
      await prefs.setString(_storageKey, serialized);
      Log.trace('PublishService: Queue persisted successfully (${serialized.length} bytes)');
    } catch (e, stackTrace) {
      Log.error('Failed to persist publish queue', e);
      Log.debug('Persist queue stack', stackTrace);
    }
  }

  Future<void> _loadQueue() async {
    try {
      Log.trace('PublishService: Loading queue from storage');
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data == null || data.isEmpty) {
        Log.trace('PublishService: No queue data found in storage');
        _queue.clear();
        return;
      }

      Log.trace('PublishService: Found queue data (${data.length} bytes), decoding...');
      final decoded = json.decode(data) as List<dynamic>;
      Log.trace('PublishService: Decoded ${decoded.length} queue item(s)');
      for (final entry in decoded) {
        final item = PublishQueueItem.fromJson(entry as Map<String, dynamic>);
        _queue[item.id] = item;
        Log.trace(
          'PublishService: Loaded queue item ${item.id}: event=${item.event.id.substring(0, 8)}..., '
          'relays=${item.relays.length}, created=${item.createdAt.toIso8601String()}',
        );
      }
      Log.trace('PublishService: Queue loaded successfully: ${_queue.length} item(s)');
    } catch (e, stackTrace) {
      Log.error('Failed to load publish queue', e);
      Log.debug('Load queue stack', stackTrace);
      _queue.clear();
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
