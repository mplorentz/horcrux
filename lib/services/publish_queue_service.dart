import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'logger.dart';

typedef NdkSupplier = Future<Ndk> Function();
typedef PubkeySupplier = Future<String?> Function();

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
      nextAttemptAt: json['nextAttemptAt'] != null
          ? DateTime.tryParse(json['nextAttemptAt'] as String)
          : null,
      lastError: json['lastError'] as String?,
    );
  }
}

class PublishQueueItem {
  final String id;
  final String content;
  final int kind;
  final String recipientPubkey;
  final List<String> relays;
  final List<List<String>> tags;
  final String? customPubkey;
  final DateTime createdAt;
  final Map<String, PublishRelayState> relayStates;
  final String? eventId;

  const PublishQueueItem({
    required this.id,
    required this.content,
    required this.kind,
    required this.recipientPubkey,
    required this.relays,
    required this.tags,
    required this.createdAt,
    required this.relayStates,
    this.customPubkey,
    this.eventId,
  });

  PublishQueueItem copyWith({
    String? eventId,
    Map<String, PublishRelayState>? relayStates,
  }) {
    return PublishQueueItem(
      id: id,
      content: content,
      kind: kind,
      recipientPubkey: recipientPubkey,
      relays: relays,
      tags: tags,
      createdAt: createdAt,
      relayStates: relayStates ?? this.relayStates,
      customPubkey: customPubkey,
      eventId: eventId ?? this.eventId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'kind': kind,
      'recipientPubkey': recipientPubkey,
      'relays': relays,
      'tags': tags,
      'customPubkey': customPubkey,
      'createdAt': createdAt.toIso8601String(),
      'relayStates': relayStates.map((key, value) => MapEntry(key, value.toJson())),
      'eventId': eventId,
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

    return PublishQueueItem(
      id: json['id'] as String,
      content: json['content'] as String,
      kind: json['kind'] as int,
      recipientPubkey: json['recipientPubkey'] as String,
      relays: (json['relays'] as List<dynamic>? ?? []).cast<String>(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map(
            (tag) => (tag as List<dynamic>).map((item) => item.toString()).toList(),
          )
          .toList(),
      customPubkey: json['customPubkey'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      relayStates: relayStates,
      eventId: json['eventId'] as String?,
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

class PublishQueueService {
  PublishQueueService({
    required NdkSupplier getNdk,
    required PubkeySupplier getSenderPubkey,
  })  : _getNdk = getNdk,
        _getSenderPubkey = getSenderPubkey;

  static const _storageKey = 'publish_queue_items_v1';
  static const _uuid = Uuid();
  static const _maxAttemptsPerRelay = 6;
  static const _baseBackoffSeconds = 2;
  static const _maxBackoff = Duration(minutes: 5);

  final NdkSupplier _getNdk;
  final PubkeySupplier _getSenderPubkey;

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
    Log.info('PublishQueueService initialized with ${_queue.length} pending item(s)');
  }

  Future<PublishQueueResult> enqueueEncryptedEvent({
    required String content,
    required int kind,
    required String recipientPubkey,
    required List<String> relays,
    List<List<String>>? tags,
    String? customPubkey,
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
      id: _uuid.v4(),
      content: content,
      kind: kind,
      recipientPubkey: recipientPubkey,
      relays: dedupedRelays,
      tags: tags ?? [],
      createdAt: DateTime.now(),
      relayStates: relayStates,
      customPubkey: customPubkey,
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
      final state = entry.value.relayStates[relayUrl];
      if (state == null || state.status == PublishRelayStatus.success) continue;
      entry.value.relayStates[relayUrl] = state.copyWith(
        nextAttemptAt: DateTime.now(),
      );
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
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final now = DateTime.now();
      final completedIds = <String>[];

      final pendingItems = List<PublishQueueItem>.from(_queue.values);

      for (final item in pendingItems) {
        final pendingRelays = item.relayStates.entries.where(
          (entry) {
            final state = entry.value;
            if (state.status == PublishRelayStatus.success) return false;
            if (state.status == PublishRelayStatus.failed) return false;
            if (state.attempts >= _maxAttemptsPerRelay) return false;
            if (state.nextAttemptAt != null && state.nextAttemptAt!.isAfter(now)) {
              return false;
            }
            return true;
          },
        ).toList();

        if (pendingRelays.isEmpty) {
          if (_isFinished(item)) {
            completedIds.add(item.id);
          }
          continue;
        }

        Nip01Event? giftWrap;
        try {
          giftWrap = await _buildGiftWrap(item);
          if (item.eventId != giftWrap.id) {
            _queue[item.id] = item.copyWith(eventId: giftWrap.id);
          }
        } catch (e, stackTrace) {
          Log.error('Failed to build gift wrap for queue item ${item.id}', e);
          Log.debug('Gift wrap build stack', stackTrace);
          for (final relayEntry in pendingRelays) {
            _updateRelayState(
              itemId: item.id,
              relayUrl: relayEntry.key,
              success: false,
              error: 'Failed to prepare event: $e',
            );
          }
          continue;
        }

        for (final relayEntry in pendingRelays) {
          final relayUrl = relayEntry.key;
          final outcome = await _broadcastToRelay(
            event: giftWrap!,
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
            eventId: completedItem.eventId,
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

  Future<Nip01Event> _buildGiftWrap(PublishQueueItem item) async {
    final ndk = await _getNdk();

    final senderPubkey = item.customPubkey ?? await _getSenderPubkey();
    if (senderPubkey == null) {
      throw Exception('No sender pubkey available for publish queue item ${item.id}');
    }

    final tags = _ensureExpirationTag(item.tags);
    final rumor = await ndk.giftWrap.createRumor(
      customPubkey: senderPubkey,
      content: item.content,
      kind: item.kind,
      tags: tags,
    );

    return ndk.giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: item.recipientPubkey,
    );
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
      final relayResult = results.firstWhere(
        (result) => result.relayUrl == relayUrl,
        orElse: () => results.isNotEmpty ? results.first : null,
      );

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
    if (item == null) return;

    final existing = item.relayStates[relayUrl] ??
        const PublishRelayState(
          status: PublishRelayStatus.pending,
          attempts: 0,
        );

    if (success) {
      item.relayStates[relayUrl] = existing.copyWith(
        status: PublishRelayStatus.success,
        attempts: existing.attempts + 1,
        nextAttemptAt: null,
        lastError: null,
      );
      return;
    }

    final attempts = existing.attempts + 1;
    final nextAttempt = attempts >= _maxAttemptsPerRelay
        ? null
        : DateTime.now().add(_backoffForAttempt(attempts));

    item.relayStates[relayUrl] = existing.copyWith(
      status: attempts >= _maxAttemptsPerRelay ? PublishRelayStatus.failed : PublishRelayStatus.pending,
      attempts: attempts,
      nextAttemptAt: nextAttempt,
      lastError: error,
    );
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

  List<List<String>> _ensureExpirationTag(List<List<String>> tags) {
    final hasExpiration = tags.any(
      (tag) => tag.isNotEmpty && tag.first == 'expiration',
    );

    if (hasExpiration) return tags;

    final expirationTimestamp =
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;

    return [
      ['expiration', expirationTimestamp.toString()],
      ...tags,
    ];
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
