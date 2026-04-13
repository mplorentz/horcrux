import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/utils/nostr_display.dart';

void main() {
  const aliceHex = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
  const bobHex = 'e0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';

  group('displayNameFromPubkey', () {
    test('uses ownerName when pubkey is vault owner', () {
      final vault = Vault(
        id: 'v1',
        name: 'Secrets',
        createdAt: DateTime.utc(2024),
        ownerPubkey: aliceHex,
        ownerName: 'Alice Owner',
      );
      expect(displayNameFromPubkey(vault, aliceHex), 'Alice Owner');
    });

    test('uses steward name from backupConfig', () {
      final bob = createSteward(pubkey: bobHex, name: 'Bob Steward');
      final config = createBackupConfig(
        vaultId: 'v1',
        threshold: 1,
        totalKeys: 1,
        stewards: [bob],
        relays: ['wss://relay.example.com'],
      );
      final vault = Vault(
        id: 'v1',
        name: 'Secrets',
        createdAt: DateTime.utc(2024),
        ownerPubkey: aliceHex,
        backupConfig: config,
      );
      expect(displayNameFromPubkey(vault, bobHex), 'Bob Steward');
    });

    test('falls back to short npub for owner when ownerName is absent', () {
      final vault = Vault(
        id: 'v1',
        name: 'Secrets',
        createdAt: DateTime.utc(2024),
        ownerPubkey: aliceHex,
      );
      final label = displayNameFromPubkey(vault, aliceHex);
      expect(label, startsWith('npub1'));
      expect(label, contains('...'));
    });

    test('falls back to short npub for steward pubkey not present on vault', () {
      final vault = Vault(
        id: 'v1',
        name: 'Secrets',
        createdAt: DateTime.utc(2024),
        ownerPubkey: aliceHex,
        ownerName: 'Alice Owner',
      );
      final label = displayNameFromPubkey(vault, bobHex);
      expect(label, startsWith('npub1'));
      expect(label, contains('...'));
    });

    test('uses shortNpub when vault is null', () {
      final label = displayNameFromPubkey(null, aliceHex);
      expect(label, startsWith('npub1'));
      expect(label, contains('...'));
    });
  });

  group('displayNameFromPubkeyOrNull', () {
    test('returns ownerName when owner pubkey matches', () {
      final vault = Vault(
        id: 'v1',
        name: 'Secrets',
        createdAt: DateTime.utc(2024),
        ownerPubkey: aliceHex,
        ownerName: 'Alice Owner',
      );
      expect(displayNameFromPubkeyOrNull(vault, aliceHex), 'Alice Owner');
    });

    test('returns null for owner when ownerName is absent', () {
      final vault = Vault(
        id: 'v1',
        name: 'Secrets',
        createdAt: DateTime.utc(2024),
        ownerPubkey: aliceHex,
      );
      expect(displayNameFromPubkeyOrNull(vault, aliceHex), isNull);
    });

    test('returns steward name from backupConfig when set', () {
      final bob = createSteward(pubkey: bobHex, name: 'Bob Steward');
      final config = createBackupConfig(
        vaultId: 'v1',
        threshold: 1,
        totalKeys: 1,
        stewards: [bob],
        relays: ['wss://relay.example.com'],
      );
      final vault = Vault(
        id: 'v1',
        name: 'Secrets',
        createdAt: DateTime.utc(2024),
        ownerPubkey: aliceHex,
        backupConfig: config,
      );
      expect(displayNameFromPubkeyOrNull(vault, bobHex), 'Bob Steward');
    });

    test('returns null for steward in backupConfig with no name', () {
      final bob = createSteward(pubkey: bobHex);
      final config = createBackupConfig(
        vaultId: 'v1',
        threshold: 1,
        totalKeys: 1,
        stewards: [bob],
        relays: ['wss://relay.example.com'],
      );
      final vault = Vault(
        id: 'v1',
        name: 'Secrets',
        createdAt: DateTime.utc(2024),
        ownerPubkey: aliceHex,
        backupConfig: config,
      );
      expect(displayNameFromPubkeyOrNull(vault, bobHex), isNull);
      expect(displayNameFromPubkey(vault, bobHex), startsWith('npub1'));
    });

    test('returns null without vault', () {
      expect(displayNameFromPubkeyOrNull(null, aliceHex), isNull);
    });
  });
}
