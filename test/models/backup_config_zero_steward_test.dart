import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';

void main() {
  group('BackupConfig with 0 stewards', () {
    test('createBackupConfig with 0 stewards preserves relays and instructions', () {
      final config = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 0,
        totalKeys: 0,
        stewards: [],
        relays: ['wss://custom.relay.example.com'],
        instructions: 'Only recover if I ask',
      );

      expect(config.relays, ['wss://custom.relay.example.com']);
      expect(config.instructions, 'Only recover if I ask');
      expect(config.threshold, 0);
      expect(config.stewards, isEmpty);
      expect(config.distributionVersion, 0);
    });

    test('createBackupConfig with 0 stewards requires at least one relay', () {
      expect(
        () => createBackupConfig(
          vaultId: 'test-vault',
          threshold: 0,
          totalKeys: 0,
          stewards: [],
          relays: [],
          instructions: null,
        ),
        throwsArgumentError,
      );
    });

    test('isValid with 0 stewards returns true when relays are non-empty', () {
      final config = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 0,
        totalKeys: 0,
        stewards: [],
        relays: ['wss://relay.example.com'],
        instructions: null,
      );

      expect(config.isValid, isTrue);
    });

    test('isValid with 0 stewards returns false when relays are deleted', () {
      final config = BackupConfig(
        vaultId: 'test-vault',
        threshold: 0,
        stewards: [],
        relays: [],
        createdAt: DateTime.now(),
        distributionVersion: 0,
        instructions: null,
      );

      expect(config.isValid, isFalse);
    });
  });
}
