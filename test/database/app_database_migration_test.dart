import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Verifies [AppDatabase] migration from schema v1 files that predate the
/// Phase 2a `held_shares` table (same `user_version`, expanded drift schema).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('upgrade from v1 without held_shares reaches schema v5', () async {
    final raw = sqlite.sqlite3.openInMemory();
    raw.execute('PRAGMA foreign_keys = ON');

    for (final statement in _legacyV1Ddl) {
      raw.execute(statement);
    }
    raw.execute('PRAGMA user_version = 1');

    final db = AppDatabase(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    final held = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'held_shares'",
        )
        .get();
    expect(held, isNotEmpty);

    final versionRow = raw.select('PRAGMA user_version');
    expect(versionRow.first.columnAt(0), 5);

    final phase3 = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'outbox'",
        )
        .get();
    expect(phase3, isNotEmpty);

    await db.close();
  });

  test('upgrade from v1 with held_shares already present reaches schema v5', () async {
    final raw = sqlite.sqlite3.openInMemory();
    raw.execute('PRAGMA foreign_keys = ON');

    for (final statement in _legacyV1Ddl) {
      raw.execute(statement);
    }
    raw.execute(_legacyV1HeldSharesDdl);
    raw.execute('PRAGMA user_version = 1');

    final db = AppDatabase(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    final held = await db
        .customSelect(
          "SELECT COUNT(*) AS c FROM held_shares",
        )
        .get();
    expect(held.first.data['c'], 0);

    final versionRow = raw.select('PRAGMA user_version');
    expect(versionRow.first.columnAt(0), 5);

    await db.close();
  });

  test('upgrade from v2 snapshot adds Phase 3 tables', () async {
    final raw = sqlite.sqlite3.openInMemory();
    raw.execute('PRAGMA foreign_keys = ON');

    for (final statement in _legacyV1Ddl) {
      raw.execute(statement);
    }
    raw.execute(_legacyV1HeldSharesDdl);
    raw.execute('PRAGMA user_version = 2');

    final db = AppDatabase(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    final invitations = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'invitations'",
        )
        .get();
    expect(invitations, isNotEmpty);

    final versionRow = raw.select('PRAGMA user_version');
    expect(versionRow.first.columnAt(0), 5);

    await db.close();
  });

  test('upgrade from v4 snapshot adds app-state tables', () async {
    final raw = sqlite.sqlite3.openInMemory();
    raw.execute('PRAGMA foreign_keys = ON');

    for (final statement in _legacyV1Ddl) {
      raw.execute(statement);
    }
    raw.execute(_legacyV1HeldSharesDdl);
    raw.execute(_legacyV4InvitationsTableDdl);
    raw.execute(_legacyV3RecoveryRequestsDdl);
    raw.execute(_legacyV3RecoveryRequestParticipantsDdl);
    raw.execute(_legacyV3RecoveryResponsesDdl);
    raw.execute(_legacyV3OutboxDdl);
    raw.execute(_legacyV3OutboxRelaysDdl);
    raw.execute('PRAGMA user_version = 4');

    final db = AppDatabase(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();

    final kvTable = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'kv'",
        )
        .get();
    expect(kvTable, isNotEmpty);

    final viewedTable = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'viewed_notifications'",
        )
        .get();
    expect(viewedTable, isNotEmpty);

    final consentsTable = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'synced_consents'",
        )
        .get();
    expect(consentsTable, isNotEmpty);

    final versionRow = raw.select('PRAGMA user_version');
    expect(versionRow.first.columnAt(0), 5);

    await db.close();
  });

  test('migrates legacy SharedPreferences app-state into Drift', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'push_notifications_opted_in': true,
      'fcm_device_token': 'legacy-token',
      'fcm_device_token_updated_at': '2026-05-11T21:59:00.000Z',
      'horcrux_notifier_base_url': 'https://legacy-notifier.example.com',
      'relay_configurations': '[{"id":"relay-1","url":"wss://relay.example.com"}]',
      'scanning_status': '{"isActive":true}',
      'horcrux_first_open_utc_ms': 1715000000000,
      'viewed_recovery_notification_ids': '["req-b","req-a","req-b"]',
      'horcrux_notifier_last_synced_consents': <String>[
        'B',
        'a',
        'B',
      ],
    });

    final raw = sqlite.sqlite3.openInMemory();
    raw.execute('PRAGMA foreign_keys = ON');

    for (final statement in _legacyV1Ddl) {
      raw.execute(statement);
    }
    raw.execute(_legacyV1HeldSharesDdl);
    raw.execute(_legacyV4InvitationsTableDdl);
    raw.execute(_legacyV3RecoveryRequestsDdl);
    raw.execute(_legacyV3RecoveryRequestParticipantsDdl);
    raw.execute(_legacyV3RecoveryResponsesDdl);
    raw.execute(_legacyV3OutboxDdl);
    raw.execute(_legacyV3OutboxRelaysDdl);
    raw.execute('PRAGMA user_version = 4');

    final db = AppDatabase(NativeDatabase.opened(raw));
    await db.customSelect('SELECT 1').get();
    await db.migrateLegacySharedPreferencesAppStateIfNeeded();

    expect(
      await db.appStateDao.getBool('push_notifications_opted_in'),
      isTrue,
    );
    expect(await db.appStateDao.getString('fcm_device_token'), 'legacy-token');
    expect(
      await db.appStateDao.getString('fcm_device_token_updated_at'),
      '2026-05-11T21:59:00.000Z',
    );
    expect(
      await db.appStateDao.getString('horcrux_notifier_base_url'),
      'https://legacy-notifier.example.com',
    );
    expect(
      await db.appStateDao.getString('relay_configurations'),
      '[{"id":"relay-1","url":"wss://relay.example.com"}]',
    );
    expect(await db.appStateDao.getString('scanning_status'), '{"isActive":true}');
    expect(await db.appStateDao.getInt('horcrux_first_open_utc_ms'), 1715000000000);

    expect(
      await db.appStateDao.viewedNotificationIds(),
      <String>['req-a', 'req-b'],
    );
    expect(await db.appStateDao.syncedConsentIds(), <String>['a', 'b']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('push_notifications_opted_in'), isFalse);
    expect(prefs.containsKey('viewed_recovery_notification_ids'), isFalse);
    expect(prefs.containsKey('horcrux_notifier_last_synced_consents'), isFalse);

    await db.close();
  });
}

