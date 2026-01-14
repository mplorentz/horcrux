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

    await _persistQueue();
    _scheduleImmediateWork();

    return completer.future;
  }

  void onRelayReconnected(String relayUrl) {
    for (final entry in _queue.entries) {
      final item = entry.value;
      final state = item.relayStates[relayUrl];
      if (state == null || state.status == PublishRelayStatus.success) continue;
      final updatedRelayStates = Map<String, PublishRelayState>.from(item.relayStates);
      updatedRelayStates[relayUrl] = state.copyWith(
        nextAttemptAt: DateTime.now(),
      );
      _queue[entry.key] = item.copyWith(relayStates: updatedRelayStates);
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
    Future.microtask(_processQueue);
  }

  Future<void> _processQueue() async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;

    try {
      final now = DateTime.now();
      final completedIds = <String>[];

      final pendingItems = List<PublishQueueItem>.from(_queue.values);

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

        if (pendingRelays.isEmpty) {
          if (_isFinished(item)) {
            completedIds.add(item.id);
          }
          continue;
        }

        for (final relayEntry in pendingRelays) {
          final relayUrl = relayEntry.key;
          final outcome = await _broadcastToRelay(
            event: item.event,
            relayUrl: relayUrl,
          );

          _updateRelayState(
            itemId: item.id,
            relayUrl: relayUrl,
            success: outcome.success,
            error: outcome.message,
          );
        }

        if (_isFinished(_queue[item.id]!)) {
          completedIds.add(item.id);
        }
      }

      if (completedIds.isNotEmpty) {
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

          final result = PublishQueueResult(
            eventId: completedItem.event.id,
            successfulRelays: successfulRelays,
            failedRelays: failedRelays,
          );

          if (completer != null && !completer.isCompleted) {
            completer.complete(result);
          }
        }
      }
    } catch (e, stackTrace) {
      Log.error('Error processing publish queue', e);
      Log.debug('Publish queue processing stack', stackTrace);
    } finally {
      await _persistQueue();
      _isProcessing = false;
    }
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

  void _updateRelayState({
    required String itemId,
    required String relayUrl,
    required bool success,
    required String? error,
  }) {
    final item = _queue[itemId];
    if (item == null) {
      return;
    }

    final existing = item.relayStates[relayUrl] ??
        const PublishRelayState(
          status: PublishRelayStatus.pending,
          attempts: 0,
        );

    final updatedRelayStates = Map<String, PublishRelayState>.from(item.relayStates);

    if (success) {
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
      final prefs = await SharedPreferences.getInstance();
      final serialized = json.encode(_queue.values.map((item) => item.toJson()).toList());
      await prefs.setString(_storageKey, serialized);
    } catch (e, stackTrace) {
      Log.error('Failed to persist publish queue', e);
      Log.debug('Persist queue stack', stackTrace);
    }
  }

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data == null || data.isEmpty) {
        _queue.clear();
        return;
      }

      final decoded = json.decode(data) as List<dynamic>;
      for (final entry in decoded) {
        final item = PublishQueueItem.fromJson(entry as Map<String, dynamic>);
        _queue[item.id] = item;
      }
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
