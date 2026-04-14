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

/// Persists the last [maxIds] successfully processed Nostr event IDs (FIFO eviction).
///
/// Uses a **snapshot** file plus an **append-only log** of IDs since the last snapshot.
/// On app background, [mergePersistedStateOnBackground] rewrites the snapshot and clears
/// the log so normal operation only appends small writes.
///
/// IDs are recorded only after handling completes without error so relays may replay
/// events without reprocessing work; combined with [RecoveryService] first-open policy,
/// new devices do not get notification spam for historical events.
class ProcessedNostrEventStore {
  ProcessedNostrEventStore({this.maxIds = 99999});

  static const _snapshotName = 'processed_nostr_event_ids.snapshot';
  static const _logName = 'processed_nostr_event_ids.log';

  final int maxIds;

  /// Insertion order = FIFO (oldest → newest).
  final LinkedHashSet<String> _ids = LinkedHashSet<String>();

  Directory? _dir;
  File? _snapshotFile;
  File? _logFile;

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

      await _removeStaleSnapshotTemp(dir);

      _ids.clear();
      await _readSnapshotIntoMemory();
      await _replayLogIntoMemory();

      _trimToMaxIds();
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

  /// Call after an event has been fully handled (vault updated or idempotent skip).
  Future<void> recordProcessed(String id) async {
    await _serialized(() async {
      await ensureLoaded();
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

  /// Rewrites the snapshot from memory and truncates the append log. Call when the app
  /// goes to background so the log stays small and restarts stay fast.
  Future<void> mergePersistedStateOnBackground() async {
    await _serialized(() async {
      await ensureLoaded();
      final log = _logFile;
      if (log == null) return;

      try {
        await _writeSnapshotFromMemory();
        if (await log.exists()) {
          await log.delete();
        }
        await log.create();
      } catch (e, st) {
        Log.error('ProcessedNostrEventStore merge (snapshot) failed', e, st);
      }
    });
  }
}
