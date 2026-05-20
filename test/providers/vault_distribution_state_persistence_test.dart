import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_detail_repository.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';

import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

class _MockLoginService extends Mock implements LoginService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('distribution state persistence', () {
    late AppDatabase db;
    late VaultRepository repository;

    setUp(() {
      db = newTestDatabase();
      repository = VaultRepository(_MockLoginService(), db: db);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    const vaultId = 'vault-dist-state';
    const ownerPubkey = TestHexPubkeys.alice;
    const stewardPubkey = TestHexPubkeys.bob;

    Future<BackupConfig> seedBackupConfig() async {
      final steward = createSteward(pubkey: stewardPubkey, name: 'Bob');
      final config = createBackupConfig(
        vaultId: vaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: const ['wss://relay.example.com'],
      ).copyWith(distributionVersion: 1);

      await repository.addVault(
        Vault(
          id: vaultId,
          name: 'Distribution State Vault',
          createdAt: DateTime.utc(2026, 5, 11, 16, 0),
          ownerPubkey: ownerPubkey,
          backupConfig: config,
          pushEnabled: true,
        ),
      );

      return config;
    }

    test('VaultRepository rehydrates steward holdingKey from persisted ack rows', () async {
      final seededConfig = await seedBackupConfig();
      final acknowledgedAt = DateTime.utc(2026, 5, 11, 16, 1, 2);

      await repository.updateStewardStatus(
        vaultId: vaultId,
        pubkey: stewardPubkey,
        acknowledgedAt: acknowledgedAt,
        acknowledgmentEventId: 'ack-event-1',
        acknowledgedDistributionVersion: 1,
        giftWrapEventId: 'gift-wrap-event-1',
      );

      final distribution = await db.distributionDao.latestForVault(vaultId);
      expect(distribution, isNotNull);
      expect(distribution!.version, seededConfig.distributionVersion);
      final distributionShareRows = await db.distributionDao.sharesFor(distribution.id);
      expect(distributionShareRows, hasLength(1));
      expect(distributionShareRows.single.acknowledgmentEventId, 'ack-event-1');
      expect(distributionShareRows.single.giftWrapEventId, 'gift-wrap-event-1');

      repository.dispose();
      repository = VaultRepository(_MockLoginService(), db: db);

      final hydratedVault = await repository.getVault(vaultId);
      final hydratedConfig = hydratedVault!.backupConfig!;
      final hydratedSteward = hydratedConfig.stewards.single;

      expect(hydratedSteward.status, StewardStatus.holdingKey);
      expect(hydratedSteward.giftWrapEventId, 'gift-wrap-event-1');
      expect(hydratedSteward.acknowledgmentEventId, 'ack-event-1');
      expect(hydratedSteward.acknowledgedDistributionVersion, 1);
      expect(
        hydratedSteward.acknowledgedAt?.millisecondsSinceEpoch,
        acknowledgedAt.millisecondsSinceEpoch,
      );
      expect(hydratedConfig.isReady, isTrue);
    });

    test('VaultDetailRepository sees persisted steward acknowledgment state', () async {
      await seedBackupConfig();
      final acknowledgedAt = DateTime.utc(2026, 5, 11, 16, 2, 3);

      await repository.updateStewardStatus(
        vaultId: vaultId,
        pubkey: stewardPubkey,
        acknowledgedAt: acknowledgedAt,
        acknowledgmentEventId: 'ack-event-2',
        acknowledgedDistributionVersion: 1,
        giftWrapEventId: 'gift-wrap-event-2',
      );

      final detailRepository = VaultDetailRepository(db: db);
      addTearDown(detailRepository.dispose);

      final detail = await detailRepository.getVaultDetail(vaultId);
      final backupConfig = detail!.backupConfig!;
      final steward = backupConfig.stewards.single;

      expect(steward.status, StewardStatus.holdingKey);
      expect(steward.acknowledgmentEventId, 'ack-event-2');
      expect(steward.giftWrapEventId, 'gift-wrap-event-2');
      expect(steward.acknowledgedDistributionVersion, 1);
      expect(
        steward.acknowledgedAt?.millisecondsSinceEpoch,
        acknowledgedAt.millisecondsSinceEpoch,
      );
      expect(backupConfig.isReady, isTrue);
    });
  });
}
