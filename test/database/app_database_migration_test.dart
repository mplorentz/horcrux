import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Verifies [AppDatabase] migration from schema v1 files that predate the
/// Phase 2a `held_shares` table (same `user_version`, expanded drift schema).
void main() {
  test('upgrade from v1 without held_shares creates held_shares at v2', () async {
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
    expect(versionRow.first.columnAt(0), 2);

    await db.close();
  });

  test('upgrade to v2 skips createTable when held_shares already exists', () async {
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
    expect(versionRow.first.columnAt(0), 2);

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
