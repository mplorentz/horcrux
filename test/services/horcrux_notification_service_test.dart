import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/push_notification_receiver.dart';

import '../fixtures/test_keys.dart';
import '../helpers/shared_preferences_mock.dart';
import 'horcrux_notification_service_test.mocks.dart';

@GenerateMocks([LoginService, VaultRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sharedPreferencesMock = SharedPreferencesMock();

  setUpAll(sharedPreferencesMock.setUpAll);
  tearDownAll(sharedPreferencesMock.tearDownAll);

  late MockLoginService loginService;
  late MockVaultRepository vaultRepository;
  late KeyPair keyPair;

  setUp(() {
    sharedPreferencesMock.clear();
    loginService = MockLoginService();
    vaultRepository = MockVaultRepository();
    keyPair = Bip340.generatePrivateKey();
    when(loginService.getStoredNostrKey()).thenAnswer((_) async => keyPair);
    when(vaultRepository.vaultsStream).thenAnswer((_) => const Stream<List<Vault>>.empty());
  });

  /// Decodes the `Authorization: Nostr <base64>` header back into its
  /// underlying NIP-98 event so we can assert on the server's view of the
  /// request.
  Nip01Event decodeAuthHeader(String header) {
    expect(header.startsWith('Nostr '), isTrue, reason: 'header: $header');
    final raw = utf8.decode(base64Decode(header.substring('Nostr '.length)));
    return Nip01Event.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  String? firstTag(Nip01Event event, String name) {
    for (final tag in event.tags) {
      if (tag.isNotEmpty && tag[0] == name && tag.length > 1) return tag[1];
    }
    return null;
  }

  /// Builds a service wired to a stub HTTP client that records the single
  /// request it sees, then replies with [response].
  ({
    HorcruxNotificationService service,
    List<http.Request> received,
  }) buildService({required http.Response Function(http.Request) handler}) {
    final received = <http.Request>[];
    final client = MockClient((request) async {
      received.add(request);
      return handler(request);
    });
    final service = HorcruxNotificationService(
      loginService: loginService,
      vaultRepository: vaultRepository,
      httpClient: client,
    );
    return (service: service, received: received);
  }

  group('base URL', () {
    test('defaults to production notifier', () async {
      final svc = HorcruxNotificationService(
        loginService: loginService,
        vaultRepository: vaultRepository,
      );
      expect(await svc.getBaseUrl(), HorcruxNotificationService.defaultBaseUrl);
      svc.dispose();
    });

    test('honors override from SharedPreferences (trailing slash trimmed)', () async {
      final svc = HorcruxNotificationService(
        loginService: loginService,
        vaultRepository: vaultRepository,
      );
      await svc.setBaseUrl('https://notify.example.com/');
      expect(await svc.getBaseUrl(), 'https://notify.example.com');
      svc.dispose();
    });

    test('clearing override reverts to default', () async {
      final svc = HorcruxNotificationService(
        loginService: loginService,
        vaultRepository: vaultRepository,
      );
      await svc.setBaseUrl('https://custom.example.com');
      await svc.setBaseUrl(null);
      expect(await svc.getBaseUrl(), HorcruxNotificationService.defaultBaseUrl);
      svc.dispose();
    });

    test('treats blank override as unset', () async {
      final svc = HorcruxNotificationService(
        loginService: loginService,
        vaultRepository: vaultRepository,
      );
      await svc.setBaseUrl('   ');
      expect(await svc.getBaseUrl(), HorcruxNotificationService.defaultBaseUrl);
      svc.dispose();
    });
  });

  group('register', () {
    test('POSTs /register with device_token/platform and NIP-98 auth', () async {
      final harness = buildService(
        handler: (req) => http.Response(
          jsonEncode({'pubkey': keyPair.publicKey, 'platform': 'ios'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.register(
        fcmToken: 'fcm-token-123',
        platform: NotifierPlatform.ios,
      );

      expect(harness.received, hasLength(1));
      final req = harness.received.single;
      expect(req.method, 'POST');
      expect(
        req.url.toString(),
        '${HorcruxNotificationService.defaultBaseUrl}/register',
      );
      expect(req.headers['Content-Type'], 'application/json');
      final body = json.decode(req.body) as Map<String, dynamic>;
      expect(body, {'device_token': 'fcm-token-123', 'platform': 'ios'});

      final event = decodeAuthHeader(req.headers['Authorization']!);
      expect(event.kind, NostrKind.httpAuth.value);
      expect(event.pubKey, keyPair.publicKey);
      expect(firstTag(event, 'method'), 'POST');
      expect(firstTag(event, 'u'), req.url.toString());
      expect(firstTag(event, 'payload'), isNotNull,
          reason: 'body present -> sha256 payload tag required');
      expect(Bip340.verify(event.id, event.sig, event.pubKey), isTrue);
      harness.service.dispose();
    });

    test('rejects empty FCM tokens before hitting the network', () async {
      final harness = buildService(
        handler: (_) => fail('should not make a request when fcmToken is empty'),
      );
      expect(
        () => harness.service.register(
          fcmToken: '   ',
          platform: NotifierPlatform.android,
        ),
        throwsArgumentError,
      );
      expect(harness.received, isEmpty);
      harness.service.dispose();
    });

    test('maps 4xx into HorcruxNotifierException with server message', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'rate limited'}),
          429,
          headers: {'content-type': 'application/json'},
        ),
      );

      try {
        await harness.service.register(
          fcmToken: 'abc',
          platform: NotifierPlatform.android,
        );
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.statusCode, 429);
        expect(e.isRateLimited, isTrue);
        expect(e.message, 'rate limited');
      }
      harness.service.dispose();
    });

    test('wraps transport failures as statusCode 0', () async {
      final harness = buildService(
        handler: (_) => throw const SocketExceptionLike('connection refused'),
      );
      try {
        await harness.service.register(
          fcmToken: 'abc',
          platform: NotifierPlatform.android,
        );
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.statusCode, 0);
        expect(e.isTransport, isTrue);
        expect(e.message, contains('connection refused'));
      }
      harness.service.dispose();
    });

    test('propagates an auth failure when no Nostr key is available', () async {
      when(loginService.getStoredNostrKey()).thenAnswer((_) async => null);
      final harness = buildService(
        handler: (_) => fail('should not send without a signing key'),
      );
      try {
        await harness.service.register(
          fcmToken: 'abc',
          platform: NotifierPlatform.android,
        );
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.statusCode, 0);
        expect(e.message, contains('No Nostr key'));
      }
      expect(harness.received, isEmpty);
      harness.service.dispose();
    });
  });

  group('deregister', () {
    test('DELETEs /register with NIP-98 and no body', () async {
      final harness = buildService(
        handler: (_) => http.Response('', 204),
      );
      await harness.service.deregister();

      final req = harness.received.single;
      expect(req.method, 'DELETE');
      expect(req.body, isEmpty);
      expect(req.headers.containsKey('Content-Type'), isFalse);

      final event = decodeAuthHeader(req.headers['Authorization']!);
      expect(firstTag(event, 'method'), 'DELETE');
      expect(firstTag(event, 'payload'), isNull, reason: 'no body -> no payload tag');
      harness.service.dispose();
    });

    test('swallows 404 (idempotent)', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'not found'}),
          404,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.deregister(); // Must not throw.
      harness.service.dispose();
    });

    test('still throws on 401', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'bad signature'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );
      try {
        await harness.service.deregister();
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.isUnauthorized, isTrue);
        expect(e.message, 'bad signature');
      }
      harness.service.dispose();
    });
  });

  test('updateToken is a POST /register with the new token', () async {
    final harness = buildService(
      handler: (_) => http.Response('{}', 200, headers: {'content-type': 'application/json'}),
    );
    await harness.service.updateToken(
      newToken: 'rotated-token',
      platform: NotifierPlatform.android,
    );
    final req = harness.received.single;
    expect(req.method, 'POST');
    expect(req.url.path, '/register');
    expect(
      json.decode(req.body),
      {'device_token': 'rotated-token', 'platform': 'android'},
    );
    harness.service.dispose();
  });

  group('replaceConsents', () {
    test('PUTs /consent with authorized_senders', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({
            'authorized_senders': ['a' * 64]
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.replaceConsents(['a' * 64, 'b' * 64]);

      final req = harness.received.single;
      expect(req.method, 'PUT');
      expect(req.url.path, '/consent');
      expect(json.decode(req.body), {
        'authorized_senders': ['a' * 64, 'b' * 64],
      });

      final event = decodeAuthHeader(req.headers['Authorization']!);
      expect(firstTag(event, 'method'), 'PUT');
      harness.service.dispose();
    });
  });

  group('deleteConsent', () {
    test('DELETEs /consent/{sender}', () async {
      final harness = buildService(
        handler: (_) => http.Response('', 204),
      );
      final sender = 'c' * 64;
      await harness.service.deleteConsent(sender);

      final req = harness.received.single;
      expect(req.method, 'DELETE');
      expect(req.url.path, '/consent/$sender');
      harness.service.dispose();
    });

    test('treats 404 as success (idempotent)', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'not found'}),
          404,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.deleteConsent('d' * 64); // Must not throw.
      harness.service.dispose();
    });
  });

  group('push', () {
    test('POSTs /push with full payload when event_json is provided', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'status': 'queued', 'fcm_message_id': 'fcm-xyz'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      await harness.service.push(
        recipientPubkey: 'e' * 64,
        title: 'Alice needs your help',
        body: 'Recovery of Family Vault requires your key.',
        eventJson: const {'id': 'deadbeef', 'kind': 1059},
        relayHints: const ['wss://relay.example.com'],
      );

      final req = harness.received.single;
      expect(req.method, 'POST');
      expect(req.url.path, '/push');
      expect(json.decode(req.body), {
        'recipient_pubkey': 'e' * 64,
        'title': 'Alice needs your help',
        'body': 'Recovery of Family Vault requires your key.',
        'event_json': {'id': 'deadbeef', 'kind': 1059},
        'relay_hints': ['wss://relay.example.com'],
      });
      harness.service.dispose();
    });

    test('includes only event_id when event_json is omitted', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'status': 'queued', 'fcm_message_id': 'id'}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await harness.service.push(
        recipientPubkey: 'f' * 64,
        title: 't',
        body: 'b',
        eventId: '0' * 64,
      );
      final body = json.decode(harness.received.single.body) as Map<String, dynamic>;
      expect(body.containsKey('event_json'), isFalse);
      expect(body.containsKey('relay_hints'), isFalse);
      expect(body['event_id'], '0' * 64);
      harness.service.dispose();
    });

    test('surfaces forbidden responses as HorcruxNotifierException', () async {
      final harness = buildService(
        handler: (_) => http.Response(
          jsonEncode({'error': 'recipient has not authorized this sender'}),
          403,
          headers: {'content-type': 'application/json'},
        ),
      );
      try {
        await harness.service.push(
          recipientPubkey: 'a' * 64,
          title: 't',
          body: 'b',
          eventId: '1' * 64,
        );
        fail('expected HorcruxNotifierException');
      } on HorcruxNotifierException catch (e) {
        expect(e.isForbidden, isTrue);
        expect(e.message, contains('not authorized'));
      }
      harness.service.dispose();
    });
  });

  group('computeConsentList', () {
    /// Helper that builds a service just long enough to exercise the
    /// pure [computeConsentList] method. We stub the network so accidental
    /// sync scheduling can't hit the wire.
    HorcruxNotificationService buildForCompute() {
      final client = MockClient((_) async => http.Response('{}', 200));
      return HorcruxNotificationService(
        loginService: loginService,
        vaultRepository: vaultRepository,
        httpClient: client,
      );
    }

    Vault ownedVault({
      required String id,
      required String owner,
      List<Steward> stewards = const [],
    }) {
      return Vault(
        id: id,
        name: id,
        content: 'decrypted',
        createdAt: DateTime.utc(2024, 1, 1),
        ownerPubkey: owner,
        backupConfig: stewards.isEmpty
            ? null
            : createBackupConfig(
                vaultId: id,
                threshold: 1,
                totalKeys: stewards.length,
                stewards: stewards,
                relays: const ['wss://relay.example'],
              ),
      );
    }

    ShardData shardFor({
      required String owner,
      required List<String> coStewardPubkeys,
      int? distributionVersion,
      int createdAt = 1000,
    }) {
      return ShardData(
        shard: 'encoded',
        threshold: 1,
        shardIndex: 0,
        totalShards: coStewardPubkeys.length + 1,
        primeMod: TestShardData.testPrimeMod,
        creatorPubkey: owner,
        createdAt: createdAt,
        distributionVersion: distributionVersion,
        stewards: [
          for (final pk in coStewardPubkeys) {'pubkey': pk, 'name': 'co'},
        ],
      );
    }

    Vault stewardedVault({
      required String id,
      required String owner,
      required ShardData shard,
      BackupConfig? backupConfig,
    }) {
      return Vault(
        id: id,
        name: id,
        content: null,
        createdAt: DateTime.utc(2024, 1, 1),
        ownerPubkey: owner,
        shards: [shard],
        backupConfig: backupConfig,
      );
    }

    test('returns an empty list when the user has no vaults', () {
      final svc = buildForCompute();
      expect(
        svc.computeConsentList(
          currentUserPubkey: TestHexPubkeys.alice,
          vaults: const [],
        ),
        isEmpty,
      );
      svc.dispose();
    });

    test('includes every steward (and excludes self) on an owned vault', () {
      final svc = buildForCompute();
      final vault = ownedVault(
        id: 'v1',
        owner: TestHexPubkeys.alice,
        stewards: [
          createSteward(pubkey: TestHexPubkeys.bob, name: 'Bob'),
          createSteward(pubkey: TestHexPubkeys.charlie, name: 'Charlie'),
          // Self should never slip into our own allowlist, even if the
          // backup config lists us as a steward (owner-as-steward case).
          createSteward(pubkey: TestHexPubkeys.alice, name: 'Alice', isOwner: true),
        ],
      );

      final result = svc.computeConsentList(
        currentUserPubkey: TestHexPubkeys.alice,
        vaults: [vault],
      );

      expect(
        result,
        equals(<String>[TestHexPubkeys.bob, TestHexPubkeys.charlie]..sort()),
      );
      svc.dispose();
    });

    test('includes owner plus co-stewards on a stewarded vault', () {
      // Bob is a steward of Alice's vault; Charlie is a co-steward.
      // Bob's local vault stub has no backup config (the steward side never
      // receives it), so co-stewards must come from the shard payload.
      final svc = buildForCompute();
      final vault = stewardedVault(
        id: 'v2',
        owner: TestHexPubkeys.alice,
        shard: shardFor(
          owner: TestHexPubkeys.alice,
          coStewardPubkeys: [TestHexPubkeys.charlie],
        ),
      );

      final result = svc.computeConsentList(
        currentUserPubkey: TestHexPubkeys.bob,
        vaults: [vault],
      );

      expect(
        result,
        equals(<String>[TestHexPubkeys.alice, TestHexPubkeys.charlie]..sort()),
      );
      svc.dispose();
    });

    test('prefers the most recent shard when multiple versions exist', () {
      // The helper uses `vault.mostRecentShard`, so the older shard's stale
      // co-steward list must not leak into the consent set.
      final svc = buildForCompute();
      final oldShard = shardFor(
        owner: TestHexPubkeys.alice,
        coStewardPubkeys: [TestHexPubkeys.diana],
        distributionVersion: 1,
        createdAt: 1000,
      );
      final newShard = shardFor(
        owner: TestHexPubkeys.alice,
        coStewardPubkeys: [TestHexPubkeys.charlie],
        distributionVersion: 2,
        createdAt: 2000,
      );
      final vault = Vault(
        id: 'v2',
        name: 'v2',
        content: null,
        createdAt: DateTime.utc(2024, 1, 1),
        ownerPubkey: TestHexPubkeys.alice,
        shards: [oldShard, newShard],
      );

      final result = svc.computeConsentList(
        currentUserPubkey: TestHexPubkeys.bob,
        vaults: [vault],
      );

      expect(result, contains(TestHexPubkeys.charlie));
      expect(result, contains(TestHexPubkeys.alice));
      expect(result, isNot(contains(TestHexPubkeys.diana)));
      svc.dispose();
    });

    test('dedupes the same pubkey across multiple vaults', () {
      final svc = buildForCompute();
      final ownedByAlice = ownedVault(
        id: 'owned',
        owner: TestHexPubkeys.alice,
        stewards: [createSteward(pubkey: TestHexPubkeys.bob, name: 'Bob')],
      );
      final stewardedForBob = stewardedVault(
        id: 'stewarded',
        owner: TestHexPubkeys.bob,
        shard: shardFor(
          owner: TestHexPubkeys.bob,
          coStewardPubkeys: [TestHexPubkeys.charlie],
        ),
      );

      final result = svc.computeConsentList(
        currentUserPubkey: TestHexPubkeys.alice,
        vaults: [ownedByAlice, stewardedForBob],
      );

      // Bob appears as a steward on the owned vault AND as the owner of the
      // stewarded vault; the result should contain him exactly once.
      expect(result.where((e) => e == TestHexPubkeys.bob), hasLength(1));
      expect(result, containsAll([TestHexPubkeys.bob, TestHexPubkeys.charlie]));
      svc.dispose();
    });

    test('ignores invalid pubkeys, blanks, and invited stewards (no pubkey)', () {
      final svc = buildForCompute();
      // Exercise both input paths:
      // - backupConfig.stewards: a legitimate invited steward (pubkey == null)
      // - shard.stewards: raw maps from the owner's payload, which we must
      //   defensively filter on the way in (non-hex, wrong length, blanks).
      const invited = Steward(
        id: 'invited',
        pubkey: null,
        name: 'Invited',
        inviteCode: 'x',
        status: StewardStatus.invited,
      );
      final valid = createSteward(pubkey: TestHexPubkeys.bob, name: 'Bob');

      final vault = Vault(
        id: 'v',
        name: 'v',
        content: 'c',
        createdAt: DateTime.utc(2024, 1, 1),
        ownerPubkey: TestHexPubkeys.alice,
        backupConfig: createBackupConfig(
          vaultId: 'v',
          threshold: 1,
          totalKeys: 2,
          stewards: [invited, valid],
          relays: const ['wss://relay.example'],
        ),
        shards: [
          // An owner-side-only test wouldn't normally have shards, but we
          // piggyback on this vault to also assert that bad shard entries
          // get filtered.
          shardFor(
            owner: TestHexPubkeys.alice,
            coStewardPubkeys: const [],
          ).copyWith(
            stewards: [
              {'pubkey': 'not-hex', 'name': 'bad'},
              {'pubkey': 'abcdef', 'name': 'short'},
              {'pubkey': '', 'name': 'blank'},
              {'pubkey': TestHexPubkeys.charlie, 'name': 'Charlie'},
            ],
          ),
        ],
      );

      final result = svc.computeConsentList(
        currentUserPubkey: TestHexPubkeys.alice,
        vaults: [vault],
      );

      expect(
        result,
        equals([TestHexPubkeys.bob, TestHexPubkeys.charlie]..sort()),
      );
      svc.dispose();
    });

    test('normalizes output to lowercase and sorts stably', () {
      final svc = buildForCompute();
      final upperBob = TestHexPubkeys.bob.toUpperCase();
      final upperCharlie = TestHexPubkeys.charlie.toUpperCase();
      final vault = ownedVault(
        id: 'v',
        owner: TestHexPubkeys.alice,
        stewards: [
          createSteward(pubkey: upperCharlie, name: 'C'),
          createSteward(pubkey: upperBob, name: 'B'),
        ],
      );

      final result = svc.computeConsentList(
        currentUserPubkey: TestHexPubkeys.alice.toUpperCase(),
        vaults: [vault],
      );

      // Everything lowercased, bob sorts before charlie alphabetically in
      // our fixture keys (9a16...  < bca6...).
      expect(result, equals([TestHexPubkeys.bob, TestHexPubkeys.charlie]));
      svc.dispose();
    });
  });

  group('syncConsentList', () {
    // The service reads opt-in state and the last-synced snapshot through
    // `SharedPreferences.getInstance()`, a process-wide singleton with its
    // own cache. Re-seeding via `setMockInitialValues` in every test is
    // the only way to guarantee a clean read.
    setUp(() {
      SharedPreferences.setMockInitialValues({
        PushNotificationReceiver.optInFlagKey: true,
      });
    });

    /// Collects every request the service issues so we can assert on
    /// side effects (or lack thereof).
    ({
      HorcruxNotificationService service,
      List<http.Request> received,
    }) buildSyncService({required http.Response Function(http.Request) handler}) {
      final received = <http.Request>[];
      final client = MockClient((request) async {
        received.add(request);
        return handler(request);
      });
      final service = HorcruxNotificationService(
        loginService: loginService,
        vaultRepository: vaultRepository,
        httpClient: client,
      );
      return (service: service, received: received);
    }

    /// Puts the user into a state where push is enabled and they have a
    /// valid pubkey. Returns the owned vault we'll use to drive consent
    /// derivation so individual tests can tweak it.
    Vault primeOptedInAlice() {
      when(loginService.getCurrentPublicKey()).thenAnswer((_) async => TestHexPubkeys.alice);
      final vault = Vault(
        id: 'v',
        name: 'v',
        content: 'secret',
        createdAt: DateTime.utc(2024, 1, 1),
        ownerPubkey: TestHexPubkeys.alice,
        backupConfig: createBackupConfig(
          vaultId: 'v',
          threshold: 1,
          totalKeys: 2,
          stewards: [
            createSteward(pubkey: TestHexPubkeys.bob, name: 'Bob'),
            createSteward(pubkey: TestHexPubkeys.charlie, name: 'Charlie'),
          ],
          relays: const ['wss://relay.example'],
        ),
      );
      when(vaultRepository.getAllVaults()).thenAnswer((_) async => [vault]);
      return vault;
    }

    test('no-ops and makes no network calls when push is not opted in', () async {
      SharedPreferences.setMockInitialValues({
        PushNotificationReceiver.optInFlagKey: false,
      });
      when(loginService.getCurrentPublicKey()).thenAnswer((_) async => TestHexPubkeys.alice);
      when(vaultRepository.getAllVaults()).thenAnswer((_) async => const <Vault>[]);

      final harness = buildSyncService(
        handler: (_) => fail('must not hit the wire while opted out'),
      );
      await harness.service.syncConsentList();

      expect(harness.received, isEmpty);
      verifyNever(vaultRepository.getAllVaults());
      harness.service.dispose();
    });

    test('bails without PUTting when there is no logged-in pubkey', () async {
      when(loginService.getCurrentPublicKey()).thenAnswer((_) async => null);

      final harness = buildSyncService(
        handler: (_) => fail('must not PUT when we have no signer'),
      );
      await harness.service.syncConsentList();
      expect(harness.received, isEmpty);
      harness.service.dispose();
    });

    test('PUTs /consent with the derived senders and persists a snapshot', () async {
      primeOptedInAlice();
      final expected = [TestHexPubkeys.bob, TestHexPubkeys.charlie]..sort();

      final harness = buildSyncService(
        handler: (_) => http.Response(
          jsonEncode({'authorized_senders': expected}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      await harness.service.syncConsentList();

      expect(harness.received, hasLength(1));
      final req = harness.received.single;
      expect(req.method, 'PUT');
      expect(req.url.path, '/consent');
      expect(json.decode(req.body), {'authorized_senders': expected});

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('horcrux_notifier_last_synced_consents'),
        equals(expected),
      );
      harness.service.dispose();
    });

    test('skips PUT when the derived list matches the last-synced snapshot', () async {
      final expected = [TestHexPubkeys.bob, TestHexPubkeys.charlie]..sort();
      SharedPreferences.setMockInitialValues({
        PushNotificationReceiver.optInFlagKey: true,
        'horcrux_notifier_last_synced_consents': expected,
      });
      primeOptedInAlice();

      final harness = buildSyncService(
        handler: (_) => fail('unchanged list should not trigger a PUT'),
      );
      await harness.service.syncConsentList();
      expect(harness.received, isEmpty);
      harness.service.dispose();
    });

    test('PUTs again when the derived list has diverged from the snapshot', () async {
      // Snapshot is stale: it still has Diana who is no longer a steward.
      SharedPreferences.setMockInitialValues({
        PushNotificationReceiver.optInFlagKey: true,
        'horcrux_notifier_last_synced_consents': [TestHexPubkeys.bob, TestHexPubkeys.diana]..sort(),
      });
      primeOptedInAlice();

      final harness = buildSyncService(
        handler: (_) => http.Response('{}', 200, headers: {'content-type': 'application/json'}),
      );
      await harness.service.syncConsentList();

      final expected = [TestHexPubkeys.bob, TestHexPubkeys.charlie]..sort();
      expect(harness.received, hasLength(1));
      expect(
        json.decode(harness.received.single.body),
        {'authorized_senders': expected},
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('horcrux_notifier_last_synced_consents'),
        equals(expected),
      );
      harness.service.dispose();
    });

    test('PUTs an empty allowlist when the user no longer has any relationships', () async {
      // If the owner removes everyone / archives their last vault we still
      // want the notifier to see an empty list so it stops trusting old
      // senders. The snapshot compare guards against resending on every tick.
      SharedPreferences.setMockInitialValues({
        PushNotificationReceiver.optInFlagKey: true,
        'horcrux_notifier_last_synced_consents': [TestHexPubkeys.bob],
      });
      when(loginService.getCurrentPublicKey()).thenAnswer((_) async => TestHexPubkeys.alice);
      when(vaultRepository.getAllVaults()).thenAnswer((_) async => const <Vault>[]);

      final harness = buildSyncService(
        handler: (_) => http.Response('{}', 200, headers: {'content-type': 'application/json'}),
      );
      await harness.service.syncConsentList();

      expect(harness.received, hasLength(1));
      expect(json.decode(harness.received.single.body), {'authorized_senders': <String>[]});
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('horcrux_notifier_last_synced_consents'),
        equals(<String>[]),
      );
      harness.service.dispose();
    });
  });

  group('vault stream triggers debounced sync', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        PushNotificationReceiver.optInFlagKey: true,
      });
    });

    test('emissions on the vault stream schedule a single debounced sync', () async {
      when(loginService.getCurrentPublicKey()).thenAnswer((_) async => TestHexPubkeys.alice);
      when(vaultRepository.getAllVaults()).thenAnswer(
        (_) async => [
          Vault(
            id: 'v',
            name: 'v',
            content: 'secret',
            createdAt: DateTime.utc(2024, 1, 1),
            ownerPubkey: TestHexPubkeys.alice,
            backupConfig: createBackupConfig(
              vaultId: 'v',
              threshold: 1,
              totalKeys: 1,
              stewards: [createSteward(pubkey: TestHexPubkeys.bob, name: 'Bob')],
              relays: const ['wss://relay.example'],
            ),
          ),
        ],
      );

      final controller = StreamController<List<Vault>>.broadcast();
      when(vaultRepository.vaultsStream).thenAnswer((_) => controller.stream);

      final received = <http.Request>[];
      final client = MockClient((request) async {
        received.add(request);
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });
      final service = HorcruxNotificationService(
        loginService: loginService,
        vaultRepository: vaultRepository,
        httpClient: client,
      );
      addTearDown(service.dispose);
      addTearDown(controller.close);

      // Fire two updates in quick succession; the debouncer should coalesce
      // them into a single PUT once the window elapses.
      controller.add(const <Vault>[]);
      controller.add(const <Vault>[]);

      // Debounce is 700ms; wait a hair longer to be safe.
      await Future<void>.delayed(const Duration(milliseconds: 900));

      expect(received, hasLength(1));
      expect(received.single.method, 'PUT');
      expect(received.single.url.path, '/consent');
    });
  });
}

/// Simple stand-in for a transport-level failure; the service only cares
/// that the client throws, not about the concrete type.
class SocketExceptionLike implements Exception {
  final String message;
  const SocketExceptionLike(this.message);
  @override
  String toString() => 'SocketException: $message';
}
