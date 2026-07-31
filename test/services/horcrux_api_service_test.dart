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

  group('fetchTermsOfService', () {
    test('returns TermsOfService on 200', () async {
      final mockClient = MockClient((request) async {
        capturedRequests.add(request);
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'text': 'Test terms of service.',
            'version': 3,
          })),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = createService(mockClient);
      final tos = await service.fetchTermsOfService();

      expect(tos.text, 'Test terms of service.');
      expect(tos.version, 3);
      expect(capturedRequests, hasLength(1));
      expect(capturedRequests.first.url.path, '/tos');
      expect(capturedRequests.first.method, 'GET');
    });

    test('throws on non-200 response', () async {
      final mockClient = MockClient((_) async {
        return http.Response('{"error":"internal error"}', 500);
      });

      final service = createService(mockClient);
      expect(
        () => service.fetchTermsOfService(),
        throwsA(isA<HorcruxApiException>()),
      );
    });
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
    test('returns true when no version has been accepted', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'text': 'Terms v1',
            'version': 1,
          })),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = createService(mockClient);
      final needs = await service.needsConsentAcceptance();

      expect(needs, isTrue);
    });

    test('returns true when served version is newer than accepted', () async {
      // Pre-accept version 1.
      await testDatabase.appStateDao.setInt(
        key: HorcruxApiService.tosAcceptedVersionKey,
        value: 1,
      );

      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'text': 'Terms v2',
            'version': 2,
          })),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = createService(mockClient);
      final needs = await service.needsConsentAcceptance();

      expect(needs, isTrue);
    });

    test('returns false when served version matches accepted', () async {
      // Pre-accept version 1.
      await testDatabase.appStateDao.setInt(
        key: HorcruxApiService.tosAcceptedVersionKey,
        value: 1,
      );

      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'text': 'Terms v1',
            'version': 1,
          })),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = createService(mockClient);
      final needs = await service.needsConsentAcceptance();

      expect(needs, isFalse);
    });

    test('returns false when API is unreachable', () async {
      final mockClient = MockClient((_) async {
        throw Exception('Connection refused');
      });

      final service = createService(mockClient);
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