/// DDL matching drift's onCreate `createAll()` for Phase 1 tables only (no
/// `held_shares`). Order respects foreign keys.
const _legacyV1Ddl = <String>[
  '''
CREATE TABLE "vaults" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "owner_pubkey" TEXT NOT NULL, "owner_name" TEXT NULL, "threshold" INTEGER NOT NULL, "prime_mod" TEXT NULL, "total_shares" INTEGER NOT NULL, "current_distribution_version" INTEGER NOT NULL DEFAULT 0, "instructions" TEXT NULL, "push_enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("push_enabled" IN (0, 1)), "archived_at" INTEGER NULL, "archived_reason" TEXT NULL, "last_synced_at" INTEGER NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"))
''',
  '''
CREATE TABLE "vault_relays" ("id" TEXT NOT NULL, "vault_id" TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE, "url" TEXT NOT NULL, "role" TEXT NOT NULL, "added_at" INTEGER NOT NULL, PRIMARY KEY ("id"))
''',
  '''
CREATE TABLE "owned_vaults" ("vault_id" TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE, "content" TEXT NOT NULL, "content_hmac" BLOB NOT NULL, "created_by_self_at" INTEGER NOT NULL, PRIMARY KEY ("vault_id"))
''',
  '''
CREATE TABLE "stewards" ("id" TEXT NOT NULL, "vault_id" TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE, "share_index" INTEGER NOT NULL, "pubkey" TEXT NULL, "name" TEXT NULL, "contact_info" TEXT NULL, "is_owner" INTEGER NOT NULL DEFAULT 0 CHECK ("is_owner" IN (0, 1)), "joined_at" INTEGER NOT NULL, "left_at" INTEGER NULL, "removal_reason" TEXT NULL, PRIMARY KEY ("id"))
''',
  '''
CREATE TABLE "distributions" ("id" TEXT NOT NULL, "vault_id" TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE, "version" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, "completed_at" INTEGER NULL, "content_hmac" BLOB NOT NULL, PRIMARY KEY ("id"))
''',
  '''
CREATE TABLE "distribution_shares" ("id" TEXT NOT NULL, "distribution_id" TEXT NOT NULL REFERENCES distributions (id) ON DELETE CASCADE, "steward_id" TEXT NOT NULL REFERENCES stewards (id) ON DELETE RESTRICT, "gift_wrap_event_id" TEXT NOT NULL, "sent_at" INTEGER NULL, "acknowledged_at" INTEGER NULL, "acknowledgment_event_id" TEXT NULL, "acknowledgment_distribution_version" INTEGER NULL, "acknowledgment_created_at" INTEGER NULL, PRIMARY KEY ("id"))
''',
];

