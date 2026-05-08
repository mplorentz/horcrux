import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';

class _MockLoginService extends Mock implements LoginService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultRepository vaultsStream', () {
    late AppDatabase db;
    VaultRepository? repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      repository?.dispose();
      await db.close();
    });

    test('first emission waits for the hydrated database snapshot', () async {
      const ownerPubkey = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final vault = Vault(
        id: 'vault-stream-1',
        name: 'Seeded vault',
        content: 'secret',
        createdAt: DateTime(2026, 1, 1),
        ownerPubkey: ownerPubkey,
      );
      final seedRepository = VaultRepository(_MockLoginService(), db: db);
      await seedRepository.addVault(vault);
      seedRepository.dispose();

      repository = VaultRepository(_MockLoginService(), db: db);

      final firstEmission = await repository!.vaultsStream.first;

      expect(firstEmission.map((v) => v.id), [vault.id]);
    });
  });
}
