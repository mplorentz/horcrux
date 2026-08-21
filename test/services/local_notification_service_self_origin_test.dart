import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:ndk/ndk.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/local_notification_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/recovery_service.dart';
import 'package:horcrux/services/ndk_service.dart' show RecoveryResponseEvent;

import '../fixtures/test_keys.dart';

/// Stub [FlutterLocalNotificationsPlatform] so notification tests don't crash
/// with a LateInitializationError on the platform _instance.
class _StubFlutterLocalNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

class _SpyingVaultRepository extends Fake implements VaultRepository {
  final List<String> getVaultCalls = <String>[];

  @override
  Future<Vault?> getVault(String id) async {
    getVaultCalls.add(id);
    return null;
  }
}

/// Returns a fixed pubkey as the "current user". Returning `null` simulates
/// "no key initialized yet"; in that mode the filter must default to
/// "not self" so a transient secure-storage hiccup never silently swallows
/// real notifications.
class _FakeLoginService extends Fake implements LoginService {
  _FakeLoginService(this._pubkey);

  final String? _pubkey;

  @override
  Future<String?> getCurrentPublicKey() async => _pubkey;
}

class _FakeRecoveryService extends Fake implements RecoveryService {
  @override
  Future<RecoveryRequest?> getRecoveryRequest(String id) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Builds a kind-718 shard-confirmation rumor signed by [senderPubkey].
  /// Only the fields the production code reads (`pubKey`, `id`, `createdAt`)
  /// matter for these tests; everything else is filler.
  Nip01Event buildShardConfirmation({
    required String senderPubkey,
    int createdAt = 1700000000,
    String id = 'evt-shard-confirm-1',
  }) {
    return Nip01Event(
      id: id,
      pubKey: senderPubkey,
      kind: 718,
      tags: const [],
      createdAt: createdAt,
      content: '',
    );
  }

  Nip01Event buildShare({
    required String senderPubkey,
    int createdAt = 1700000000,
    String id = 'evt-shard-data-1',
  }) {
    return Nip01Event(
      id: id,
      pubKey: senderPubkey,
      kind: 713,
      tags: const [],
      createdAt: createdAt,
      content: '',
    );
  }

  Share makeShare({String vaultId = 'vault-1'}) {
    return Share(
      payload: 'shard-payload',
      threshold: 2,
      shareIndex: 0,
      totalShares: 3,
      scheme: TestShare.testPrimeMod,
      creatorPubkey: TestShare.testCreatorPubkey,
      createdAt: 1700000000,
      vaultId: vaultId,
    );
  }

  late _SpyingVaultRepository vaultRepository;
  late _FakeRecoveryService recoveryService;

  setUp(() {
    FlutterLocalNotificationsPlatform.instance = _StubFlutterLocalNotificationsPlatform();
    // The shard-data and shard-confirmation paths consult `getFirstAppOpenUtc`
    vaultRepository = _SpyingVaultRepository();
    recoveryService = _FakeRecoveryService();
  });

  LocalNotificationService buildService({
    String? currentPubkey,
    bool Function()? isForegrounded,
  }) {
    return LocalNotificationService(
      vaultRepository: vaultRepository,
      loginService: _FakeLoginService(currentPubkey),
      appDatabase: AppDatabase(NativeDatabase.memory()),
      getRecoveryService: () => recoveryService,
      // Tests default to "background" so behavior does not depend on the
      // binding's lifecycle (horcrux_app-tur foreground gate).
      isForegrounded: isForegrounded ?? () => false,
    );
  }

