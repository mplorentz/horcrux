import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/invitation_service.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/providers/key_provider.dart';
import '../fixtures/test_keys.dart';
import '../helpers/secure_storage_mock.dart';

import 'ndk_service_test.mocks.dart';

@GenerateMocks([
  Ndk,
  GiftWrap,
  Broadcast,
  Nip01Event,
  NdkBroadcastResponse,
  LoginService,
  InvitationService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();

  setUpAll(() {
    secureStorageMock.setUpAll();
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
  });

  group('NdkService - Expiration Tag Tests', () {
    late LoginService loginService;
    late MockNdk mockNdk;
    late MockGiftWrap mockGiftWrap;
    late MockBroadcast mockBroadcast;
    late MockNip01Event mockRumor;
    late MockNip01Event mockGiftWrapEvent;
    late MockNdkBroadcastResponse mockBroadcastResponse;
    late NdkService ndkService;
    late ProviderContainer container;

    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({});

      loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      // Generate a key pair for the test
      await loginService.generateAndStoreNostrKey();

      // Create mocks
      mockNdk = MockNdk();
      mockGiftWrap = MockGiftWrap();
      mockBroadcast = MockBroadcast();
      mockRumor = MockNip01Event();
      mockGiftWrapEvent = MockNip01Event();
      mockBroadcastResponse = MockNdkBroadcastResponse();

      // Setup NDK mocks
      when(mockNdk.giftWrap).thenReturn(mockGiftWrap);
      when(mockNdk.broadcast).thenReturn(mockBroadcast);

      // Setup gift wrap event ID
      when(mockGiftWrapEvent.id).thenReturn('test-gift-wrap-event-id');

      // Setup container
      container = ProviderContainer(
        overrides: [
          loginServiceProvider.overrideWithValue(loginService),
          invitationServiceProvider.overrideWithValue(MockInvitationService()),
        ],
      );

      // Create NdkService using the provider which gives us proper Ref
      ndkService = container.read(ndkServiceProvider);
    });

    tearDown(() async {
      await ndkService.dispose();
      container.dispose();
    });

    test(
      'publishEncryptedEvent adds expiration tag when none exists',
      () async {
        // Arrange
        final capturedTags = <List<String>>[];
        const testContent = 'test content';
        final testKind = NostrKind.shardData.value;
        const recipientPubkey = TestHexPubkeys.alice;
        final relays = ['ws://localhost:10547'];

        // Mock createRumor to capture tags
        when(
          mockGiftWrap.createRumor(
            customPubkey: anyNamed('customPubkey'),
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            tags: anyNamed('tags'),
          ),
        ).thenAnswer((invocation) async {
          final tags = invocation.namedArguments[#tags] as List<List<String>>;
          capturedTags.addAll(tags);
          return mockRumor;
        });

        // Mock toGiftWrap
        when(
          mockGiftWrap.toGiftWrap(
            rumor: anyNamed('rumor'),
            recipientPubkey: anyNamed('recipientPubkey'),
          ),
        ).thenAnswer((_) async => mockGiftWrapEvent);

        // Mock broadcast
        when(
          mockBroadcast.broadcast(
            nostrEvent: anyNamed('nostrEvent'),
            specificRelays: anyNamed('specificRelays'),
          ),
        ).thenReturn(mockBroadcastResponse);

        // Mock broadcast results
        when(mockBroadcastResponse.broadcastDoneFuture).thenAnswer(
          (_) async => [
            RelayBroadcastResponse(
              relayUrl: relays.first,
              broadcastSuccessful: true,
              msg: '',
            ),
          ],
        );

        // Inject mock NDK for testing
        ndkService.setNdkForTesting(mockNdk);

        // Act
        await ndkService.publishEncryptedEvent(
          content: testContent,
          kind: testKind,
          recipientPubkey: recipientPubkey,
          relays: relays,
          tags: [
            ['d', 'test-tag'],
          ],
        );

        // Assert - Verify expiration tag was added
        expect(capturedTags, isNotEmpty);

        // Find expiration tag
        final expirationTag = capturedTags.firstWhere(
          (tag) => tag.isNotEmpty && tag[0] == 'expiration',
          orElse: () => [],
        );

        expect(
          expirationTag,
          isNotEmpty,
          reason: 'Expiration tag should be present',
        );
        expect(
          expirationTag.length,
          equals(2),
          reason: 'Expiration tag should have timestamp value',
        );

        // Verify expiration timestamp is approximately 7 days from now
        final expirationTimestamp = int.parse(expirationTag[1]);
        final expectedExpiration =
            DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
        const tolerance = 60; // Allow 60 seconds tolerance for test execution time

        expect(
          expirationTimestamp,
          closeTo(expectedExpiration, tolerance),
          reason: 'Expiration should be approximately 7 days from now',
        );

        // Verify custom tags are also present
        final dTag = capturedTags.firstWhere(
          (tag) => tag.isNotEmpty && tag[0] == 'd',
          orElse: () => [],
        );
        expect(dTag, isNotEmpty, reason: 'Custom d tag should be present');
        expect(dTag[1], equals('test-tag'));
      },
    );

    test(
      'publishEncryptedEvent does not add expiration tag when one already exists',
      () async {
        // Arrange
        final capturedTags = <List<String>>[];
        const testContent = 'test content';
        final testKind = NostrKind.shardData.value;
        const recipientPubkey = TestHexPubkeys.alice;
        final relays = ['ws://localhost:10547'];
        final customExpiration =
            DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch ~/ 1000;

        // Mock createRumor to capture tags
        when(
          mockGiftWrap.createRumor(
            customPubkey: anyNamed('customPubkey'),
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            tags: anyNamed('tags'),
          ),
        ).thenAnswer((invocation) async {
          final tags = invocation.namedArguments[#tags] as List<List<String>>;
          capturedTags.addAll(tags);
          return mockRumor;
        });

        // Mock toGiftWrap
        when(
          mockGiftWrap.toGiftWrap(
            rumor: anyNamed('rumor'),
            recipientPubkey: anyNamed('recipientPubkey'),
          ),
        ).thenAnswer((_) async => mockGiftWrapEvent);

        // Mock broadcast
        when(
          mockBroadcast.broadcast(
            nostrEvent: anyNamed('nostrEvent'),
            specificRelays: anyNamed('specificRelays'),
          ),
        ).thenReturn(mockBroadcastResponse);

        // Mock broadcast results
        when(mockBroadcastResponse.broadcastDoneFuture).thenAnswer(
          (_) async => [
            RelayBroadcastResponse(
              relayUrl: relays.first,
              broadcastSuccessful: true,
              msg: '',
            ),
          ],
        );

        // Inject mock NDK for testing
        ndkService.setNdkForTesting(mockNdk);

        // Act - Pass tags that already include an expiration tag
        await ndkService.publishEncryptedEvent(
          content: testContent,
          kind: testKind,
          recipientPubkey: recipientPubkey,
          relays: relays,
          tags: [
            ['expiration', customExpiration.toString()],
            ['d', 'test-tag'],
          ],
        );

        // Assert - Verify only one expiration tag exists (the custom one)
        final expirationTags =
            capturedTags.where((tag) => tag.isNotEmpty && tag[0] == 'expiration').toList();

        expect(
          expirationTags.length,
          equals(1),
          reason: 'Should have exactly one expiration tag',
        );
        expect(
          expirationTags[0][1],
          equals(customExpiration.toString()),
          reason: 'Should use the custom expiration timestamp, not add a new one',
        );

        // Verify custom tags are also present
        final dTag = capturedTags.firstWhere(
          (tag) => tag.isNotEmpty && tag[0] == 'd',
          orElse: () => [],
        );
        expect(dTag, isNotEmpty, reason: 'Custom d tag should be present');
      },
    );
  });
}
