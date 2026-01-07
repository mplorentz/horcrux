import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';

void main() {
  group('BackupConfig', () {
    // T027: Tests for owner steward helpers
    group('owner steward helpers', () {
      test('hasOwnerSteward returns true when config has owner steward', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final ownerSteward = createOwnerSteward(pubkey: hexPubkey);
        final regularSteward = createSteward(
          pubkey: 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          name: 'Alice',
        );

        final config = createBackupConfig(
          vaultId: 'vault-1',
          threshold: 2,
          totalKeys: 2,
          stewards: [ownerSteward, regularSteward],
          relays: ['wss://relay.example.com'],
        );

        expect(hasOwnerSteward(config), isTrue);
      });

      test('hasOwnerSteward returns false when config has no owner steward', () {
        final steward1 = createSteward(
          pubkey: 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          name: 'Alice',
        );
        final steward2 = createSteward(
          pubkey: 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          name: 'Bob',
        );

        final config = createBackupConfig(
          vaultId: 'vault-1',
          threshold: 2,
          totalKeys: 2,
          stewards: [steward1, steward2],
          relays: ['wss://relay.example.com'],
        );

        expect(hasOwnerSteward(config), isFalse);
      });

      test('getOwnerSteward returns owner steward when present', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final ownerSteward = createOwnerSteward(pubkey: hexPubkey, name: 'Me');
        final regularSteward = createSteward(
          pubkey: 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          name: 'Alice',
        );

        final config = createBackupConfig(
          vaultId: 'vault-1',
          threshold: 2,
          totalKeys: 2,
          stewards: [ownerSteward, regularSteward],
          relays: ['wss://relay.example.com'],
        );

        final result = getOwnerSteward(config);
        expect(result, isNotNull);
        expect(result!.isOwner, isTrue);
        expect(result.name, equals('Me'));
      });

      test('getOwnerSteward returns null when no owner steward', () {
        final steward = createSteward(
          pubkey: 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          name: 'Alice',
        );

        final config = createBackupConfig(
          vaultId: 'vault-1',
          threshold: 1,
          totalKeys: 1,
          stewards: [steward],
          relays: ['wss://relay.example.com'],
        );

        final result = getOwnerSteward(config);
        expect(result, isNull);
      });

      test('owner steward is preserved through JSON serialization', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final ownerSteward = createOwnerSteward(pubkey: hexPubkey);

        final config = createBackupConfig(
          vaultId: 'vault-1',
          threshold: 1,
          totalKeys: 1,
          stewards: [ownerSteward],
          relays: ['wss://relay.example.com'],
        );

        final json = backupConfigToJson(config);
        final restored = backupConfigFromJson(json);

        expect(hasOwnerSteward(restored), isTrue);
        expect(getOwnerSteward(restored)?.isOwner, isTrue);
      });
    });
  });
}
