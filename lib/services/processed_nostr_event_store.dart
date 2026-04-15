import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'logger.dart';

final processedNostrEventStoreProvider = Provider<ProcessedNostrEventStore>((ref) {
  return ProcessedNostrEventStore();
});

/// Normalizes relay URLs so cursor map keys stay stable across trivial spelling differences.
String normalizeRelayUrlForNostrEventCursor(String relayUrl) {
  final t = relayUrl.trim();
  if (t.isEmpty) return t;
  final uri = Uri.tryParse(t);
  if (uri == null || uri.host.isEmpty) {
    return t.toLowerCase();
  }
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final port = uri.hasPort ? ':${uri.port}' : '';
  var path = uri.path;
  if (path == '/') path = '';
  return '$scheme://$host$port$path';
}

/// Persists the last [maxIds] successfully processed Nostr event IDs (FIFO eviction).
///
/// Uses a **snapshot** file plus an **append-only log** of IDs since the last snapshot.
/// On app background, [mergePersistedStateOnBackground] rewrites the snapshot and clears
/// the log so normal operation only appends small writes.
///
/// Also keeps the date of the most recent event from each relay so we can avoid fetching duplicate
/// events.
///
/// [claimEvent] / [releaseClaimedEvent] implement an in-memory **claim** so
/// the same outer id is not unwrapped concurrently from two relays (not persisted).
///
/// IDs are recorded only after handling completes without error so relays may replay
/// events without reprocessing work; combined with [RecoveryService] first-open policy,
/// new devices do not get notification spam for historical events.
class ProcessedNostrEventStore {
  ProcessedNostrEventStore({this.maxIds = 99999});

  static const _snapshotName = 'processed_nostr_event_ids.snapshot';
  static const _logName = 'processed_nostr_event_ids.log';
  static const _cursorsFileName = 'nostr_relay_subscription_cursors.json';

  final int maxIds;

  /// Insertion order = FIFO (oldest → newest).
  final LinkedHashSet<String> _ids = LinkedHashSet<String>();

  /// In-flight outer event IDs (subscription path). Not persisted; cleared on process exit.
  final LinkedHashSet<String> _claimedIds = LinkedHashSet<String>();

  /// Keys: [normalizeRelayUrlForNostrEventCursor]; values: max event `created_at` (unix sec).
  final Map<String, int> _relayMaxSeenEventCreatedAtSec = {};

  Directory? _dir;
  File? _snapshotFile;
  File? _logFile;
  File? _cursorsFile;

  bool _loaded = false;
  Future<void>? _loadFuture;

