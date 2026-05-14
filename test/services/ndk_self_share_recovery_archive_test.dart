import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/database/app_database_provider.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:ndk/ndk.dart';

import '../helpers/secure_storage_mock.dart';
import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();

  setUpAll(() {
    secureStorageMock.setUpAll();
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
  });

  group('NdkService archives self-initiated recovery when processing own 1337', () {
    late AppDatabase db;
    late LoginService loginService;
    late ProviderContainer container;

    setUp(() async {
      secureStorageMock.clear();
      loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();
      await loginService.generateAndStoreNostrKey();

      db = newTestDatabase();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          loginServiceProvider.overrideWithValue(loginService),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('archives active sessions when inner share pubkey is the logged-in user', () async {
      final pubkey = (await loginService.getStoredNostrKey())!.publicKey;

      final fixture = await RecoverySessionFixture.inProgress(
        db,
        ownerPubkey: pubkey,
        initiatorPubkey: pubkey,
        participantPubkeys: const [
          'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
          'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
        ],
        threshold: 2,
      );

      final inner = Nip01Event(
        pubKey: pubkey,
        kind: 1337,
        tags: const [],
        createdAt: 1700000000,
        content: '{"vault_id":"${fixture.vaultId}","payload":"","threshold":2,'
            '"share_index":0,"total_shares":3,"prime_mod":"p","creator_pubkey":"$pubkey",'
            '"created_at":1700000000}',
      )..id = 'inner-share-1';

      final ndk = container.read(ndkServiceProvider);
      await ndk.archiveSelfInitiatedRecoveriesWhenProcessingOwnShareForTesting(inner);

      final row = await db.recoveryDao.getById(fixture.requestId);
      expect(row, isNotNull);
      expect(row!.status, RecoveryRequestStatus.archived.name);
    });

    test('does not archive when inner share is from another user', () async {
      final pubkey = (await loginService.getStoredNostrKey())!.publicKey;
      const other = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

      final fixture = await RecoverySessionFixture.inProgress(
        db,
        ownerPubkey: pubkey,
        initiatorPubkey: pubkey,
        participantPubkeys: const [
          'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
          'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
        ],
        threshold: 2,
      );

      final inner = Nip01Event(
        pubKey: other,
        kind: 1337,
        tags: const [],
        createdAt: 1700000000,
        content: '{"vault_id":"${fixture.vaultId}","payload":"x","threshold":2,'
            '"share_index":0,"total_shares":3,"prime_mod":"p","creator_pubkey":"$other",'
            '"created_at":1700000000}',
      )..id = 'inner-share-peer';

      final ndk = container.read(ndkServiceProvider);
      await ndk.archiveSelfInitiatedRecoveriesWhenProcessingOwnShareForTesting(inner);

      final row = await db.recoveryDao.getById(fixture.requestId);
      expect(row, isNotNull);
      expect(row!.status, RecoveryRequestStatus.inProgress.name);
    });
  });
}
