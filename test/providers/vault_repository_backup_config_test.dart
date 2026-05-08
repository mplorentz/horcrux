import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';

class _MockLoginService extends Mock implements LoginService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultRepository backupConfig removal', () {
    late VaultRepository repository;
    const ownerPubkey = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';

    setUp(() {
      repository = VaultRepository(_MockLoginService());
    });

    tearDown(() => repository.dispose());

    test('persisting null backupConfig clears stewards so hydration has no config', () async {
      final steward = createSteward(
        pubkey: 'b0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
        name: 'S',
      );
      final config = createBackupConfig(
        vaultId: 'vault-del-bc',
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: const ['wss://relay.example.com'],
      );
      final created = DateTime.utc(2025, 1, 1);
      final withConfig = Vault(
        id: 'vault-del-bc',
        name: 'V',
        content: 'secret',
        createdAt: created,
        ownerPubkey: ownerPubkey,
        backupConfig: config,
        pushEnabled: true,
      );
      await repository.addVault(withConfig);
      final loadedWith = await repository.getVault('vault-del-bc');
      expect(loadedWith!.backupConfig, isNotNull);
      expect(loadedWith.backupConfig!.stewards, hasLength(1));

      await repository.saveVault(loadedWith.copyWith(backupConfig: null));
      final loadedWithout = await repository.getVault('vault-del-bc');
      expect(loadedWithout!.backupConfig, isNull);
    });
  });
}
