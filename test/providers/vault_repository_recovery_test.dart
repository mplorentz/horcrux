import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';

import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

class _MockLoginService extends Mock implements LoginService {}

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

    test(
      'archiveActiveRecoverySessionsInitiatedBy archives active sessions and clears share payloads',
      () async {
        final fixture = await RecoverySessionFixture.inProgress(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          initiatorPubkey: TestHexPubkeys.alice,
          participantPubkeys: const [TestHexPubkeys.bob],
          threshold: 1,
        );
        await fixture.withResponse(
          responderPubkey: TestHexPubkeys.bob,
          approved: true,
          sharePayload: '{"shard":"secret"}',
        );

        await repository.archiveActiveRecoverySessionsInitiatedBy(TestHexPubkeys.alice);

        final requestRow = await db.recoveryDao.getById(fixture.requestId);
        expect(requestRow, isNotNull);
        expect(requestRow!.status, RecoveryRequestStatus.archived.name);
        expect(requestRow.completedAt, isNotNull);

        final responses = await db.recoveryDao.responsesFor(fixture.requestId);
        expect(responses, hasLength(1));
        expect(responses.single.sharePayload, isEmpty);
      },
    );

    test(
      'archiveActiveRecoverySessionsInitiatedBy leaves other-initiator sessions active',
      () async {
        final initiatedByAlice = await RecoverySessionFixture.inProgress(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          initiatorPubkey: TestHexPubkeys.alice,
          participantPubkeys: const [TestHexPubkeys.bob],
          threshold: 1,
        );
        final initiatedByBob = await RecoverySessionFixture.inProgress(
          db,
          vaultId: initiatedByAlice.vaultId,
          ownerPubkey: TestHexPubkeys.alice,
          initiatorPubkey: TestHexPubkeys.bob,
          participantPubkeys: const [TestHexPubkeys.alice],
          threshold: 1,
        );

        await repository.archiveActiveRecoverySessionsInitiatedBy(TestHexPubkeys.alice);

        final rowAlice = await db.recoveryDao.getById(initiatedByAlice.requestId);
        expect(rowAlice!.status, RecoveryRequestStatus.archived.name);

        final rowBobInit = await db.recoveryDao.getById(initiatedByBob.requestId);
        expect(rowBobInit!.status, RecoveryRequestStatus.inProgress.name);
      },
    );

    test(
      'archiveActiveRecoverySessionsInitiatedBy does not alter completed sessions',
      () async {
        final fixture = await RecoverySessionFixture.inProgress(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          initiatorPubkey: TestHexPubkeys.alice,
          participantPubkeys: const [TestHexPubkeys.bob],
          threshold: 1,
        );
        final vault = await repository.getVault(fixture.vaultId);
        final request = vault!.recoveryRequests.firstWhere((r) => r.id == fixture.requestId);
        await repository.updateRecoveryRequestInVault(
          fixture.vaultId,
          fixture.requestId,
          request.copyWith(status: RecoveryRequestStatus.completed),
        );

        await repository.archiveActiveRecoverySessionsInitiatedBy(TestHexPubkeys.alice);

        final row = await db.recoveryDao.getById(fixture.requestId);
        expect(row!.status, RecoveryRequestStatus.completed.name);
      },
    );
  });
}
