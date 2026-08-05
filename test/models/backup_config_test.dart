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

    group('threshold normalization (horcrux_app-2sxc)', () {
      group('BackupConfigExtension.normalizeThreshold', () {
        test('returns threshold as-is when already valid (threshold 2, 3 stewards)', () {
          expect(BackupConfigExtension.normalizeThreshold(2, 3), equals(2));
        });

        test('returns threshold as-is when threshold 1 with 1 steward', () {
          expect(BackupConfigExtension.normalizeThreshold(1, 1), equals(1));
        });

        test('returns threshold as-is when threshold 1 with 0 stewards', () {
          expect(BackupConfigExtension.normalizeThreshold(1, 0), equals(1));
        });

        test('bumps threshold 1 to 2 when steward count is 2 (auto-bump)', () {
          expect(BackupConfigExtension.normalizeThreshold(1, 2), equals(2));
        });

        test('bumps threshold 1 to 2 when steward count is 3 (auto-bump)', () {
          expect(BackupConfigExtension.normalizeThreshold(1, 3), equals(2));
        });

        test('bumps threshold 1 to 2 when steward count is 10 (max, auto-bump)', () {
          expect(BackupConfigExtension.normalizeThreshold(1, 10), equals(2));
        });

        test('clamps threshold to steward count when threshold exceeds it', () {
          expect(BackupConfigExtension.normalizeThreshold(5, 3), equals(3));
        });

        test('does not clamp threshold 1 when 0 stewards (placeholder for empty plan)', () {
          expect(BackupConfigExtension.normalizeThreshold(1, 0), equals(1));
        });

        test('bumps threshold 0 to 1 when steward count is 1 (clamp below minimum)', () {
          expect(BackupConfigExtension.normalizeThreshold(0, 1), equals(1));
        });

        test('bumps threshold 0 to 2 when steward count is 2 (clamp below minimum)', () {
          expect(BackupConfigExtension.normalizeThreshold(0, 2), equals(2));
        });

        test('bumps threshold 0 to 2 when steward count is 3 (clamp below minimum)', () {
          expect(BackupConfigExtension.normalizeThreshold(0, 3), equals(2));
        });

        test('bumps threshold 1 to 2 when steward count is 2 (auto-bump)', () {
          expect(BackupConfigExtension.normalizeThreshold(1, 2), equals(2));
        });

        test('does not clamp threshold 3 when 0 stewards (no minimum floor)', () {
          expect(BackupConfigExtension.normalizeThreshold(3, 0), equals(3));
        });

        test('clamps threshold to 1 when 1 steward but threshold is 3', () {
          expect(BackupConfigExtension.normalizeThreshold(3, 1), equals(1));
        });

        test('auto-bump takes priority over clamp (threshold 1 becomes 2, not 1)', () {
          // With 2 stewards, threshold 1 normalizes to 2, not clamped to 1
          expect(BackupConfigExtension.normalizeThreshold(1, 2), equals(2));
        });

        test('does not bump threshold 2+ when steward count is 2', () {
          expect(BackupConfigExtension.normalizeThreshold(2, 2), equals(2));
        });

        test('does not bump threshold 3 when steward count is 5', () {
          expect(BackupConfigExtension.normalizeThreshold(3, 5), equals(3));
        });

        test('handles threshold equal to steward count (both 2)', () {
          expect(BackupConfigExtension.normalizeThreshold(2, 2), equals(2));
        });

        test('handles threshold equal to steward count (both 5)', () {
          expect(BackupConfigExtension.normalizeThreshold(5, 5), equals(5));
        });
      });

      group('BackupConfigExtension.minThresholdForDisplay', () {
        test('is 1 when steward count is 0', () {
          expect(BackupConfigExtension.minThresholdForDisplay(0), equals(1));
        });

        test('is 1 when steward count is 1', () {
          expect(BackupConfigExtension.minThresholdForDisplay(1), equals(1));
        });

        test('is 2 when steward count is 2', () {
          expect(BackupConfigExtension.minThresholdForDisplay(2), equals(2));
        });

        test('is 2 when steward count is 3', () {
          expect(BackupConfigExtension.minThresholdForDisplay(3), equals(2));
        });

        test('is 2 when steward count is 10', () {
          expect(BackupConfigExtension.minThresholdForDisplay(10), equals(2));
        });

        test('min threshold for display never exceeds 2 regardless of steward count', () {
          expect(BackupConfigExtension.minThresholdForDisplay(100), equals(2));
        });
      });

      group('BackupConfigExtension.distributionMinThreshold', () {
        test('is always 2', () {
          expect(BackupConfigExtension.distributionMinThreshold, equals(2));
        });
      });

      group('BackupConfigExtension.defaultThreshold', () {
        test('returns minThreshold (1) when steward count is 0', () {
          expect(BackupConfigExtension.defaultThreshold(0), equals(1));
        });

        test('returns 1 when steward count is 1', () {
          expect(BackupConfigExtension.defaultThreshold(1), equals(1));
        });

        test('returns 2 when steward count is 2', () {
          expect(BackupConfigExtension.defaultThreshold(2), equals(2));
        });

        test('returns n-1 when steward count is 3', () {
          expect(BackupConfigExtension.defaultThreshold(3), equals(2));
        });

        test('returns n-1 when steward count is 4', () {
          expect(BackupConfigExtension.defaultThreshold(4), equals(3));
        });

        test('returns n-1 when steward count is 5', () {
          expect(BackupConfigExtension.defaultThreshold(5), equals(4));
        });

        test('returns n-1 when steward count is 10 (max)', () {
          expect(BackupConfigExtension.defaultThreshold(10), equals(9));
        });
      });

      group('comprehensive: normalizeThreshold covers all onboarding scenarios', () {
        // Simulates the full flow: new plan with 0 stewards, then add stewards one by one
        test('new plan flow: 0 stewards → 1 steward → 2 stewards → 3 stewards', () {
          int threshold = BackupConfigExtension.defaultThreshold(0); // 0 stewards
          expect(threshold, equals(1));

          threshold = BackupConfigExtension.defaultThreshold(1); // 1 steward
          expect(threshold, equals(1));

          threshold = BackupConfigExtension.defaultThreshold(2); // 2 stewards
          expect(threshold, equals(2));

          threshold = BackupConfigExtension.defaultThreshold(3); // 3 stewards
          expect(threshold, equals(2));
        });

        // Simulates: existing plan loaded from DB with threshold 1, but 2 stewards
        test('existing plan loaded from DB: threshold 1 with 2 stewards normalizes to 2', () {
          final normalized = BackupConfigExtension.normalizeThreshold(1, 2);
          expect(normalized, equals(2));
        });

        // Simulates: existing plan loaded from DB with threshold 3, but only 2 stewards remain
        test('existing plan loaded from DB: threshold 3 with 2 stewards clamps to 2', () {
          final normalized = BackupConfigExtension.normalizeThreshold(3, 2);
          expect(normalized, equals(2));
        });

        // Simulates: save normalization with 2 stewards, threshold 1
        test('save normalization: threshold 1 with 2 stewards bumps to 2', () {
          final normalized = BackupConfigExtension.normalizeThreshold(1, 2);
          expect(normalized, equals(2));
          expect(BackupConfigExtension.minThresholdForDisplay(2), equals(2));
        });

        // Simulates: remove steward so only 1 left, threshold should stay valid
        test('remove steward: 2 stewards → 1, threshold 2 normalizes to 1', () {
          final normalized = BackupConfigExtension.normalizeThreshold(2, 1);
          expect(normalized, equals(1));
        });

        // Simulates: add steward back to 2, threshold 1 should bump to 2
        test('add steward back: 1 steward → 2, threshold 1 normalizes to 2', () {
          final normalized = BackupConfigExtension.normalizeThreshold(1, 2);
          expect(normalized, equals(2));
        });
      });
    });

    group('isValidForSave / isValidForDistribution (horcrux_app-2sxc)', () {
      BackupConfig makeConfig(int threshold, int stewardCount) {
        final stewards = List.generate(
            stewardCount,
            (i) => createSteward(
                  pubkey: '${i + 1}'.padLeft(64, '0'),
                  name: 'Steward $i',
                ));
        return BackupConfig(
          vaultId: 'v1',
          threshold: threshold,
          stewards: stewards,
          relays: const ['wss://relay.example.com'],
          createdAt: DateTime.now(),
          distributionVersion: 0,
        );
      }

      test('isValidForSave accepts threshold 1 with 2 stewards (structural, no distribution check)',
          () {
        expect(makeConfig(1, 2).isValidForSave, isTrue);
      });

      test('isValidForSave accepts threshold 1 with 1 steward', () {
        expect(makeConfig(1, 1).isValidForSave, isTrue);
      });

      test('isValidForSave accepts threshold 2 with 2 stewards', () {
        expect(makeConfig(2, 2).isValidForSave, isTrue);
      });

      test('isValidForSave rejects threshold 0 with 1 steward', () {
        expect(makeConfig(0, 1).isValidForSave, isFalse);
      });

      test('isValidForSave rejects threshold 0 with 2 stewards', () {
        expect(makeConfig(0, 2).isValidForSave, isFalse);
      });

      test('isValidForSave accepts empty config (no stewards)', () {
        expect(makeConfig(1, 0).isValidForSave, isTrue);
      });

      test('isValidForDistribution rejects threshold 1 with 2 stewards', () {
        expect(makeConfig(1, 2).isValidForDistribution, isFalse);
      });

      test('isValidForDistribution rejects threshold 1 with 5 stewards', () {
        expect(makeConfig(1, 5).isValidForDistribution, isFalse);
      });

      test('isValidForDistribution accepts threshold 2 with 2 stewards', () {
        expect(makeConfig(2, 2).isValidForDistribution, isTrue);
      });

      test('isValidForDistribution accepts threshold 3 with 5 stewards', () {
        expect(makeConfig(3, 5).isValidForDistribution, isTrue);
      });

      test('isValidForDistribution rejects threshold 1 with 1 steward (needs 2+ stewards)', () {
        expect(makeConfig(1, 1).isValidForDistribution, isFalse);
      });

      test('isValidForDistribution rejects empty config (no stewards)', () {
        expect(makeConfig(1, 0).isValidForDistribution, isFalse);
      });

      test('isValidForDistribution rejects threshold 0 with 2 stewards', () {
        expect(makeConfig(0, 2).isValidForDistribution, isFalse);
      });
    });

    group('createBackupConfig threshold validation (constructor is permissive)', () {
      // createBackupConfig only enforces VaultBackupConstraints.minThreshold (1),
      // not minThresholdForDisplay(totalKeys). The stricter enforcement is in
      // isValidForDistribution, saveBackupConfig, and generateShamirShares.
      final stewards2 = [
        createSteward(pubkey: 'a${'0' * 63}', name: 'A'),
        createSteward(pubkey: 'b${'0' * 63}', name: 'B'),
      ];

      test('accepts threshold 1 with 2 stewards (constructor permissive)', () {
        expect(
          () => createBackupConfig(
            vaultId: 'v1',
            threshold: 1,
            totalKeys: 2,
            stewards: stewards2,
            relays: ['wss://relay.example.com'],
          ),
          returnsNormally,
        );
      });

      test('isValid still rejects threshold 1 with 2 stewards', () {
        final config = createBackupConfig(
          vaultId: 'v1',
          threshold: 1,
          totalKeys: 2,
          stewards: stewards2,
          relays: ['wss://relay.example.com'],
        );
        expect(config.isValidForDistribution, isFalse);
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
