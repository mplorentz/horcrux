import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ndk/ndk.dart';

/// A minimal fake Nostr relay on localhost (random port) for testing.
///
/// Supports REQ/CLOSE/EVENT protocol for testing subscription delivery.
/// Does NOT sign events — pre-built events are forwarded as-is.
///
/// NDK expects the relay to send EVENT messages in the format:
///   ["EVENT", <subscription_id>, <event_json>]
///
/// This relay tracks active subscriptions by their NDK-assigned IDs.
class FakeNostrRelay {
  HttpServer? _server;
  WebSocket? _webSocket;
  int? _port;

  /// Active subscriptions keyed by subscription ID → filters.
  final Map<String, List<Filter>> _activeSubscriptions = {};

  /// Completer that resolves once the first WebSocket handshake is complete.
  final _connectedCompleter = Completer<void>();

  /// URL of this relay (e.g. "ws://localhost:12345").
  String get url => 'ws://localhost:$_port';

  /// Whether a client has connected.
  bool get isConnected => _connectedCompleter.isCompleted;

  /// Future that completes when a WebSocket client connects.
  Future<void> get connected => _connectedCompleter.future;

  /// Sends an EVENT message to the connected client with [event].
  /// If an active subscription has matching filters (kind and pTags),
  /// the event is delivered with that subscription's ID.
  /// Otherwise, it is sent with the first active subscription's ID.
  void sendEvent(Nip01Event event) {
    if (_webSocket == null) return;

    // Find the first subscription whose filters match the event.
    final match = _activeSubscriptions.entries.cast<MapEntry<String, List<Filter>>>().toList();
    String? subId;

    for (final entry in match) {
      if (_matchesAnyFilter(event, entry.value)) {
        subId = entry.key;
        break;
      }
    }

    // Fall back to the first available subscription if no filter match.
    subId ??= _activeSubscriptions.keys.firstOrNull;

    if (subId != null) {
      _webSocket!.add(jsonEncode(['EVENT', subId, Nip01EventModel.fromEntity(event).toJson()]));
    }
  }

  /// Whether [event] matches any of [filters] (kind match + pTag match).
  bool _matchesAnyFilter(Nip01Event event, List<Filter> filters) {
    for (final filter in filters) {
      if (filter.kinds != null && filter.kinds!.isNotEmpty) {
        if (!filter.kinds!.contains(event.kind)) continue;
      }
      if (filter.pTags != null && filter.pTags!.isNotEmpty) {
        final eventPTags = _getPTags(event);
        if (!eventPTags.any((t) => filter.pTags!.contains(t))) continue;
      }
      return true;
    }
    return false;
  }

  List<String> _getPTags(Nip01Event event) {
    return event.tags.where((t) => t.length >= 2 && t[0] == 'p').map((t) => t[1]).toList();
  }

  /// Start the WebSocket server on a random port.
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: true);
    _port = _server!.port;

    _server!.transform(WebSocketTransformer()).listen((webSocket) {
      _webSocket = webSocket;
      if (!_connectedCompleter.isCompleted) {
        _connectedCompleter.complete();
      }

      webSocket.listen((message) {
        if (message is! String) return;
        final data = json.decode(message);
        if (data is! List) return;
        if (data.isEmpty) return;

        final command = data[0] as String;
        switch (command) {
          case 'REQ':
            _handleReq(data);
          case 'CLOSE':
            _handleClose(data);
        }
      }, onDone: () {
        _webSocket = null;
        _activeSubscriptions.clear();
      }, onError: (Object e) {
        _webSocket = null;
        _activeSubscriptions.clear();
      });
    });
  }

  void _handleReq(List<dynamic> data) {
    final subId = data[1] as String;
    final filters = <Filter>[];
    for (var i = 2; i < data.length; i++) {
      if (data[i] is Map<String, dynamic>) {
        filters.add(Filter.fromMap(data[i] as Map<String, dynamic>));
      }
    }
    if (filters.isNotEmpty) {
      _activeSubscriptions[subId] = filters;
    }
    // Send EOSE immediately (required by NDK)
    _webSocket?.add(jsonEncode(['EOSE', subId]));
  }

  void _handleClose(List<dynamic> data) {
    final subId = data[1] as String;
    _activeSubscriptions.remove(subId);
  }

  /// Stop the server.
  Future<void> stop() async {
    _webSocket?.close();
    await _server?.close(force: true);
    _server = null;
    _webSocket = null;
    _activeSubscriptions.clear();
  }
}

/// Creates a minimal kind-1059 gift wrap event addressed to [recipientPubkey].
///
/// The event is NOT cryptographically valid — it has an empty sig. This is
/// sufficient for testing subscription delivery and claim/store logic.
/// NDK's Bip340EventVerifier will reject invalid sigs, so tests using this
/// helper must use a mock event verifier or work around verification.
Nip01Event makeGiftWrapEvent({
  required String recipientPubkey,
  required String id,
  int createdAt = 0,
}) {
  return Nip01Event(
    id: id,
    pubKey: 'a' * 64,
    kind: 1059,
    tags: [
      ['p', recipientPubkey],
    ],
    content: '{"kind":1,"content":"test"}',
    createdAt: createdAt,
  );
}
