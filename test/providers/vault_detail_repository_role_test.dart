import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/providers/vault_detail_repository.dart';
import 'package:horcrux/services/login_service.dart';

import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

class _PubkeyLoginService extends Fake implements LoginService {
  _PubkeyLoginService(this._hexPubkey);

  final String? _hexPubkey;

  @override
  Future<String?> getCurrentPublicKey() async => _hexPubkey;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultDetailRepository device role', () {
    late AppDatabase db;

    setUp(() {
      db = newTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'stale owned_vaults when logged-in pubkey != vault owner yields StewardedVaultDetail',
      () async {
        final fx = await VaultFixture.stewarded(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          threshold: 1,
          totalShares: 2,
        );
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.into(db.ownedVaults).insert(
              OwnedVaultsCompanion.insert(
                vaultId: fx.vaultId,
                content: 'stale-ciphertext',
                contentHmac: Uint8List(32),
                createdBySelfAt: now,
              ),
            );
        await fx.withSteward(
          shareIndex: 1,
          pubkey: TestHexPubkeys.bob,
          name: 'Bob',
        );
        final login = _PubkeyLoginService(TestHexPubkeys.bob);

        final repo = VaultDetailRepository(db: db, loginService: login);
        addTearDown(repo.dispose);

        final detail = await repo.getVaultDetail(fx.vaultId);
        expect(detail, isA<StewardedVaultDetail>());
        expect(detail!.ownerPubkey, TestHexPubkeys.alice);
        expect(detail.stewards, hasLength(1));
        expect(detail.stewards.single.pubkey, TestHexPubkeys.bob);
      },
    );

    test(
      'owned vault with LoginService matching owner yields OwnedVaultDetail',
      () async {
        final fx = await VaultFixture.owned(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          threshold: 1,
          totalShares: 1,
        );
        await fx.withSteward(
          shareIndex: 1,
          pubkey: TestHexPubkeys.alice,
          isOwner: true,
          name: 'Alice',
        );
        final login = _PubkeyLoginService(TestHexPubkeys.alice);

        final repo = VaultDetailRepository(db: db, loginService: login);
        addTearDown(repo.dispose);

        final detail = await repo.getVaultDetail(fx.vaultId);
        expect(detail, isA<OwnedVaultDetail>());
        expect(detail!.ownerPubkey, TestHexPubkeys.alice);
      },
    );

    test(
      'without LoginService, owned_vaults alone yields OwnedVaultDetail (legacy)',
      () async {
        final fx = await VaultFixture.owned(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          threshold: 1,
          totalShares: 1,
        );

        final repo = VaultDetailRepository(db: db);
        addTearDown(repo.dispose);

        final detail = await repo.getVaultDetail(fx.vaultId);
        expect(detail, isA<OwnedVaultDetail>());
      },
    );

    test(
      'hydrates active recovery requests so manageableRecoveryFor returns them',
      () async {
        final fx = await VaultFixture.stewarded(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          threshold: 2,
          totalShares: 3,
        );
        await fx.withSteward(
          shareIndex: 1,
          pubkey: TestHexPubkeys.bob,
          name: 'Bob',
        );
        await HeldShareFixture.insert(
          db,
          vaultId: fx.vaultId,
          shareIndex: 1,
          payload: 'p',
        );
        final session = await RecoverySessionFixture.inProgress(
          db,
          vaultId: fx.vaultId,
          ownerPubkey: TestHexPubkeys.alice,
          initiatorPubkey: TestHexPubkeys.bob,
          threshold: 2,
        );

        final repo = VaultDetailRepository(
          db: db,
          loginService: _PubkeyLoginService(TestHexPubkeys.bob),
        );
        addTearDown(repo.dispose);

        final detail = await repo.getVaultDetail(fx.vaultId);
        expect(detail!.recoveryRequests, hasLength(1));
        expect(detail.recoveryRequests.single.id, session.requestId);
        expect(detail.recoveryRequests.single.status.isActive, isTrue);
        expect(
          detail.manageableRecoveryFor(TestHexPubkeys.bob, isPractice: false),
          isNotNull,
        );
      },
    );

    test(
      'hydrates recovery for OwnedVaultDetail when owner initiated',
      () async {
        final fx = await VaultFixture.owned(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          threshold: 2,
          totalShares: 3,
        );
        await fx.withSteward(
          shareIndex: 1,
          pubkey: TestHexPubkeys.alice,
          isOwner: true,
          name: 'Alice',
        );
        await RecoverySessionFixture.inProgress(
          db,
          vaultId: fx.vaultId,
          ownerPubkey: TestHexPubkeys.alice,
          initiatorPubkey: TestHexPubkeys.alice,
          threshold: 2,
        );

        final repo = VaultDetailRepository(
          db: db,
          loginService: _PubkeyLoginService(TestHexPubkeys.alice),
        );
        addTearDown(repo.dispose);

        final detail = await repo.getVaultDetail(fx.vaultId);
        expect(detail, isA<OwnedVaultDetail>());
        expect(detail!.recoveryRequests, hasLength(1));
        expect(
          detail.manageableRecoveryFor(TestHexPubkeys.alice, isPractice: false),
          isNotNull,
        );
      },
    );

    test(
      'watchVaultDetail re-emits when a recovery request row is inserted',
      () async {
        final fx = await VaultFixture.stewarded(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          threshold: 2,
          totalShares: 3,
        );
        await fx.withSteward(
          shareIndex: 1,
          pubkey: TestHexPubkeys.bob,
          name: 'Bob',
        );
        await HeldShareFixture.insert(
          db,
          vaultId: fx.vaultId,
          shareIndex: 1,
          payload: 'p',
        );

        final repo = VaultDetailRepository(
          db: db,
          loginService: _PubkeyLoginService(TestHexPubkeys.bob),
        );
        addTearDown(repo.dispose);

        final stream = repo.watchVaultDetail(fx.vaultId);
        final first = await stream.first;
        expect(first, isNotNull);
        expect(first!.recoveryRequests, isEmpty);

        await RecoverySessionFixture.inProgress(
          db,
          vaultId: fx.vaultId,
          ownerPubkey: TestHexPubkeys.alice,
          initiatorPubkey: TestHexPubkeys.bob,
          threshold: 2,
        );

        final second = await stream.skip(1).first;
        expect(second, isNotNull);
        expect(second!.recoveryRequests, hasLength(1));
      },
    );
  });
}
