import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';

class _MockLoginService extends Mock implements LoginService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultRepository archival persistence', () {
    late VaultRepository repository;

    setUp(() {
      repository = VaultRepository(_MockLoginService());
    });

    tearDown(() => repository.dispose());

    test('archivedAt persists and reloads as archived', () async {
      const ownerPubkey = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final vault = Vault(
        id: 'vault-archive-1',
        name: 'Test',
        content: null,
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: ownerPubkey,
        archivedAt: DateTime(2024, 2, 1),
        archivedReason: 'user hid',
        pushEnabled: false,
      );

      await repository.addVault(vault);
      final loaded = await repository.getVault(vault.id);

      expect(loaded, isNotNull);
      expect(loaded!.isArchived, isTrue);
      expect(loaded.archivedAt, DateTime(2024, 2, 1));
      expect(loaded.archivedReason, 'user hid');
    });

    test('clearing archivedAt clears archive columns on persist', () async {
      const ownerPubkey = 'b0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final vault = Vault(
        id: 'vault-unarchive-1',
        name: 'Test',
        content: null,
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: ownerPubkey,
        archivedAt: DateTime(2024, 6, 15),
        archivedReason: 'should not survive',
        pushEnabled: false,
      );

      await repository.addVault(vault);
      final stored = await repository.getVault(vault.id);
      await repository.saveVault(
        stored!.copyWith(
          archivedAt: null,
          archivedReason: null,
        ),
      );
      final loaded = await repository.getVault(vault.id);

      expect(loaded, isNotNull);
      expect(loaded!.isArchived, isFalse);
      expect(loaded.archivedAt, isNull);
      expect(loaded.archivedReason, isNull);
    });
  });
}
