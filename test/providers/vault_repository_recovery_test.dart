import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/notification_recency.dart';

import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

class _MockLoginService extends Mock implements LoginService {}

/// [LoginService] that only implements [getCurrentPublicKey]; other methods use [Mock]'s noSuchMethod.
class _LoginServiceWithPubkey extends Mock implements LoginService {
  _LoginServiceWithPubkey(this._pubkey);
  final String? _pubkey;

  @override
  Future<String?> getCurrentPublicKey() async => _pubkey;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultRepository recovery request persistence', () {
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

    test('addRecoveryRequestToVault writes request and participant rows', () async {
      final vault = await VaultFixture.stewarded(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        threshold: 2,
        totalShares: 3,
      );
      final participants = <String>[
        TestHexPubkeys.bob,
        TestHexPubkeys.charlie,
        TestHexPubkeys.diana,
      ];
      final request = RecoveryRequest.makeFromParticipants(
        id: 'req-add-1',
        vaultId: vault.vaultId,
        initiatorPubkey: TestHexPubkeys.alice,
        requestedAt: DateTime.now(),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: participants,
      );

      await repository.addRecoveryRequestToVault(vault.vaultId, request);

      final requestRow = await db.recoveryDao.getById(request.id);
      expect(requestRow, isNotNull);
      expect(requestRow!.status, RecoveryRequestStatus.inProgress.name);
      expect(requestRow.thresholdAtStart, 2);

      final participantRows = await db.recoveryDao.participantsFor(request.id);
      expect(participantRows, hasLength(3));
      expect(participantRows.map((p) => p.pubkey).toSet(), equals(participants.toSet()));
    });

    test('updateRecoveryRequestInVault stores only resolved steward responses', () async {
      final fixture = await RecoverySessionFixture.inProgress(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        initiatorPubkey: TestHexPubkeys.alice,
        participantPubkeys: const [
          TestHexPubkeys.bob,
          TestHexPubkeys.charlie,
          TestHexPubkeys.diana,
        ],
        threshold: 2,
      );
      final now = DateTime.now();
      final approvedShare = createShare(
        payload: 'approved-shard-payload',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        primeMod: 'fixture-prime-mod',
        creatorPubkey: TestHexPubkeys.alice,
        vaultId: fixture.vaultId,
      );
      final updatedRequest = RecoveryRequest.makeFromParticipants(
        id: fixture.requestId,
        vaultId: fixture.vaultId,
        initiatorPubkey: fixture.initiatorPubkey,
        requestedAt: DateTime.fromMillisecondsSinceEpoch(fixture.startedAtMs),
        status: RecoveryRequestStatus.inProgress,
        threshold: fixture.threshold,
        stewardPubkeys: const [
          TestHexPubkeys.bob,
          TestHexPubkeys.charlie,
          TestHexPubkeys.diana,
        ],
        responses: [
          RecoveryResponse(
            pubkey: TestHexPubkeys.bob,
            approved: true,
            respondedAt: now,
            share: approvedShare,
            nostrEventId: 'resp_evt_bob',
          ),
          RecoveryResponse(
            pubkey: TestHexPubkeys.charlie,
            approved: false,
            respondedAt: now,
            nostrEventId: 'resp_evt_charlie',
          ),
          const RecoveryResponse(
            pubkey: TestHexPubkeys.diana,
            approved: false,
          ),
        ],
      );

      await repository.updateRecoveryRequestInVault(
        fixture.vaultId,
        fixture.requestId,
        updatedRequest,
      );

      final rows = await db.recoveryDao.responsesFor(fixture.requestId);
      expect(rows, hasLength(2));
      final byPubkey = {for (final row in rows) row.responderPubkey: row};
      expect(byPubkey.containsKey(TestHexPubkeys.bob), isTrue);
      expect(byPubkey.containsKey(TestHexPubkeys.charlie), isTrue);
      expect(byPubkey.containsKey(TestHexPubkeys.diana), isFalse);
      expect(byPubkey[TestHexPubkeys.bob]!.approved, isTrue);
      expect(byPubkey[TestHexPubkeys.charlie]!.approved, isFalse);
      expect(byPubkey[TestHexPubkeys.charlie]!.sharePayload, isEmpty);

      final bobPayload = jsonDecode(byPubkey[TestHexPubkeys.bob]!.sharePayload);
      expect(bobPayload['shard'], equals('approved-shard-payload'));
    });

