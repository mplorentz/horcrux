import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/kv.dart';
import '../tables/synced_consents.dart';
import '../tables/viewed_notifications.dart';

part 'app_state_dao.g.dart';

@DriftAccessor(tables: [Kv, ViewedNotifications, SyncedConsents])
class AppStateDao extends DatabaseAccessor<AppDatabase> with _$AppStateDaoMixin {
  AppStateDao(super.db);

  Future<String?> getString(String key) async {
    final row = await (select(kv)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setString({
    required String key,
    required String value,
  }) {
    return into(kv).insertOnConflictUpdate(
      KvCompanion.insert(
        key: key,
        value: value,
      ),
    );
  }

  Future<void> removeKey(String key) async {
    await (delete(kv)..where((t) => t.key.equals(key))).go();
  }

  Future<int?> getInt(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> setInt({
    required String key,
    required int value,
  }) {
    return setString(key: key, value: value.toString());
  }

  Future<bool?> getBool(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return null;
  }

  Future<void> setBool({
    required String key,
    required bool value,
  }) {
    return setString(key: key, value: value.toString());
  }

  Future<List<String>> viewedNotificationIds() async {
    final rows = await (select(viewedNotifications)
          ..orderBy([(t) => OrderingTerm.asc(t.notificationId)]))
        .get();
    return rows.map((r) => r.notificationId).toList();
  }

  Future<void> replaceViewedNotificationIds(Iterable<String> ids) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      await delete(viewedNotifications).go();
      final filtered = ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
      if (filtered.isEmpty) return;
      await batch((b) {
        b.insertAll(
          viewedNotifications,
          filtered
              .map(
                (id) => ViewedNotificationsCompanion.insert(
                  notificationId: id,
                  viewedAt: now,
                ),
              )
              .toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<void> clearViewedNotificationIds() async {
    await delete(viewedNotifications).go();
  }

  Future<List<String>> syncedConsentIds() async {
    final rows =
        await (select(syncedConsents)..orderBy([(t) => OrderingTerm.asc(t.consentId)])).get();
    return rows.map((r) => r.consentId).toList();
  }

  Future<void> replaceSyncedConsentIds(Iterable<String> consentIds) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      await delete(syncedConsents).go();
      final filtered =
          consentIds.map((id) => id.trim().toLowerCase()).where((id) => id.isNotEmpty).toSet();
      if (filtered.isEmpty) return;
      await batch((b) {
        b.insertAll(
          syncedConsents,
          filtered
              .map(
                (id) => SyncedConsentsCompanion.insert(
                  consentId: id,
                  payload: id,
                  syncedAt: now,
                ),
              )
              .toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }
}
