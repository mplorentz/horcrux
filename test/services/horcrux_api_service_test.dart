import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/terms_of_service.dart';
import 'package:horcrux/services/horcrux_api_service.dart';
import 'package:horcrux/services/login_service.dart';

import 'horcrux_api_service_test.mocks.dart';

@GenerateMocks([LoginService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLoginService loginService;
  late AppDatabase testDatabase;
  late List<http.BaseRequest> capturedRequests;
  late KeyPair keyPair;

  /// Creates a [HorcruxApiService] backed by [mockClient] and the test DB.
  HorcruxApiService createService(MockClient mockClient) {
    return HorcruxApiService(
      loginService: loginService,
      database: testDatabase,
      httpClient: mockClient,
    );
  }

  setUp(() {
    loginService = MockLoginService();
    testDatabase = AppDatabase(NativeDatabase.memory());
    capturedRequests = [];
    keyPair = Bip340.generatePrivateKey();
    when(loginService.getStoredNostrKey()).thenAnswer((_) async => keyPair);
  });

  tearDown(() async {
    await testDatabase.close();
  });

  group('acceptTermsOfService', () {
    test('sends POST /tos/accept with NIP-98 auth on success', () async {
      final mockClient = MockClient((request) async {
        capturedRequests.add(request);
        return http.Response.bytes(utf8.encode('{}'), 200);
      });

      final service = createService(mockClient);
      await service.acceptTermsOfService(1);

      expect(capturedRequests, hasLength(1));
      final req = capturedRequests.first;
      expect(req.url.path, '/tos/accept');
      expect(req.method, 'POST');

      // Verify NIP-98 auth header is present.
      final auth = req.headers['authorization'];
      expect(auth, isNotNull);
      expect(auth!.startsWith('Nostr '), isTrue);

      // Verify body contains tos_version (request is a [http.Request] subclass).
      if (req is http.Request) {
        final body = jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;
        expect(body['tos_version'], 1);
      }

      // Verify the accepted version was persisted locally.
      final stored = await service.getLastAcceptedVersion();
      expect(stored, 1);
    });

    test('throws on non-2xx response', () async {
      final mockClient = MockClient((_) async {
        return http.Response('{"error":"bad request"}', 422);
      });

      final service = createService(mockClient);
      expect(
        () => service.acceptTermsOfService(1),
        throwsA(isA<HorcruxApiException>()),
      );
    });

    test('throws when no Nostr key is available', () async {
      when(loginService.getStoredNostrKey()).thenAnswer((_) async => null);

      final mockClient = MockClient((_) async {
        return http.Response('{}', 200);
      });

      final service = createService(mockClient);
      expect(
        () => service.acceptTermsOfService(1),
        throwsA(
          predicate<HorcruxApiException>((e) => e.isTransport),
        ),
      );
    });
  });

  group('needsConsentAcceptance', () {
    // The ToS version check is now purely local (bundled kCurrentTosVersion
    // vs. the last accepted version in the DB) — no network call, so these
    // tests don't need to configure the mock client's response.
    test('returns true when no version has been accepted', () async {
      final service = createService(MockClient((_) async => http.Response('', 200)));
      final needs = await service.needsConsentAcceptance();

      expect(needs, isTrue);
    });

    test('returns true when accepted version is older than the bundled version', () async {
      await testDatabase.appStateDao.setInt(
        key: HorcruxApiService.tosAcceptedVersionKey,
        value: 0,
      );

      final service = createService(MockClient((_) async => http.Response('', 200)));
      final needs = await service.needsConsentAcceptance();

      expect(needs, isTrue);
    });

    test('returns false when accepted version matches the bundled version', () async {
      await testDatabase.appStateDao.setInt(
        key: HorcruxApiService.tosAcceptedVersionKey,
        value: kCurrentTosVersion,
      );

      final service = createService(MockClient((_) async => http.Response('', 200)));
      final needs = await service.needsConsentAcceptance();

      expect(needs, isFalse);
    });
  });

  group('getLastAcceptedVersion', () {
    test('returns null when no version has been stored', () async {
      final mockClient = MockClient((_) async {
        return http.Response('{}', 200);
      });

      final service = createService(mockClient);
      final version = await service.getLastAcceptedVersion();

      expect(version, isNull);
    });

    test('returns stored version', () async {
      await testDatabase.appStateDao.setInt(
        key: HorcruxApiService.tosAcceptedVersionKey,
        value: 5,
      );

      final mockClient = MockClient((_) async {
        return http.Response('{}', 200);
      });

      final service = createService(mockClient);
      final version = await service.getLastAcceptedVersion();

      expect(version, 5);
    });
  });
}