  group('LocalNotificationService self-origin filter (horcrux_app-3b0)', () {
    test(
      'shard confirmation signed by the current user does not trigger a '
      'vault lookup or notification',
      () async {
        // Owner is a steward of their own vault, so a kind-718 they just
        // published gets gift-wrapped to themselves and round-trips back. The
        // filter must drop it before composing "{self} has confirmed they
        // have the latest data..." -- the bug from horcrux_app-3b0.
        final service = buildService(currentPubkey: TestHexPubkeys.alice);

        await service.notifyShareConfirmationProcessed(
          event: buildShardConfirmation(senderPubkey: TestHexPubkeys.alice),
          vaultId: 'vault-1',
        );

        expect(
          vaultRepository.getVaultCalls,
          isEmpty,
          reason: 'self-origin events must be dropped before vault lookup',
        );
      },
    );

    test(
      'shard data signed by the current user does not trigger a vault '
      'lookup or notification',
      () async {
        // Mirrors the confirmation case for the kind-713 leg of the loop:
        // the owner publishes shard data to every steward, which includes
        // themselves; the gift wrap echoes back and would otherwise read
        // "Open Horcrux to save the latest data for {self}'s vault X".
        final service = buildService(currentPubkey: TestHexPubkeys.alice);

        await service.notifyShareDataProcessed(
          event: buildShare(senderPubkey: TestHexPubkeys.alice),
          share: makeShare(vaultId: 'vault-1'),
        );

        expect(vaultRepository.getVaultCalls, isEmpty);
      },
    );

    test(
      'shard confirmation from another steward still proceeds past the '
      'self-origin filter when foregrounded',
      () async {
        // Sanity check: with the filter in place, real cross-device
        // confirmations from peers must keep flowing through to the rest
        // of the notification pipeline (vault lookup, text composition,
        // OS show). We must be in foreground because the T3 background
        // gate suppresses notifications when the app is not visible
        // (FCM push covers that case).
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => true,
        );

        await service.notifyShareConfirmationProcessed(
          event: buildShardConfirmation(
            senderPubkey: TestHexPubkeys.bob,
            // Use "now" so the recency gate doesn't filter the event out
            // first and mask the assertion we actually care about.
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          vaultId: 'vault-1',
        );

        expect(
          vaultRepository.getVaultCalls,
          equals(['vault-1']),
          reason: 'non-self events in foreground must reach vault lookup',
        );
      },
    );

    test(
      'pubkey comparison is case-insensitive',
      () async {
        // Hex pubkeys *should* always be lowercase by convention, but
        // upstream relays and gift-wrap unwrappers occasionally surface a
        // mixed-case form. Do not let a case mismatch open a hole in the
        // self-filter -- the bug from horcrux_app-3b0 would still surface.
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice.toLowerCase(),
        );

        await service.notifyShareConfirmationProcessed(
          event: buildShardConfirmation(
            senderPubkey: TestHexPubkeys.alice.toUpperCase(),
          ),
          vaultId: 'vault-1',
        );

        expect(vaultRepository.getVaultCalls, isEmpty);
      },
    );

    test(
      'no current key (e.g. login not initialized) defaults to "not self" '
      'so notifications are not silently swallowed when foregrounded',
      () async {
        // Login can transiently report no key (cold-start race, secure
        // storage hiccup). The safe default is to keep notifying so a flake
        // in `LoginService` does not look like a notification regression.
        // Must be in foreground because the T3 background gate suppresses
        // notifications when the app is not visible (FCM push covers it).
        final service = buildService(
          currentPubkey: null,
          isForegrounded: () => true,
        );

        await service.notifyShareConfirmationProcessed(
          event: buildShardConfirmation(
            senderPubkey: TestHexPubkeys.alice,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          vaultId: 'vault-1',
        );

        expect(vaultRepository.getVaultCalls, equals(['vault-1']));
      },
    );
  });

  /// Builds a kind-716 invitation-acceptance rumor signed by [senderPubkey].
  Nip01Event buildInvitationAcceptance({
    required String senderPubkey,
    int createdAt = 1700000000,
    String id = 'evt-invite-accept-1',
  }) {
    return Nip01Event(
      id: id,
      pubKey: senderPubkey,
      kind: NostrKind.invitationAcceptance.value,
      tags: const [],
      createdAt: createdAt,
      content: '',
    );
  }

