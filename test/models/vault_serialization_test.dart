import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/vault.dart';

void main() {
  const ownerHex = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';

  Vault baseVault({bool? pushEnabled}) => Vault(
        id: 'v1',
        name: 'My Vault',
        createdAt: DateTime.utc(2026, 4, 21, 12, 0, 0),
        ownerPubkey: ownerHex,
        // Intentionally omit `pushEnabled` in the `null` case to exercise the
        // model's default.
        pushEnabled: pushEnabled ?? true,
      );

  group('Vault.pushEnabled', () {
    test('defaults to true on new vaults', () {
      final vault = Vault(
        id: 'v1',
        name: 'My Vault',
        createdAt: DateTime.utc(2026, 4, 21),
        ownerPubkey: ownerHex,
      );
      expect(vault.pushEnabled, isTrue);
    });

    test('toJson emits pushEnabled', () {
      final vault = baseVault(pushEnabled: false);
      final json = vault.toJson();
      expect(json['pushEnabled'], isFalse);
    });

    test('round-trips through toJson/fromJson preserving false', () {
      final vault = baseVault(pushEnabled: false);
      final decoded = Vault.fromJson(vault.toJson());
      expect(decoded.pushEnabled, isFalse);
    });

    test('round-trips through toJson/fromJson preserving true', () {
      final vault = baseVault(pushEnabled: true);
      final decoded = Vault.fromJson(vault.toJson());
      expect(decoded.pushEnabled, isTrue);
    });

    test('legacy JSON without pushEnabled reads back as false', () {
      // Legacy vaults predate this field. The owner's metadata is what
      // leaks to the notifier, so we never flip push on without their
      // explicit say-so -- legacy vaults stay opted-out.
      final legacyJson = <String, dynamic>{
        'id': 'legacy-1',
        'name': 'Legacy Vault',
        'content': null,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'ownerPubkey': ownerHex,
        'shards': [],
        'recoveryRequests': [],
        'backupConfig': null,
        'isArchived': false,
        // pushEnabled intentionally absent
      };
      final vault = Vault.fromJson(legacyJson);
      expect(vault.pushEnabled, isFalse);
    });

    test('copyWith toggles pushEnabled independently of other fields', () {
      final vault = baseVault(pushEnabled: true);
      final toggled = vault.copyWith(pushEnabled: false);
      expect(toggled.pushEnabled, isFalse);
      expect(toggled.id, vault.id);
      expect(toggled.name, vault.name);
    });
  });
}