    test('cleanupExpiredRecoverySessions marks expired requests failed and clears responses',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fixture = await RecoverySessionFixture.inProgress(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        initiatorPubkey: TestHexPubkeys.alice,
        participantPubkeys: const [
          TestHexPubkeys.bob,
          TestHexPubkeys.charlie,
        ],
        threshold: 2,
        startedAtMs: now - const Duration(hours: 2).inMilliseconds,
        expiresAtMs: now - const Duration(minutes: 5).inMilliseconds,
      );
      await fixture.withResponse(
        responderPubkey: TestHexPubkeys.bob,
        approved: true,
        sharePayload: '{"shard":"s1"}',
      );
      await fixture.withResponse(
        responderPubkey: TestHexPubkeys.charlie,
        approved: false,
      );

      await repository.cleanupExpiredRecoverySessions();

      final requestRow = await db.recoveryDao.getById(fixture.requestId);
      expect(requestRow, isNotNull);
      expect(requestRow!.status, RecoveryRequestStatus.failed.name);
      expect(requestRow.errorMessage, 'Recovery session expired');
      expect(requestRow.completedAt, isNotNull);

      final responses = await db.recoveryDao.responsesFor(fixture.requestId);
      expect(responses, isEmpty);
    });

    test('cleanupExpiredRecoverySessions leaves non-expired requests untouched', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fixture = await RecoverySessionFixture.inProgress(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        initiatorPubkey: TestHexPubkeys.alice,
        participantPubkeys: const [TestHexPubkeys.bob],
        threshold: 1,
        startedAtMs: now - const Duration(minutes: 10).inMilliseconds,
        expiresAtMs: now + const Duration(hours: 1).inMilliseconds,
      );
      await fixture.withResponse(
        responderPubkey: TestHexPubkeys.bob,
        approved: true,
        sharePayload: '{"shard":"still-there"}',
      );

      await repository.cleanupExpiredRecoverySessions();

      final requestRow = await db.recoveryDao.getById(fixture.requestId);
      expect(requestRow, isNotNull);
      expect(requestRow!.status, RecoveryRequestStatus.inProgress.name);

      final responses = await db.recoveryDao.responsesFor(fixture.requestId);
      expect(responses, hasLength(1));
      expect(responses.single.sharePayload, contains('still-there'));
    });
  });

  group('addRecoveryRequestToVault recency gate', () {
    late AppDatabase db;
    late VaultRepository repository;

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    test('drops self-initiated request when eventCreationTime predates first app open', () async {
      db = newTestDatabase();
      repository = VaultRepository(_LoginServiceWithPubkey(TestHexPubkeys.alice), db: db);
      final vault = await VaultFixture.stewarded(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        threshold: 2,
        totalShares: 3,
      );
      final firstOpen = DateTime.utc(2024, 6, 1, 12, 0, 0);
      await db.appStateDao.setInt(
        key: firstAppOpenUtcKey,
        value: firstOpen.millisecondsSinceEpoch,
      );

      final request = RecoveryRequest.makeFromParticipants(
        id: 'req-stale-self',
        vaultId: vault.vaultId,
        initiatorPubkey: TestHexPubkeys.alice,
        requestedAt: DateTime.utc(2024, 5, 15, 12, 0, 0),
        eventCreationTime: DateTime.utc(2024, 5, 10, 12, 0, 0),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: const [TestHexPubkeys.bob, TestHexPubkeys.charlie],
      );

      await repository.addRecoveryRequestToVault(vault.vaultId, request);

      expect(await db.recoveryDao.getById(request.id), isNull);
    });

    test('persists self-initiated request when eventCreationTime is after first app open',
        () async {
      db = newTestDatabase();
      repository = VaultRepository(_LoginServiceWithPubkey(TestHexPubkeys.alice), db: db);
      final vault = await VaultFixture.stewarded(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        threshold: 2,
        totalShares: 3,
      );
      final firstOpen = DateTime.utc(2024, 6, 1, 12, 0, 0);
      await db.appStateDao.setInt(
        key: firstAppOpenUtcKey,
        value: firstOpen.millisecondsSinceEpoch,
      );

      final request = RecoveryRequest.makeFromParticipants(
        id: 'req-recent-self',
        vaultId: vault.vaultId,
        initiatorPubkey: TestHexPubkeys.alice,
        requestedAt: DateTime.utc(2024, 6, 15, 12, 0, 0),
        eventCreationTime: DateTime.utc(2024, 6, 15, 12, 0, 0),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: const [TestHexPubkeys.bob, TestHexPubkeys.charlie],
      );

      await repository.addRecoveryRequestToVault(vault.vaultId, request);

      final row = await db.recoveryDao.getById(request.id);
      expect(row, isNotNull);
      expect(row!.initiatorPubkey, TestHexPubkeys.alice);
    });

    test('persists self-initiated request when eventCreationTime is null (local create path)',
        () async {
      db = newTestDatabase();
      repository = VaultRepository(_LoginServiceWithPubkey(TestHexPubkeys.alice), db: db);
      final vault = await VaultFixture.stewarded(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        threshold: 2,
        totalShares: 3,
      );
      final firstOpen = DateTime.utc(2024, 6, 1, 12, 0, 0);
      await db.appStateDao.setInt(
        key: firstAppOpenUtcKey,
        value: firstOpen.millisecondsSinceEpoch,
      );

      final request = RecoveryRequest.makeFromParticipants(
        id: 'req-local-self',
        vaultId: vault.vaultId,
        initiatorPubkey: TestHexPubkeys.alice,
        requestedAt: DateTime.utc(2024, 1, 1, 12, 0, 0),
        status: RecoveryRequestStatus.pending,
        threshold: 2,
        stewardPubkeys: const [TestHexPubkeys.bob, TestHexPubkeys.charlie],
      );

      await repository.addRecoveryRequestToVault(vault.vaultId, request);

      final row = await db.recoveryDao.getById(request.id);
      expect(row, isNotNull);
      expect(row!.status, RecoveryRequestStatus.pending.name);
    });

    test('persists other-initiator request even when event predates first app open', () async {
      db = newTestDatabase();
      repository = VaultRepository(_LoginServiceWithPubkey(TestHexPubkeys.alice), db: db);
      final vault = await VaultFixture.stewarded(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        threshold: 2,
        totalShares: 3,
      );
      final firstOpen = DateTime.utc(2024, 6, 1, 12, 0, 0);
      await db.appStateDao.setInt(
        key: firstAppOpenUtcKey,
        value: firstOpen.millisecondsSinceEpoch,
      );

      final request = RecoveryRequest.makeFromParticipants(
        id: 'req-other-stale',
        vaultId: vault.vaultId,
        initiatorPubkey: TestHexPubkeys.bob,
        requestedAt: DateTime.utc(2024, 5, 15, 12, 0, 0),
        eventCreationTime: DateTime.utc(2024, 5, 10, 12, 0, 0),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: const [TestHexPubkeys.alice, TestHexPubkeys.charlie],
      );

      await repository.addRecoveryRequestToVault(vault.vaultId, request);

      final row = await db.recoveryDao.getById(request.id);
      expect(row, isNotNull);
      expect(row!.initiatorPubkey, TestHexPubkeys.bob);
    });
  });
}
