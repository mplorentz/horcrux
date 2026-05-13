import 'dart:convert';

import 'package:drift/native.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/local_notification_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/push_notification_receiver.dart';

import 'push_notification_receiver_test.mocks.dart';

@GenerateMocks([
  NdkService,
  LocalNotificationService,
  HorcruxNotificationService,
])
void main() {
  group('parseFcmEmbeddedEventJson', () {
    test('returns null when event_json is absent', () {
      expect(parseFcmEmbeddedEventJson({'event_id': 'abc'}), isNull);
    });

    test('accepts a decoded Map', () {
      final map = <String, dynamic>{'kind': 1059, 'id': 'x' * 64};
      expect(
        parseFcmEmbeddedEventJson({'event_json': map}),
        map,
      );
    });

    test('decodes a JSON string (typical FCM Android/iOS)', () {
      final map = <String, dynamic>{'kind': 1059, 'content': 'cipher'};
      final encoded = jsonEncode(map);
      expect(
        parseFcmEmbeddedEventJson({'event_json': encoded}),
        map,
      );
    });

    test('returns null for invalid JSON string', () {
      expect(parseFcmEmbeddedEventJson({'event_json': '{not json'}), isNull);
    });

    test('returns null when event_json is a JSON array', () {
      expect(parseFcmEmbeddedEventJson({'event_json': '[1,2]'}), isNull);
    });
  });

  group('parseFcmEventId', () {
    test('parses string event_id', () {
      expect(
        parseFcmEventId({'event_id': 'ab' * 32}),
        'ab' * 32,
      );
    });

    test('returns null when absent', () {
      expect(parseFcmEventId({}), isNull);
    });
  });

  group('parseFcmRelayHints', () {
    test('parses JSON array string', () {
      expect(
        parseFcmRelayHints({'relay_hints': '["wss://a.com","wss://b.com"]'}),
        ['wss://a.com', 'wss://b.com'],
      );
    });

    test('accepts a decoded List', () {
      expect(
        parseFcmRelayHints({
          'relay_hints': ['wss://r.example/nostr'],
        }),
        ['wss://r.example/nostr'],
      );
    });

    test('returns null for invalid JSON string', () {
      expect(parseFcmRelayHints({'relay_hints': '['}), isNull);
    });
  });

  group('handleNotificationTap dedupe', () {
    late MockNdkService ndkService;
    late MockLocalNotificationService localNotifications;
    late MockHorcruxNotificationService notifierService;
    late PushNotificationReceiver receiver;

    /// Builds an FCM [RemoteMessage] whose `event_json` payload encodes a
    /// minimally-valid kind-1059 gift wrap that [Nip01Event.fromJson] accepts.
    RemoteMessage giftWrapMessage({required String messageId}) {
      final keyPair = Bip340.generatePrivateKey();
      final wrap = {
        'id': 'a' * 64,
        'pubkey': keyPair.publicKey,
        'kind': NostrKind.giftWrap.value,
        'created_at': 1700000000,
        'tags': <List<String>>[],
        'content': 'cipher',
        'sig': 'b' * 128,
      };
      return RemoteMessage(
        messageId: messageId,
        data: {'event_json': jsonEncode(wrap)},
      );
    }

    setUp(() {
      ndkService = MockNdkService();
      localNotifications = MockLocalNotificationService();
      notifierService = MockHorcruxNotificationService();

      when(ndkService.resolveVaultIdForGiftWrap(any)).thenAnswer((_) async => 'vault-1');
      when(ndkService.resolveRecoveryRequestIdForGiftWrap(any)).thenAnswer((_) async => (
            kind: NostrKind.recoveryRequest,
            recoveryRequestId: 'rr-1',
          ));
      when(ndkService.processGiftWrapFromForegroundPush(
        any,
        allowLocalNotification: anyNamed('allowLocalNotification'),
      )).thenAnswer((_) async {});
      when(localNotifications.navigateForKind(
        any,
        any,
        vaultId: anyNamed('vaultId'),
      )).thenAnswer((_) async => true);

      receiver = PushNotificationReceiver(
        localNotifications: localNotifications,
        notifierService: notifierService,
        ndkService: ndkService,
        database: AppDatabase(NativeDatabase.memory()),
      );
    });

    test('ignores duplicate dispatch for the same messageId', () async {
      final message = giftWrapMessage(messageId: 'msg-1');

      await receiver.handleNotificationTap(message);
      await receiver.handleNotificationTap(message);

      verify(ndkService.processGiftWrapFromForegroundPush(
        any,
        allowLocalNotification: false,
      )).called(1);
      verify(localNotifications.navigateForKind(
        any,
        any,
        vaultId: anyNamed('vaultId'),
      )).called(1);
    });

    test('processes distinct messageIds independently', () async {
      await receiver.handleNotificationTap(giftWrapMessage(messageId: 'msg-1'));
      await receiver.handleNotificationTap(giftWrapMessage(messageId: 'msg-2'));

      verify(ndkService.processGiftWrapFromForegroundPush(
        any,
        allowLocalNotification: false,
      )).called(2);
      verify(localNotifications.navigateForKind(
        any,
        any,
        vaultId: anyNamed('vaultId'),
      )).called(2);
    });
  });
}
