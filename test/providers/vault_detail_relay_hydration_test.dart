import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/providers/vault_detail_repository.dart';

import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ownerPubkey = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';

  group('VaultDetailRepository relay hydration', () {
    late AppDatabase db;
    late VaultDetailRepository repository;

    setUp(() {
      db = newTestDatabase();
      repository = VaultDetailRepository(db: db);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    // -------------------------------------------------------------------------
    // Test 1: _hydrateDetail excludes steward-role relays when owner rows exist
    // -------------------------------------------------------------------------
    test('excludes steward-role relays when owner rows exist', () async {
      const vaultId = 'vdr-relay-test-1';
      final now = DateTime.now().millisecondsSinceEpoch;

      // Insert vault + owned_vaults (so we get OwnedVaultDetail)
      await db.into(db.vaults).insert(VaultsCompanion.insert(
            id: vaultId,
            name: 'Relay Hydrate Test',
            ownerPubkey: ownerPubkey,
            threshold: 1,
            totalShares: 1,
            createdAt: now,
          ));
      await db.into(db.ownedVaults).insert(OwnedVaultsCompanion.insert(
            vaultId: vaultId,
            content: 'test-content',
            contentHmac: Uint8List.fromList(List.filled(32, 0)),
            createdBySelfAt: now,
          ));
      // Insert a steward so backupConfig is non-null
      await db.into(db.stewards).insert(StewardsCompanion.insert(
            id: '$vaultId-steward-1',
            vaultId: vaultId,
            shareIndex: 0,
            pubkey: Value('b' * 64),
            name: const Value('Test Steward'),
            joinedAt: now,
          ));

      // Owner relays: [A, B]
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-owner-a',
            vaultId: vaultId,
            url: 'wss://relay-a.example.com',
            role: 'owner',
            addedAt: now,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-owner-b',
            vaultId: vaultId,
            url: 'wss://relay-b.example.com',
            role: 'owner',
            addedAt: now,
          ));

      // Steward relays: [A, B, C] — C should NOT appear in hydrated detail
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-a',
            vaultId: vaultId,
            url: 'wss://relay-a.example.com',
            role: 'steward',
            addedAt: now,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-b',
            vaultId: vaultId,
            url: 'wss://relay-b.example.com',
            role: 'steward',
            addedAt: now,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-c',
            vaultId: vaultId,
            url: 'wss://relay-c.example.com',
            role: 'steward',
            addedAt: now,
          ));

      // Act
      final detail = await repository.getVaultDetail(vaultId);
      expect(detail, isNotNull);
      final config = detail!.backupConfig;
      expect(config, isNotNull);

      // Assert: only owner relays [A, B], not steward-only relay C
      expect(config!.relays, hasLength(2));
      expect(config.relays, contains('wss://relay-a.example.com'));
      expect(config.relays, contains('wss://relay-b.example.com'));
      expect(config.relays, isNot(contains('wss://relay-c.example.com')));
    });

    // -------------------------------------------------------------------------
    // Test 2: falls back to steward-role relays when no owner rows exist
    // -------------------------------------------------------------------------
    test('falls back to steward-role relays when no owner rows exist', () async {
      const vaultId = 'vdr-relay-test-2';
      final now = DateTime.now().millisecondsSinceEpoch;

      // Insert vault + owned_vaults
      await db.into(db.vaults).insert(VaultsCompanion.insert(
            id: vaultId,
            name: 'Fallback Relay Test',
            ownerPubkey: ownerPubkey,
            threshold: 1,
            totalShares: 1,
            createdAt: now,
          ));
      await db.into(db.ownedVaults).insert(OwnedVaultsCompanion.insert(
            vaultId: vaultId,
            content: 'test-content',
            contentHmac: Uint8List.fromList(List.filled(32, 0)),
            createdBySelfAt: now,
          ));
      await db.into(db.stewards).insert(StewardsCompanion.insert(
            id: '$vaultId-steward-1',
            vaultId: vaultId,
            shareIndex: 0,
            pubkey: Value('b' * 64),
            name: const Value('Test Steward'),
            joinedAt: now,
          ));

      // NO owner relays — only steward relays [X, Y]
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-x',
            vaultId: vaultId,
            url: 'wss://relay-x.example.com',
            role: 'steward',
            addedAt: now,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-y',
            vaultId: vaultId,
            url: 'wss://relay-y.example.com',
            role: 'steward',
            addedAt: now,
          ));

      // Act
      final detail = await repository.getVaultDetail(vaultId);
      expect(detail, isNotNull);
      final config = detail!.backupConfig;
      expect(config, isNotNull);

      // Assert: falls back to steward relays [X, Y]
      expect(config!.relays, hasLength(2));
      expect(config.relays, contains('wss://relay-x.example.com'));
      expect(config.relays, contains('wss://relay-y.example.com'));
    });

    // -------------------------------------------------------------------------
    // Test 3: removed relay does not reappear via VaultDetailRepository
    // -------------------------------------------------------------------------
    test('removed relay does not reappear in VaultDetail after owner-role update', () async {
      const vaultId = 'vdr-relay-test-3';
      final now = DateTime.now().millisecondsSinceEpoch;

      // Insert vault + owned_vaults
      await db.into(db.vaults).insert(VaultsCompanion.insert(
            id: vaultId,
            name: 'Remove Relay Test',
            ownerPubkey: ownerPubkey,
            threshold: 1,
            totalShares: 1,
            createdAt: now,
          ));
      await db.into(db.ownedVaults).insert(OwnedVaultsCompanion.insert(
            vaultId: vaultId,
            content: 'test-content',
            contentHmac: Uint8List.fromList(List.filled(32, 0)),
            createdBySelfAt: now,
          ));
      await db.into(db.stewards).insert(StewardsCompanion.insert(
            id: '$vaultId-steward-1',
            vaultId: vaultId,
            shareIndex: 0,
            pubkey: Value('b' * 64),
            name: const Value('Test Steward'),
            joinedAt: now,
          ));

      // Owner relays: [A, B] (user already removed C from owner rows)
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-owner-a',
            vaultId: vaultId,
            url: 'wss://relay-a.example.com',
            role: 'owner',
            addedAt: now,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-owner-b',
            vaultId: vaultId,
            url: 'wss://relay-b.example.com',
            role: 'owner',
            addedAt: now,
          ));

      // Steward relays: [A, B, C] — stale C still here
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-a',
            vaultId: vaultId,
            url: 'wss://relay-a.example.com',
            role: 'steward',
            addedAt: now,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-b',
            vaultId: vaultId,
            url: 'wss://relay-b.example.com',
            role: 'steward',
            addedAt: now,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-c',
            vaultId: vaultId,
            url: 'wss://relay-c.example.com',
            role: 'steward',
            addedAt: now,
          ));

      // Act: hydrate detail
      final detail = await repository.getVaultDetail(vaultId);
      expect(detail, isNotNull);
      final config = detail!.backupConfig;
      expect(config, isNotNull);

      // Assert: C should NOT appear (only owner rows used)
      expect(config!.relays, hasLength(2));
      expect(config.relays, contains('wss://relay-a.example.com'));
      expect(config.relays, contains('wss://relay-b.example.com'));
      expect(config.relays, isNot(contains('wss://relay-c.example.com')));
    });
  });
}
