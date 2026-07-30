import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/key_holder_removal_reason.dart';
import 'package:horcrux/models/relay_configuration.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/account_deletion_service.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/invitation_sending_service.dart';
import 'package:horcrux/services/logout_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/publish_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'account_deletion_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<NdkService>(),
  MockSpec<PublishService>(),
  MockSpec<RelayScanService>(),
  MockSpec<HorcruxNotificationService>(),
  MockSpec<LogoutService>(),
  MockSpec<VaultRepository>(),
  MockSpec<InvitationSendingService>(),
])
void main() {
  group('AccountDeletionService', () {
    late MockNdkService ndkService;
    late MockPublishService publishService;
    late MockRelayScanService relayScanService;
    late MockHorcruxNotificationService notificationService;
    late MockLogoutService logoutService;
    late MockVaultRepository vaultRepository;
    late MockInvitationSendingService invitationSendingService;
    late AccountDeletionService service;

    final relays = [
      const RelayConfiguration(id: 'r1', url: 'wss://relay.one', name: 'relay.one'),
      const RelayConfiguration(id: 'r2', url: 'wss://relay.two', name: 'relay.two'),
    ];

    /// Builds a fake [PublishBroadcastHandle] whose `done` future resolves
    /// only after [statusEvents] (if any) have all been emitted on
    /// `statusUpdates`, mirroring how `ndk`'s real `broadcastDoneFuture` is
    /// derived from `broadcastDone.last`. Events are emitted from a macrotask
    /// (scheduled via the `Future(...)` constructor) so that
    /// `AccountDeletionService.deleteAccount`'s `statusUpdates.listen(...)`
    /// call -- which happens synchronously once it awaits this handle -- is
    /// always attached before the first event fires.
    PublishBroadcastHandle handleFor(
      List<String> relayUrls,
      Set<String> acknowledged, {
      List<List<RelayPublishStatus>> statusEvents = const [],
    }) {
      final controller = StreamController<List<RelayPublishStatus>>.broadcast();
      final doneCompleter = Completer<Set<String>>();
      Future<void>(() async {
        for (final event in statusEvents) {
          controller.add(event);
        }
        await controller.close();
        doneCompleter.complete(acknowledged);
      });
      return PublishBroadcastHandle(
        relayUrls: relayUrls,
        statusUpdates: controller.stream,
        done: doneCompleter.future,
      );
    }

    setUp(() {
      ndkService = MockNdkService();
      publishService = MockPublishService();
      relayScanService = MockRelayScanService();
      notificationService = MockHorcruxNotificationService();
      logoutService = MockLogoutService();
      vaultRepository = MockVaultRepository();
      invitationSendingService = MockInvitationSendingService();
      service = AccountDeletionService(
        ndkService: ndkService,
        relayScanService: relayScanService,
        notificationService: notificationService,
        logoutService: logoutService,
        vaultRepository: vaultRepository,
        invitationSendingService: invitationSendingService,
      );

      when(ndkService.publishService).thenReturn(publishService);
      when(ndkService.getCurrentPubkey()).thenAnswer((_) async => 'test-pubkey');
      when(
        relayScanService.getRelayConfigurations(enabledOnly: true),
      ).thenAnswer((_) async => relays);
      when(notificationService.deregister()).thenAnswer((_) async {});
      when(logoutService.logout()).thenAnswer((_) async {});
      when(vaultRepository.getAllVaults()).thenAnswer((_) async => []);
      when(invitationSendingService.sendKeyHolderRemovalEvent(
        vaultId: anyNamed('vaultId'),
        removedStewardPubkey: anyNamed('removedStewardPubkey'),
        relayUrls: anyNamed('relayUrls'),
        reason: anyNamed('reason'),
      )).thenAnswer((_) async => 'mock-event-id');
    });

    test('wipes local state when at least one relay acknowledges', () async {
      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor([
          'wss://relay.one',
          'wss://relay.two'
        ], {
          'wss://relay.one',
        }),
      );

      final result = await service.deleteAccount();

      expect(result.relayRequestAcknowledged, isTrue);
      expect(result.relaysAcknowledged, 1);
      expect(result.relaysTotal, 2);
      verify(notificationService.deregister()).called(1);
      verify(logoutService.logout()).called(1);
    });

    test('throws and does nothing when no relays are configured', () async {
      when(
        relayScanService.getRelayConfigurations(enabledOnly: true),
      ).thenAnswer((_) async => []);

      await expectLater(service.deleteAccount(), throwsStateError);

      verifyNever(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      );
      verifyNever(notificationService.deregister());
      verifyNever(logoutService.logout());
    });

    test('does not wipe local state when no relay acknowledges', () async {
      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor(['wss://relay.one', 'wss://relay.two'], {}),
      );

      final result = await service.deleteAccount();

      expect(result.relayRequestAcknowledged, isFalse);
      expect(result.relaysAcknowledged, 0);
      verifyNever(notificationService.deregister());
      verifyNever(logoutService.logout());
    });

    test('forwards live relay status updates via onRelayStatusUpdate', () async {
      const pending = [
        RelayPublishStatus(
          relayUrl: 'wss://relay.one',
          state: RelayPublishAckState.pending,
        ),
        RelayPublishStatus(
          relayUrl: 'wss://relay.two',
          state: RelayPublishAckState.pending,
        ),
      ];
      const settled = [
        RelayPublishStatus(
          relayUrl: 'wss://relay.one',
          state: RelayPublishAckState.acknowledged,
        ),
        RelayPublishStatus(
          relayUrl: 'wss://relay.two',
          state: RelayPublishAckState.failed,
        ),
      ];
      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor(
          ['wss://relay.one', 'wss://relay.two'],
          {'wss://relay.one'},
          statusEvents: [pending, settled],
        ),
      );

      final received = <List<RelayPublishStatus>>[];
      await service.deleteAccount(onRelayStatusUpdate: received.add);

      expect(received, [pending, settled]);
    });

    test('cancels the relay-status subscription even when the broadcast fails', () async {
      final relayUrls = ['wss://relay.one', 'wss://relay.two'];
      final controller = StreamController<List<RelayPublishStatus>>.broadcast();
      final doneCompleter = Completer<Set<String>>();
      // Complete the error from a later task, mirroring handleFor, so the
      // service's `await broadcast.done` is already attached when it fires.
      Future<void>(() => doneCompleter.completeError(Exception('broadcast failed')));
      final handle = PublishBroadcastHandle(
        relayUrls: relayUrls,
        statusUpdates: controller.stream,
        done: doneCompleter.future,
      );
      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer((_) async => handle);

      await expectLater(
        service.deleteAccount(onRelayStatusUpdate: (_) {}),
        throwsException,
      );

      expect(controller.hasListener, isFalse);
      verifyNever(notificationService.deregister());
      verifyNever(logoutService.logout());
    });

    test('still wipes local state when notifier deregister fails', () async {
      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor([
          'wss://relay.one',
          'wss://relay.two'
        ], {
          'wss://relay.one',
        }),
      );
      when(notificationService.deregister()).thenThrow(Exception('network error'));

      final result = await service.deleteAccount();

      expect(result.relayRequestAcknowledged, isTrue);
      verify(logoutService.logout()).called(1);
    });

    test('sends vaultDeleted 721 for owned vaults with active stewards before wiping', () async {
      const vaultId = 'owned-vault-1';
      const stewardPubkey = 'steward-pubkey-abc';
      const anotherVaultId = 'owned-vault-2';
      const anotherStewardPubkey = 'steward-pubkey-xyz';

      const steward = Steward(
        id: 'steward-1',
        pubkey: stewardPubkey,
        name: 'Steward One',
        status: StewardStatus.holdingKey,
      );

      const anotherSteward = Steward(
        id: 'steward-2',
        pubkey: anotherStewardPubkey,
        name: 'Steward Two',
        status: StewardStatus.holdingKey,
      );

      final now = DateTime(2024);
      final config = BackupConfig(
        vaultId: vaultId,
        stewards: [steward],
        threshold: 1,
        createdAt: now,
        relays: ['wss://relay.one'],
        distributionVersion: 1,
      );

      final anotherConfig = BackupConfig(
        vaultId: anotherVaultId,
        stewards: [anotherSteward],
        threshold: 1,
        createdAt: now,
        relays: ['wss://relay.one'],
        distributionVersion: 1,
      );

      final vault1 = Vault(
        id: vaultId,
        name: 'Owned Vault 1',
        createdAt: DateTime(2024),
        ownerPubkey: 'owner-pubkey',
        backupConfig: config,
      );

      final vault2 = Vault(
        id: anotherVaultId,
        name: 'Owned Vault 2',
        createdAt: DateTime(2024),
        ownerPubkey: 'owner-pubkey',
        backupConfig: anotherConfig,
      );

      when(vaultRepository.getAllVaults()).thenAnswer((_) async => [vault1, vault2]);
      when(vaultRepository.isOwnedVault(vaultId)).thenAnswer((_) async => true);
      when(vaultRepository.isOwnedVault(anotherVaultId)).thenAnswer((_) async => true);

      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor([
          'wss://relay.one',
          'wss://relay.two'
        ], {
          'wss://relay.one',
        }),
      );

      final result = await service.deleteAccount();

      // Capture the relayUrls from the first 721 call to verify the
      // union of vault relays and account-vanish relays.
      final capturedRelays = verify(invitationSendingService.sendKeyHolderRemovalEvent(
        vaultId: vaultId,
        removedStewardPubkey: stewardPubkey,
        relayUrls: captureAnyNamed('relayUrls'),
        reason: KeyHolderRemovalReason.vaultDeleted,
      )).captured.cast<List<String>>();
      expect(capturedRelays, hasLength(1));
      // vault config has ['wss://relay.one'], account-vanish relays
      // include 'wss://relay.two', so the union must contain both.
      expect(
        capturedRelays.first,
        containsAll(['wss://relay.one', 'wss://relay.two']),
      );
      // No duplicates
      expect(capturedRelays.first.toSet().length, capturedRelays.first.length);

      // Verify the second 721 was sent
      verify(invitationSendingService.sendKeyHolderRemovalEvent(
        vaultId: anotherVaultId,
        removedStewardPubkey: anotherStewardPubkey,
        relayUrls: anyNamed('relayUrls'),
        reason: KeyHolderRemovalReason.vaultDeleted,
      )).called(1);

      // Verify the wipe still happened (code structure ensures 721s
      // precede logout, as the test name asserts)
      verify(logoutService.logout()).called(1);

      expect(result.relayRequestAcknowledged, isTrue);
    });

    test('includes awaitingNewKey stewards when notifying owned vaults', () async {
      const vaultId = 'owned-vault-awaiting-new-key';
      const holdingStewardPubkey = 'holding-steward-pubkey';
      const awaitingNewStewardPubkey = 'awaiting-new-steward-pubkey';

      const holdingSteward = Steward(
        id: 'steward-hold',
        pubkey: holdingStewardPubkey,
        name: 'Holding Steward',
        status: StewardStatus.holdingKey,
      );

      const awaitingNewSteward = Steward(
        id: 'steward-awaiting',
        pubkey: awaitingNewStewardPubkey,
        name: 'Awaiting New Key Steward',
        status: StewardStatus.awaitingNewKey,
      );

      final now = DateTime(2024);
      final config = BackupConfig(
        vaultId: vaultId,
        stewards: [holdingSteward, awaitingNewSteward],
        threshold: 1,
        createdAt: now,
        relays: ['wss://relay.one'],
        distributionVersion: 2,
      );

      final vault = Vault(
        id: vaultId,
        name: 'Vault with awaitingNewKey steward',
        createdAt: DateTime(2024),
        ownerPubkey: 'owner-pubkey',
        backupConfig: config,
      );

      when(vaultRepository.getAllVaults()).thenAnswer((_) async => [vault]);
      when(vaultRepository.isOwnedVault(vaultId)).thenAnswer((_) async => true);

      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor([
          'wss://relay.one',
          'wss://relay.two'
        ], {
          'wss://relay.one',
        }),
      );

      await service.deleteAccount();

      // Both stewards should receive a 721
      verify(invitationSendingService.sendKeyHolderRemovalEvent(
        vaultId: vaultId,
        removedStewardPubkey: holdingStewardPubkey,
        relayUrls: anyNamed('relayUrls'),
        reason: KeyHolderRemovalReason.vaultDeleted,
      )).called(1);
      verify(invitationSendingService.sendKeyHolderRemovalEvent(
        vaultId: vaultId,
        removedStewardPubkey: awaitingNewStewardPubkey,
        relayUrls: anyNamed('relayUrls'),
        reason: KeyHolderRemovalReason.vaultDeleted,
      )).called(1);

      verify(logoutService.logout()).called(1);
    });

    test('skips vaults without backup config when notifying stewards', () async {
      const vaultId = 'vault-no-config';

      final vault = Vault(
        id: vaultId,
        name: 'No Config',
        createdAt: DateTime(2024),
        ownerPubkey: 'owner-pubkey',
        backupConfig: null,
      );

      when(vaultRepository.getAllVaults()).thenAnswer((_) async => [vault]);
      when(vaultRepository.isOwnedVault(vaultId)).thenAnswer((_) async => true);

      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor([
          'wss://relay.one',
          'wss://relay.two'
        ], {
          'wss://relay.one',
        }),
      );

      await service.deleteAccount();

      // No 721 should have been sent (no backup config = no stewards)
      verifyNever(invitationSendingService.sendKeyHolderRemovalEvent(
        vaultId: anyNamed('vaultId'),
        removedStewardPubkey: anyNamed('removedStewardPubkey'),
        relayUrls: anyNamed('relayUrls'),
        reason: anyNamed('reason'),
      ));
      verify(logoutService.logout()).called(1);
    });

    test('continues deletion when steward notification fails', () async {
      const vaultId = 'failing-vault';
      const stewardPubkey = 'steward-pubkey';

      const steward = Steward(
        id: 'steward-1',
        pubkey: stewardPubkey,
        name: 'Steward',
        status: StewardStatus.holdingKey,
      );

      final now = DateTime(2024);
      final config = BackupConfig(
        vaultId: vaultId,
        stewards: [steward],
        threshold: 1,
        createdAt: now,
        relays: ['wss://relay.one'],
        distributionVersion: 1,
      );

      final vault = Vault(
        id: vaultId,
        name: 'Failing Vault',
        createdAt: DateTime(2024),
        ownerPubkey: 'owner-pubkey',
        backupConfig: config,
      );

      when(vaultRepository.getAllVaults()).thenAnswer((_) async => [vault]);
      when(vaultRepository.isOwnedVault(vaultId)).thenAnswer((_) async => true);
      // Make the 721 publish fail
      when(invitationSendingService.sendKeyHolderRemovalEvent(
        vaultId: anyNamed('vaultId'),
        removedStewardPubkey: anyNamed('removedStewardPubkey'),
        relayUrls: anyNamed('relayUrls'),
        reason: anyNamed('reason'),
      )).thenThrow(Exception('network error'));

      when(
        publishService.requestAccountVanish(relayUrls: anyNamed('relayUrls')),
      ).thenAnswer(
        (_) async => handleFor([
          'wss://relay.one',
          'wss://relay.two'
        ], {
          'wss://relay.one',
        }),
      );

      final result = await service.deleteAccount();

      // Deletion proceeds despite the 721 failure
      expect(result.relayRequestAcknowledged, isTrue);
      verify(logoutService.logout()).called(1);
    });
  });
}
