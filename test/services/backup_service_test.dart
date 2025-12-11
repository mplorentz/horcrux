import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:horcrux/services/backup_service.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/shard_distribution_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:horcrux/models/shard_data.dart';

import 'backup_service_test.mocks.dart';

@GenerateMocks([
  VaultRepository,
  ShardDistributionService,
  LoginService,
  RelayScanService,
])
void main() {
  group('BackupService - Shamir Secret Sharing', () {
    late BackupService backupService;
    late MockVaultRepository mockRepository;
    late MockShardDistributionService mockShardDistributionService;
    late MockLoginService mockLoginService;
    late MockRelayScanService mockRelayScanService;

    setUp(() {
      mockRepository = MockVaultRepository();
      mockShardDistributionService = MockShardDistributionService();
      mockLoginService = MockLoginService();
      mockRelayScanService = MockRelayScanService();
      backupService = BackupService(
        mockRepository,
        mockShardDistributionService,
        mockLoginService,
        mockRelayScanService,
      );
    });

    const testSecret = 'This is a test secret that we want to protect with Shamir Secret Sharing!';
    const testCreatorPubkey = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
    const testVaultId = 'test-vault-123';
    const testVaultName = 'Test Vault';
    // Note: peers list excludes the creator
    const testPeers = [
      {
        'name': 'Peer 1',
        'pubkey': 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
      },
      {
        'name': 'Peer 2',
        'pubkey': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      },
    ];

    test('generateShamirShares creates correct number of shares', () async {
      // Arrange
      const threshold = 3;
      const totalShards = 5;

      // Act
      final shares = await backupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: testVaultName,
        peers: testPeers,
      );

      // Assert
      expect(shares, hasLength(totalShards));
      for (int i = 0; i < totalShards; i++) {
        expect(shares[i].threshold, threshold);
        expect(shares[i].totalShards, totalShards);
        expect(shares[i].shardIndex, i);
        expect(shares[i].creatorPubkey, testCreatorPubkey);
        expect(shares[i].shard, isA<String>());
        expect(shares[i].shard.isNotEmpty, true);
        expect(shares[i].primeMod, isA<String>());
        expect(shares[i].primeMod.isNotEmpty, true);
      }
    });

    test('generateShamirShares creates unique shares', () async {
      // Arrange
      const threshold = 2;
      const totalShards = 3;

      // Act
      final shares = await backupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: testVaultName,
        peers: testPeers,
      );

      // Assert - All shares should be unique
      final shardStrings = shares.map((s) => s.shard).toList();
      expect(shardStrings.toSet().length, totalShards);
    });

    test(
      'reconstructFromShares recovers original secret with minimum threshold',
      () async {
        // Arrange
        const threshold = 3;
        const totalShards = 5;
        final originalShares = await backupService.generateShamirShares(
          content: testSecret,
          threshold: threshold,
          totalShards: totalShards,
          creatorPubkey: testCreatorPubkey,
          vaultId: testVaultId,
          vaultName: testVaultName,
          peers: testPeers,
        );

        // Act - Use exactly threshold number of shares
        final reconstructed = await backupService.reconstructFromShares(
          shares: originalShares.sublist(0, threshold),
        );

        // Assert
        expect(reconstructed, testSecret);
      },
    );

    test(
      'reconstructFromShares recovers original secret with more than threshold',
      () async {
        // Arrange
        const threshold = 2;
        const totalShards = 4;
        final originalShares = await backupService.generateShamirShares(
          content: testSecret,
          threshold: threshold,
          totalShards: totalShards,
          creatorPubkey: testCreatorPubkey,
          vaultId: testVaultId,
          vaultName: testVaultName,
          peers: testPeers,
        );

        // Act - Use more than threshold shares (all 4)
        final reconstructed = await backupService.reconstructFromShares(
          shares: originalShares,
        );

        // Assert
        expect(reconstructed, testSecret);
      },
    );

    test(
      'reconstructFromShares works with different share combinations',
      () async {
        // Arrange
        const threshold = 3;
        const totalShards = 5;
        final originalShares = await backupService.generateShamirShares(
          content: testSecret,
          threshold: threshold,
          totalShards: totalShards,
          creatorPubkey: testCreatorPubkey,
          vaultId: testVaultId,
          vaultName: testVaultName,
          peers: testPeers,
        );

        // Act - Try different combinations of threshold shares
        final combination1 = await backupService.reconstructFromShares(
          shares: [originalShares[0], originalShares[1], originalShares[2]],
        );
        final combination2 = await backupService.reconstructFromShares(
          shares: [originalShares[1], originalShares[3], originalShares[4]],
        );
        final combination3 = await backupService.reconstructFromShares(
          shares: [originalShares[0], originalShares[2], originalShares[4]],
        );

        // Assert - All combinations should recover the original secret
        expect(combination1, testSecret);
        expect(combination2, testSecret);
        expect(combination3, testSecret);
      },
    );

    test('reconstructFromShares throws with insufficient shares', () async {
      // Arrange
      const threshold = 3;
      const totalShards = 5;
      final originalShares = await backupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: testVaultName,
        peers: testPeers,
      );

      // Act & Assert - Should throw when fewer than threshold shares provided
      expect(
        () => backupService.reconstructFromShares(
          shares: originalShares.sublist(0, threshold - 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reconstructFromShares throws with mismatched parameters', () async {
      // Arrange - Create two different share sets
      final shares1 = await backupService.generateShamirShares(
        content: testSecret,
        threshold: 2,
        totalShards: 3,
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: testVaultName,
        peers: testPeers,
      );
      final shares2 = await backupService.generateShamirShares(
        content: 'Different secret',
        threshold: 2,
        totalShards: 3,
        creatorPubkey: 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef1234',
        vaultId: 'different-vault',
        vaultName: 'Different Vault',
        peers: [
          {
            'name': 'Peer A',
            'pubkey': 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef1234',
          },
          {
            'name': 'Peer B',
            'pubkey': '1111111111111111111111111111111111111111111111111111111111111111',
          },
          {
            'name': 'Peer C',
            'pubkey': '2222222222222222222222222222222222222222222222222222222222222222',
          },
        ],
      );

      // Act & Assert - Should throw when mixing shares from different sets
      expect(
        () => backupService.reconstructFromShares(
          shares: [shares1[0], shares2[1]],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reconstructFromShares throws with empty shares list', () async {
      // Act & Assert
      expect(
        () => backupService.reconstructFromShares(shares: []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('generateShamirShares works with long secrets', () async {
      // Arrange - Create a secret longer than 256 bits
      final longSecret = 'A' * 500;
      const threshold = 2;
      const totalShards = 3;

      // Act
      final shares = await backupService.generateShamirShares(
        content: longSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: testVaultName,
        peers: testPeers,
      );

      final reconstructed = await backupService.reconstructFromShares(
        shares: shares.sublist(0, threshold),
      );

      // Assert
      expect(reconstructed, longSecret);
    });

    test('generateShamirShares works with special characters', () async {
      // Arrange
      const specialSecret = 'Test with émojis 🔐 and spëcial çhars!@#\$%^&*()';
      const threshold = 2;
      const totalShards = 3;

      // Act
      final shares = await backupService.generateShamirShares(
        content: specialSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: testVaultName,
        peers: testPeers,
      );

      final reconstructed = await backupService.reconstructFromShares(
        shares: shares.sublist(0, threshold),
      );

      // Assert
      expect(reconstructed, specialSecret);
    });

    test('reconstructFromShares throws with invalid prime modulus', () async {
      // Arrange
      const threshold = 2;
      const totalShards = 3;

      // Generate valid shares first
      final validShares = await backupService.generateShamirShares(
        content: testSecret,
        threshold: threshold,
        totalShards: totalShards,
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: testVaultName,
        peers: testPeers,
      );

      // Create tampered shares with an invalid prime modulus
      const invalidPrimeMod = 'aW52YWxpZFByaW1lTW9kdWx1cw=='; // "invalidPrimeModulus" in base64

      // Create tampered shares with an invalid prime modulus
      final tamperedShares = validShares.map((share) {
        return copyShardData(
          share,
          primeMod: invalidPrimeMod, // Replace with invalid prime
        );
      }).toList();

      // Act & Assert
      expect(
        () => backupService.reconstructFromShares(shares: tamperedShares),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid prime modulus'),
          ),
        ),
      );
    });
  });
}