  /// Serializes snapshot writes, log appends, and merge so concurrent calls do not corrupt files.
  Future<void> _chain = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() fn) async {
    final completer = Completer<void>();
    final previous = _chain;
    _chain = completer.future;
    await previous;
    try {
      return await fn();
    } finally {
      completer.complete();
    }
  }

  Future<void> ensureLoaded() async {
    _loadFuture ??= _load();
    await _loadFuture;
  }

  Future<void> _load() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _dir = dir;
      _snapshotFile = File(p.join(dir.path, _snapshotName));
      _logFile = File(p.join(dir.path, _logName));
      _cursorsFile = File(p.join(dir.path, _cursorsFileName));

      await _removeStaleSnapshotTemp(dir);
      await _removeStaleCursorsTemp(dir);

      _ids.clear();
      await _readSnapshotIntoMemory();
      await _replayLogIntoMemory();

      _trimToMaxIds();

      await _readCursorsFromJson();
    } catch (e, st) {
      Log.error('ProcessedNostrEventStore load failed', e, st);
    } finally {
      _loaded = true;
    }
  }

  Future<void> _removeStaleSnapshotTemp(Directory dir) async {
    final tmp = File(p.join(dir.path, '$_snapshotName.tmp'));
    if (tmp.existsSync()) {
      try {
        await tmp.delete();
      } catch (e) {
        Log.warning('ProcessedNostrEventStore: could not delete stale snapshot tmp: $e');
      }
    }
  }

  Future<void> _removeStaleCursorsTemp(Directory dir) async {
    final tmp = File(p.join(dir.path, '$_cursorsFileName.tmp'));
    if (tmp.existsSync()) {
      try {
        await tmp.delete();
      } catch (e) {
        Log.warning('ProcessedNostrEventStore: could not delete stale cursors tmp: $e');
      }
    }
  }

  Future<void> _readCursorsFromJson() async {
    final file = _cursorsFile;
    if (file == null || !await file.exists()) return;
    try {
      final text = await file.readAsString();
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return;
      final relays = decoded['relays'];
      if (relays is! Map) return;
      _relayMaxSeenEventCreatedAtSec.clear();
      for (final e in relays.entries) {
        final k = e.key;
        final v = e.value;
        if (k is! String || v is! num) continue;
        _relayMaxSeenEventCreatedAtSec[k] = v.toInt();
      }
    } catch (e, st) {
      Log.error('ProcessedNostrEventStore cursors load failed', e, st);
    }
  }

  Future<void> _writeCursorsJson() async {
    final file = _cursorsFile;
    final dir = _dir;
    if (file == null || dir == null) return;
    final tmp = File(p.join(dir.path, '$_cursorsFileName.tmp'));
    try {
      final payload = jsonEncode({'relays': _relayMaxSeenEventCreatedAtSec});
      await tmp.writeAsString(payload, flush: true);
      await tmp.rename(file.path);
    } catch (e, st) {
      Log.error('ProcessedNostrEventStore cursors write failed', e, st);
    }
  }

  Future<void> _readSnapshotIntoMemory() async {
    final file = _snapshotFile;
    if (file == null || !await file.exists()) return;

    await for (final line
        in file.openRead().transform(utf8.decoder).transform(const LineSplitter())) {
      final id = line.trim();
      if (id.isNotEmpty) {
        _ingestId(id);
      }
    }
    _trimToMaxIds();
  }

  Future<void> _replayLogIntoMemory() async {
    final file = _logFile;
    if (file == null || !await file.exists()) return;

    await for (final line
        in file.openRead().transform(utf8.decoder).transform(const LineSplitter())) {
      final id = line.trim();
      if (id.isNotEmpty) {
        _ingestId(id);
      }
    }
    _trimToMaxIds();
  }

  void _ingestId(String id) {
    if (_ids.contains(id)) return;
    _ids.add(id);
    _trimToMaxIds();
  }

  void _trimToMaxIds() {
    while (_ids.length > maxIds) {
      _ids.remove(_ids.first);
    }
  }

  Future<void> _writeSnapshotFromMemory() async {
    final dir = _dir;
    final snapshot = _snapshotFile;
    if (dir == null || snapshot == null) return;

    final tmp = File(p.join(dir.path, '$_snapshotName.tmp'));
    final sink = tmp.openWrite();
    try {
      for (final id in _ids) {
        sink.writeln(id);
      }
    } finally {
      await sink.close();
    }

    // Atomic replace on POSIX; Dart removes an existing [snapshot] first when needed.
    await tmp.rename(snapshot.path);
  }

  Future<bool> contains(String id) async {
    await ensureLoaded();
    return _ids.contains(id);
  }

  /// Returns true if this [id] can start handling: not yet processed and not already claimed.
  ///
  /// Call [releaseClaimedEvent] on failure before [recordProcessed]; [recordProcessed] clears
  /// the claim on success.
  Future<bool> claimEvent(String id) async {
    if (id.isEmpty) return false;
    return _serialized(() async {
      await ensureLoaded();
      if (_ids.contains(id)) return false;
      if (_claimedIds.contains(id)) return false;
      _claimedIds.add(id);
      return true;
    });
  }

  /// Drops an in-memory claim so another attempt can process this [id] (e.g. after error).
  Future<void> releaseClaimedEvent(String id) async {
    if (id.isEmpty) return;
    await _serialized(() async {
      await ensureLoaded();
      _claimedIds.remove(id);
    });
  }

  /// Call after an event has been fully handled (vault updated or idempotent skip).
  Future<void> recordProcessed(String id) async {
    await _serialized(() async {
      await ensureLoaded();
      _claimedIds.remove(id);
      if (_ids.contains(id)) return;

      _ingestId(id);

      final log = _logFile;
      if (log == null) return;
      try {
        if (!await log.exists()) {
          await log.create();
        }
        await log.writeAsString('$id\n', mode: FileMode.append, flush: true);
      } catch (e, st) {
        Log.error('ProcessedNostrEventStore log append failed', e, st);
      }
    });
  }

  /// Latest recorded outer `created_at` (unix seconds) for subscription events from [relayUrl].
  Future<int?> getLastSeen(String relayUrl) async {
    await ensureLoaded();
    final key = normalizeRelayUrlForNostrEventCursor(relayUrl);
    if (key.isEmpty) return null;
    return _relayMaxSeenEventCreatedAtSec[key];
  }

  /// Updates the per-relay cursor if [createdAtUnix] is newer (in-memory until background merge).
  Future<void> recordLastSeen(
    String relayUrl,
    int createdAtUnix,
  ) async {
    await _serialized(() async {
      await ensureLoaded();
      final key = normalizeRelayUrlForNostrEventCursor(relayUrl);
      if (key.isEmpty) return;
      final existing = _relayMaxSeenEventCreatedAtSec[key] ?? 0;
      if (createdAtUnix <= existing) return;
      _relayMaxSeenEventCreatedAtSec[key] = createdAtUnix;
    });
  }

  /// Rewrites the snapshot from memory and truncates the append log. Call when the app
  /// goes to background so the log stays small and restarts stay fast.
  ///
  /// Also persists relay subscription cursors to JSON.
  Future<void> mergePersistedStateOnBackground() async {
    await _serialized(() async {
      await ensureLoaded();
      try {
        final log = _logFile;
        final snapshot = _snapshotFile;
        if (snapshot != null && log != null) {
          await _writeSnapshotFromMemory();
          if (await log.exists()) {
            await log.delete();
          }
          await log.create();
        }
        await _writeCursorsJson();
      } catch (e, st) {
        Log.error('ProcessedNostrEventStore merge (snapshot/cursors) failed', e, st);
      }
    });
  }
}
