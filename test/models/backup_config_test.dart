import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';

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

        final cloned = config.copyWith();

        expect(hasOwnerSteward(cloned), isTrue);
        expect(getOwnerSteward(cloned)?.isOwner, isTrue);
      });
    });

    group('needsRedistribution', () {
      BackupConfig distributedConfig(
        List<Steward> stewards, {
        int version = 1,
      }) {
        return BackupConfig(
          vaultId: 'vault-1',
          threshold: 2,
          stewards: stewards,
          relays: const ['wss://relay.example.com'],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          distributionVersion: version,
        );
      }

      test('is false after publish when stewards await acknowledgment only', () {
        const hex = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        const hexB = 'b0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final s1 = createSteward(
          pubkey: hex,
        ).copyWith(status: StewardStatus.awaitingKey, giftWrapEventId: 'evt1');
        final s2 = createSteward(
          pubkey: hexB,
        ).copyWith(status: StewardStatus.awaitingKey, giftWrapEventId: 'evt2');
        final config = distributedConfig([s1, s2]);
        expect(config.needsRedistribution, isFalse);
      });

      test('is true when publish has not been recorded for a keyed steward', () {
        const hex = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        const hexB = 'b0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final s1 = createSteward(
          pubkey: hex,
        ).copyWith(status: StewardStatus.awaitingKey);
        final s2 = createSteward(
          pubkey: hexB,
        ).copyWith(status: StewardStatus.awaitingKey);
        final config = distributedConfig([s1, s2]);
        expect(config.needsRedistribution, isTrue);
      });

      test('is true for awaitingNewKey without publish marker', () {
        const hex = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        const hexB = 'b0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final s1 = createSteward(
          pubkey: hex,
        ).copyWith(status: StewardStatus.awaitingNewKey);
        final s2 = createSteward(
          pubkey: hexB,
        ).copyWith(status: StewardStatus.awaitingKey);
        final config = distributedConfig([s1, s2]);
        expect(config.needsRedistribution, isTrue);
      });
    });

    group('BackupConfig equality', () {
      test('two instances with same fields are equal and have same hashCode', () {
        const pubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final s1 = createSteward(pubkey: pubkey, name: 'A', id: 'id-a');
        final s2 = createSteward(
          pubkey: 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          name: 'B',
          id: 'id-b',
        );
        final created = DateTime.utc(2025, 3, 1);
        final a = BackupConfig(
          vaultId: 'v1',
          threshold: 2,
          stewards: [s1, s2],
          relays: const ['wss://a.example', 'wss://b.example'],
          instructions: 'keep safe',
          createdAt: created,
          distributionVersion: 3,
        );
        final b = BackupConfig(
          vaultId: 'v1',
          threshold: 2,
          stewards: [s1, s2],
          relays: const ['wss://a.example', 'wss://b.example'],
          instructions: 'keep safe',
          createdAt: created,
          distributionVersion: 3,
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('relays order matters', () {
        const pubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final s1 = createSteward(pubkey: pubkey, name: 'A');
        final s2 = createSteward(
          pubkey: 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          name: 'B',
        );
        final created = DateTime.utc(2025, 3, 1);
        final a = BackupConfig(
          vaultId: 'v1',
          threshold: 2,
          stewards: [s1, s2],
          relays: const ['wss://first', 'wss://second'],
          createdAt: created,
          distributionVersion: 1,
        );
        final b = BackupConfig(
          vaultId: 'v1',
          threshold: 2,
          stewards: [s1, s2],
          relays: const ['wss://second', 'wss://first'],
          createdAt: created,
          distributionVersion: 1,
        );
        expect(a, isNot(equals(b)));
      });
    });

    group('Vault equality with BackupConfig', () {
      test('hydration-shaped Vaults compare equal when backup configs match', () {
        const pubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final s1 = createSteward(pubkey: pubkey, name: 'A');
        final s2 = createSteward(
          pubkey: 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          name: 'B',
        );
        final created = DateTime.utc(2025, 3, 1);
        final cfg1 = BackupConfig(
          vaultId: 'vault-x',
          threshold: 2,
          stewards: [s1, s2],
          relays: const ['wss://relay.example.com'],
          createdAt: created,
          distributionVersion: 1,
        );
        final cfg2 = BackupConfig(
          vaultId: 'vault-x',
          threshold: 2,
          stewards: [s1, s2],
          relays: const ['wss://relay.example.com'],
          createdAt: created,
          distributionVersion: 1,
        );
        final v1 = Vault(
          id: 'vault-x',
          name: 'N',
          createdAt: created,
          ownerPubkey: pubkey,
          backupConfig: cfg1,
          pushEnabled: true,
        );
        final v2 = Vault(
          id: 'vault-x',
          name: 'N',
          createdAt: created,
          ownerPubkey: pubkey,
          backupConfig: cfg2,
          pushEnabled: true,
        );
        expect(v1, equals(v2));
        expect(v1.hashCode, v2.hashCode);
      });
    });
  });
}