  group('LocalNotificationService invitation acceptance', () {
    test(
      'invitation acceptance from another steward proceeds past '
      'self-origin filter and reaches vault lookup when foregrounded',
      () async {
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => true,
        );

        await service.notifyInvitationAcceptanceProcessed(
          event: buildInvitationAcceptance(
            senderPubkey: TestHexPubkeys.bob,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          vaultId: 'vault-1',
        );

        expect(
          vaultRepository.getVaultCalls,
          equals(['vault-1']),
          reason: 'non-self invitation acceptance in foreground must reach vault lookup',
        );
      },
    );

    test(
      'invitation acceptance from a peer is suppressed when NOT foregrounded '
      '(FCM covers background notifications)',
      () async {
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => false,
        );

        await service.notifyInvitationAcceptanceProcessed(
          event: buildInvitationAcceptance(
            senderPubkey: TestHexPubkeys.bob,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          vaultId: 'vault-1',
        );

        expect(
          vaultRepository.getVaultCalls,
          isEmpty,
          reason: 'background invitation acceptance must be suppressed (FCM covers it)',
        );
      },
    );

    test(
      'invitation acceptance signed by the current user is filtered '
      'by self-origin check',
      () async {
        final service = buildService(currentPubkey: TestHexPubkeys.alice);

        await service.notifyInvitationAcceptanceProcessed(
          event: buildInvitationAcceptance(
            senderPubkey: TestHexPubkeys.alice,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          vaultId: 'vault-1',
        );

        expect(
          vaultRepository.getVaultCalls,
          isEmpty,
          reason: 'self-origin invitation acceptance must be dropped',
        );
      },
    );

    test(
      'invitation acceptance with empty vaultId is skipped before '
      'vault lookup',
      () async {
        final service = buildService(currentPubkey: TestHexPubkeys.alice);

        await service.notifyInvitationAcceptanceProcessed(
          event: buildInvitationAcceptance(
            senderPubkey: TestHexPubkeys.bob,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          vaultId: '',
        );

        expect(
          vaultRepository.getVaultCalls,
          isEmpty,
          reason: 'empty vaultId must short-circuit before vault lookup',
        );
      },
    );

    test(
      'old invitation acceptance event is filtered by recency gate',
      () async {
        final service = buildService(currentPubkey: TestHexPubkeys.alice);

        await service.notifyInvitationAcceptanceProcessed(
          event: buildInvitationAcceptance(
            senderPubkey: TestHexPubkeys.bob,
            // Old timestamp from well before first app open
            createdAt: 1700000000,
          ),
          vaultId: 'vault-1',
        );

        expect(
          vaultRepository.getVaultCalls,
          isEmpty,
          reason: 'old events must be filtered by recency gate',
        );
      },
    );
  });

  group('LocalNotificationService foreground shard suppression (horcrux_app-tur)', () {
    test(
      'kind-713 from a peer reaches vault lookup when isForegrounded is true '
      '(no duplicated FCM in foreground)',
      () async {
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => true,
        );

        await service.notifyShareDataProcessed(
          event: buildShare(
            senderPubkey: TestHexPubkeys.bob,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          share: makeShare(vaultId: 'vault-1'),
        );

        expect(vaultRepository.getVaultCalls, equals(['vault-1']));
      },
    );
    test(
      'kind-713 from a peer is suppressed when NOT foregrounded '
      '(FCM covers background notifications)',
      () async {
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => false,
        );

        await service.notifyShareDataProcessed(
          event: buildShare(
            senderPubkey: TestHexPubkeys.bob,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          share: makeShare(vaultId: 'vault-1'),
        );

        expect(vaultRepository.getVaultCalls, isEmpty);
      },
    );

    test(
      'kind-718 from a peer is suppressed when NOT foregrounded '
      '(T3: FCM push covers background notifications)',
      () async {
        // When the app is in background, the FCM push notification already
        // displays an OS notification. Showing a local notification on top
        // would duplicate it. Skip the local notification and rely on the
        // FCM push.
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => false,
        );

        await service.notifyShareConfirmationProcessed(
          event: buildShardConfirmation(
            senderPubkey: TestHexPubkeys.bob,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          vaultId: 'vault-1',
        );

        expect(
          vaultRepository.getVaultCalls,
          isEmpty,
          reason: 'background confirmation must be suppressed (FCM covers it)',
        );
      },
    );

    test(
      'kind-718 from a peer still reaches vault lookup when foregrounded',
      () async {
        // When the app is in foreground, no FCM OS notification clash, so
        // the local notification pipeline must proceed normally.
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => true,
        );

        await service.notifyShareConfirmationProcessed(
          event: buildShardConfirmation(
            senderPubkey: TestHexPubkeys.bob,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          vaultId: 'vault-1',
        );

        expect(vaultRepository.getVaultCalls, equals(['vault-1']));
      },
    );
  });

  group('LocalNotificationService recovery request background suppression', () {
    // Borrow RecoversRequest from the production code's naming.
    RecoveryRequest makeRecentRecoveryRequest({String vaultId = 'vault-1'}) {
      return RecoveryRequest(
        id: 'req-1',
        vaultId: vaultId,
        initiatorPubkey: TestHexPubkeys.bob,
        requestedAt: DateTime.now().subtract(const Duration(seconds: 30)),
        status: RecoveryRequestStatus.pending,
        threshold: 2,
      );
    }

    test(
      'recovery request reaches vault lookup when foregrounded',
      () async {
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => true,
        );

        await service.notifyRecoveryRequestProcessed(makeRecentRecoveryRequest());

        expect(
          vaultRepository.getVaultCalls,
          equals(['vault-1']),
          reason: 'foreground recovery request must reach vault lookup',
        );
      },
    );

    test(
      'recovery request is suppressed when NOT foregrounded '
      '(FCM covers background notifications)',
      () async {
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => false,
        );

        await service.notifyRecoveryRequestProcessed(makeRecentRecoveryRequest());

        expect(
          vaultRepository.getVaultCalls,
          isEmpty,
          reason: 'background recovery request must be suppressed (FCM covers it)',
        );
      },
    );
  });

  group('LocalNotificationService recovery response background suppression', () {
    RecoveryResponseEvent makeRecentRecoveryResponse({bool approved = true}) {
      return RecoveryResponseEvent(
        recoveryRequestId: 'req-1',
        vaultId: 'vault-1',
        senderPubkey: TestHexPubkeys.bob,
        approved: approved,
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
    }

    test(
      'recovery response reaches vault lookup when foregrounded',
      () async {
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => true,
        );

        await service.notifyRecoveryResponseProcessed(makeRecentRecoveryResponse());

        expect(
          vaultRepository.getVaultCalls,
          equals(['vault-1']),
          reason: 'foreground recovery response must reach vault lookup',
        );
      },
    );

    test(
      'recovery response is suppressed when NOT foregrounded '
      '(FCM covers background notifications)',
      () async {
        final service = buildService(
          currentPubkey: TestHexPubkeys.alice,
          isForegrounded: () => false,
        );

        await service.notifyRecoveryResponseProcessed(makeRecentRecoveryResponse());

        expect(
          vaultRepository.getVaultCalls,
          isEmpty,
          reason: 'background recovery response must be suppressed (FCM covers it)',
        );
      },
    );
  });
}