const _legacyV1HeldSharesDdl = '''
CREATE TABLE "held_shares" ("id" TEXT NOT NULL, "vault_id" TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE, "share_index" INTEGER NOT NULL, "share_payload" TEXT NOT NULL, "distribution_version" INTEGER NOT NULL, "received_at" INTEGER NOT NULL, "nostr_event_id" TEXT NULL, "last_seen_relay" TEXT NULL, "push_enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("push_enabled" IN (0, 1)), PRIMARY KEY ("id"))
''';

const _legacyV3RecoveryRequestsDdl = '''
CREATE TABLE "recovery_requests" ("id" TEXT NOT NULL, "vault_id" TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE, "request_event_id" TEXT NULL, "initiator_pubkey" TEXT NOT NULL, "started_at" INTEGER NOT NULL, "expires_at" INTEGER NULL, "cancelled_at" INTEGER NULL, "completed_at" INTEGER NULL, "distribution_version_at_start" INTEGER NOT NULL, "threshold_at_start" INTEGER NOT NULL, "status" TEXT NOT NULL, "is_practice" INTEGER NOT NULL DEFAULT 0 CHECK ("is_practice" IN (0, 1)), "error_message" TEXT NULL, "event_creation_time_ms" INTEGER NULL, PRIMARY KEY ("id"))
''';

const _legacyV3RecoveryRequestParticipantsDdl = '''
CREATE TABLE "recovery_request_participants" ("request_id" TEXT NOT NULL REFERENCES recovery_requests (id) ON DELETE CASCADE, "pubkey" TEXT NOT NULL, PRIMARY KEY ("request_id", "pubkey"))
''';

const _legacyV3RecoveryResponsesDdl = '''
CREATE TABLE "recovery_responses" ("id" TEXT NOT NULL, "request_id" TEXT NOT NULL REFERENCES recovery_requests (id) ON DELETE CASCADE, "steward_id" TEXT NULL REFERENCES stewards (id) ON DELETE SET NULL, "responder_pubkey" TEXT NOT NULL, "share_payload" TEXT NOT NULL, "share_distribution_version" INTEGER NOT NULL, "received_at" INTEGER NOT NULL, "nostr_event_id" TEXT NULL, "replying_to_event_id" TEXT NULL, "approved" INTEGER NOT NULL DEFAULT 0 CHECK ("approved" IN (0, 1)), "responded_at_ms" INTEGER NULL, "error_message" TEXT NULL, PRIMARY KEY ("id"))
''';

const _legacyV3OutboxDdl = '''
CREATE TABLE "outbox" ("id" TEXT NOT NULL, "vault_id" TEXT NULL REFERENCES vaults (id) ON DELETE CASCADE, "kind" INTEGER NOT NULL, "event_id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "next_attempt_at" INTEGER NULL, "event_json" TEXT NOT NULL, "correlation_id" TEXT NULL, PRIMARY KEY ("id"))
''';

const _legacyV3OutboxRelaysDdl = '''
CREATE TABLE "outbox_relays" ("outbox_id" TEXT NOT NULL REFERENCES outbox (id) ON DELETE CASCADE, "relay_url" TEXT NOT NULL, "status" TEXT NOT NULL, "attempts" INTEGER NOT NULL DEFAULT 0, "next_attempt_at" INTEGER NULL, "last_error" TEXT NULL, PRIMARY KEY ("outbox_id", "relay_url"))
''';

const _legacyV4InvitationsTableDdl = '''
CREATE TABLE "invitations" ("code" TEXT NOT NULL, "vault_id" TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE, "steward_id" TEXT NULL REFERENCES stewards (id) ON DELETE CASCADE, "payload" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "expires_at" INTEGER NULL, "accepted_at" INTEGER NULL, "accepted_by_pubkey" TEXT NULL, "revoked_at" INTEGER NULL, PRIMARY KEY ("code"))
''';
