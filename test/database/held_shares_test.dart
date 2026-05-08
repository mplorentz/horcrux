import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/app_database.dart';

import '../helpers/test_database.dart';

void main() {
  group('HeldShares table + DAO (Phase 2a)', () {
    late AppDatabase db;

    setUp(() {
      db = newTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    Future<String> seedVault({String? id, String? ownerPubkey}) async {
      final f = await VaultFixture.stewarded(
        db,
        ownerPubkey: ownerPubkey ?? ('aa' * 32),
        id: id,
      );
      return f.vaultId;
    }

    test('insertIfNew writes a held_share row', () async {
      final vaultId = await seedVault();
      await HeldShareFixture.insert(
        db,
        vaultId: vaultId,
        shareIndex: 0,
        payload: 'share-bytes',
        distributionVersion: 1,
        nostrEventId: 'event-id-1',
      );

      final rows = await db.heldShareDao.forVault(vaultId);
      expect(rows, hasLength(1));
      expect(rows.single.sharePayload, 'share-bytes');
      expect(rows.single.shareIndex, 0);
      expect(rows.single.distributionVersion, 1);
      expect(rows.single.nostrEventId, 'event-id-1');
    });

    test('forVault returns rows ordered by distributionVersion descending', () async {
      final vaultId = await seedVault();
      await HeldShareFixture.insert(
        db,
        vaultId: vaultId,
        shareIndex: 0,
        payload: 'v1-bytes',
        distributionVersion: 1,
      );
      await HeldShareFixture.insert(
        db,
        vaultId: vaultId,
        shareIndex: 0,
        payload: 'v3-bytes',
        distributionVersion: 3,
      );
      await HeldShareFixture.insert(
        db,
        vaultId: vaultId,
        shareIndex: 0,
        payload: 'v2-bytes',
        distributionVersion: 2,
      );

      final rows = await db.heldShareDao.forVault(vaultId);
      expect(rows.map((r) => r.distributionVersion).toList(), [3, 2, 1]);
    });

    test('mostRecentForVault returns highest-version row', () async {
      final vaultId = await seedVault();
      await HeldShareFixture.insert(db,
          vaultId: vaultId, shareIndex: 0, payload: 'v1', distributionVersion: 1);
      await HeldShareFixture.insert(db,
          vaultId: vaultId, shareIndex: 0, payload: 'v5', distributionVersion: 5);
      await HeldShareFixture.insert(db,
          vaultId: vaultId, shareIndex: 0, payload: 'v2', distributionVersion: 2);

      final row = await db.heldShareDao.mostRecentForVault(vaultId);
      expect(row, isA<HeldShareRow>());
      expect(row!.distributionVersion, 5);
      expect(row.sharePayload, 'v5');
    });

    test('deleteForVault removes all rows for the vault', () async {
      final vaultId = await seedVault(id: 'vault-a');
      final vaultId2 = await seedVault(id: 'vault-b');
      await HeldShareFixture.insert(db,
          vaultId: vaultId, shareIndex: 0, payload: 'v1', distributionVersion: 1);
      await HeldShareFixture.insert(db,
          vaultId: vaultId, shareIndex: 0, payload: 'v2', distributionVersion: 2);
      await HeldShareFixture.insert(db,
          vaultId: vaultId2, shareIndex: 0, payload: 'other', distributionVersion: 1);

      await db.heldShareDao.deleteForVault(vaultId);

      expect(await db.heldShareDao.forVault(vaultId), isEmpty);
      // Other vault is unaffected.
      expect(await db.heldShareDao.forVault(vaultId2), hasLength(1));
    });

    test('pruneOldVersions keeps only the N most-recent distribution versions', () async {
      final vaultId = await seedVault();
      for (int v = 1; v <= 5; v++) {
        await HeldShareFixture.insert(
          db,
          vaultId: vaultId,
          shareIndex: 0,
          payload: 'v$v',
          distributionVersion: v,
          receivedAt: DateTime.now().millisecondsSinceEpoch + v * 1000,
        );
      }

      await db.heldShareDao.pruneOldVersions(vaultId, keepCount: 3);

      final remaining = await db.heldShareDao.forVault(vaultId);
      expect(remaining.map((r) => r.distributionVersion).toList(), [5, 4, 3]);
    });

    test('pruneOldVersions is a no-op when row count is within retention window', () async {
      final vaultId = await seedVault();
      await HeldShareFixture.insert(db,
          vaultId: vaultId, shareIndex: 0, payload: 'v1', distributionVersion: 1);
      await HeldShareFixture.insert(db,
          vaultId: vaultId, shareIndex: 0, payload: 'v2', distributionVersion: 2);

      await db.heldShareDao.pruneOldVersions(vaultId, keepCount: 3);

      expect(await db.heldShareDao.forVault(vaultId), hasLength(2));
    });

    test('cascade delete on vaults removes held_shares', () async {
      final vaultId = await seedVault();
      await HeldShareFixture.insert(db,
          vaultId: vaultId, shareIndex: 0, payload: 'share', distributionVersion: 1);

      await db.transaction(() async {
        await (db.delete(db.vaults)..where((v) => v.id.equals(vaultId))).go();
      });

      expect(await db.heldShareDao.forVault(vaultId), isEmpty);
    });

    test('insertIfNew is idempotent for the same id', () async {
      final vaultId = await seedVault();
      final now = DateTime.now().millisecondsSinceEpoch;
      final companion = HeldSharesCompanion.insert(
        id: 'fixed-id',
        vaultId: vaultId,
        shareIndex: 0,
        sharePayload: 'share-bytes',
        distributionVersion: 1,
        receivedAt: now,
        nostrEventId: const Value('evt-1'),
      );

      await db.heldShareDao.insertIfNew(companion);
      await db.heldShareDao.insertIfNew(companion); // second call — no-op

      final rows = await db.heldShareDao.forVault(vaultId);
      expect(rows, hasLength(1));
    });

    test(
      'insertIfNew ignores duplicate (vault_id, distribution_version, '
      'nostr_event_id) when primary key differs',
      () async {
        final vaultId = await seedVault();
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.heldShareDao.insertIfNew(
          HeldSharesCompanion.insert(
            id: 'held-share-id-first',
            vaultId: vaultId,
            shareIndex: 0,
            sharePayload: 'first-payload',
            distributionVersion: 2,
            receivedAt: now,
            nostrEventId: const Value('same-nostr-event'),
          ),
        );
        await db.heldShareDao.insertIfNew(
          HeldSharesCompanion.insert(
            id: 'held-share-id-second',
            vaultId: vaultId,
            shareIndex: 0,
            sharePayload: 'second-payload',
            distributionVersion: 2,
            receivedAt: now + 1,
            nostrEventId: const Value('same-nostr-event'),
          ),
        );

        final rows = await db.heldShareDao.forVault(vaultId);
        expect(rows, hasLength(1));
        expect(rows.single.id, 'held-share-id-first');
        expect(rows.single.sharePayload, 'first-payload');
      },
    );
  });
}
