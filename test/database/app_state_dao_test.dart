import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/app_database.dart';

import '../helpers/test_database.dart';

void main() {
  group('AppStateDao', () {
    late AppDatabase db;

    setUp(() {
      db = newTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('stores and reads string/int/bool kv values', () async {
      await db.appStateDao.setString(key: 'k_string', value: 'abc');
      await db.appStateDao.setInt(key: 'k_int', value: 123);
      await db.appStateDao.setBool(key: 'k_bool', value: true);

      expect(await db.appStateDao.getString('k_string'), 'abc');
      expect(await db.appStateDao.getInt('k_int'), 123);
      expect(await db.appStateDao.getBool('k_bool'), isTrue);

      await db.appStateDao.removeKey('k_string');
      expect(await db.appStateDao.getString('k_string'), isNull);
    });

    test('replaces viewed notification ids atomically', () async {
      await db.appStateDao.replaceViewedNotificationIds({'req-1', 'req-2'});
      expect(await db.appStateDao.viewedNotificationIds(), ['req-1', 'req-2']);

      await db.appStateDao.replaceViewedNotificationIds({'req-3'});
      expect(await db.appStateDao.viewedNotificationIds(), ['req-3']);

      await db.appStateDao.clearViewedNotificationIds();
      expect(await db.appStateDao.viewedNotificationIds(), isEmpty);
    });

    test('replaces synced consent ids atomically', () async {
      await db.appStateDao.replaceSyncedConsentIds(['b', 'a', 'b']);
      expect(await db.appStateDao.syncedConsentIds(), ['a', 'b']);

      await db.appStateDao.replaceSyncedConsentIds({'c'});
      expect(await db.appStateDao.syncedConsentIds(), ['c']);

      await db.appStateDao.replaceSyncedConsentIds({});
      expect(await db.appStateDao.syncedConsentIds(), isEmpty);
    });
  });
}
