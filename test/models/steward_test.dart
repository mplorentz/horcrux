import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

void main() {
  group('KeyHolder', () {
    // Helper function to create KeyHolder records directly for testing
    Steward createTestKeyHolder(String pubkey,
        {String? name, bool isOwner = false, String? contactInfo}) {
      return Steward(
        id: _uuid.v4(),
        pubkey: pubkey,
        name: name,
        inviteCode: null,
        status: StewardStatus.awaitingKey,
        lastSeen: null,
        keyShare: null,
        giftWrapEventId: null,
        acknowledgedAt: null,
        acknowledgmentEventId: null,
        acknowledgedDistributionVersion: null,
        isOwner: isOwner,
        contactInfo: contactInfo,
      );
    }

    test('should return bech32 npub when pubkey is in hex format', () {
      // Given: A KeyHolder with valid hex pubkey from the test npub (Nostr convention: no 0x prefix)
      const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final keyHolder = createTestKeyHolder(hexPubkey, name: 'Test Steward');

      // When: Getting the npub
      final npub = keyHolder.npub;

      // Then: Should return a valid bech32 npub
      expect(npub, isNotNull);
      expect(npub, startsWith('npub1'));
      expect(npub!.length, greaterThan(60));
      expect(npub.length, lessThan(70));

      // Verify it matches the expected npub
      expect(npub, equals('npub16zsllwrkrwt5emz2805vhjewj6nsjrw0ge0latyrn2jv5gxf5k0q5l92l7'));
    });

    test('should return bech32 npub when pubkey is hex without 0x prefix', () {
      // Given: A KeyHolder with hex pubkey without 0x prefix (Nostr convention)
      const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final keyHolder = createTestKeyHolder(hexPubkey, name: 'Test Steward');

      // When: Getting the npub
      final npub = keyHolder.npub;

      // Then: Should return a valid bech32 npub
      expect(npub, isNotNull);
      expect(npub, startsWith('npub1'));
      expect(npub!.length, greaterThan(60));
      expect(npub.length, lessThan(70));

      // Verify it matches the expected npub
      expect(npub, equals('npub16zsllwrkrwt5emz2805vhjewj6nsjrw0ge0latyrn2jv5gxf5k0q5l92l7'));
    });

    test('displayName uses npub when name is null', () {
      // Given: A KeyHolder with hex pubkey (Nostr convention: no 0x prefix)
      const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final keyHolder = createTestKeyHolder(
        hexPubkey,
        name: null,
      ); // No name, should use npub for display

      // When: Getting the display name
      final displayName = keyHolder.displayName;

      // Then: Should return truncated npub
      expect(displayName, startsWith('npub1'));
      expect(displayName, contains('...'));
      expect(displayName.length, equals(19)); // 8 + 3 + 8 = 19
    });

    test('displayName uses name when provided', () {
      // Given: A KeyHolder with hex pubkey and name (Nostr convention: no 0x prefix)
      const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final keyHolder = createTestKeyHolder(hexPubkey, name: 'Alice');

      // When: Getting the display name
      final displayName = keyHolder.displayName;

      // Then: Should return the name, not npub
      expect(displayName, equals('Alice'));
    });

    // T026: Tests for isOwner field
    group('isOwner field', () {
      test('createSteward creates steward with isOwner false by default', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final steward = createSteward(pubkey: hexPubkey, name: 'Alice');

        expect(steward.isOwner, isFalse);
      });

      test('createSteward can create steward with isOwner true', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final steward = createSteward(pubkey: hexPubkey, name: 'Me', isOwner: true);

        expect(steward.isOwner, isTrue);
      });

      test('createOwnerSteward creates steward with isOwner true', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final steward = createOwnerSteward(pubkey: hexPubkey);

        expect(steward.isOwner, isTrue);
        expect(steward.name, equals('You')); // Default name for owner
      });

      test('createOwnerSteward accepts custom name', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final steward = createOwnerSteward(pubkey: hexPubkey, name: 'Me (Owner)');

        expect(steward.isOwner, isTrue);
        expect(steward.name, equals('Me (Owner)'));
      });

      test('createInvitedSteward creates steward with isOwner false', () {
        final steward = createInvitedSteward(name: 'Bob', inviteCode: 'ABC123');

        expect(steward.isOwner, isFalse);
        expect(steward.pubkey, isNull);
      });

      test('copySteward preserves isOwner by default', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final original = createOwnerSteward(pubkey: hexPubkey);
        final copy = original.copyWith(name: 'New Name');

        expect(copy.isOwner, isTrue);
        expect(copy.name, equals('New Name'));
      });

      test('copySteward can change isOwner', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final original = createOwnerSteward(pubkey: hexPubkey);
        final copy = original.copyWith(isOwner: false);

        expect(copy.isOwner, isFalse);
      });

      test('stewardToJson includes isOwner field', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final steward = createOwnerSteward(pubkey: hexPubkey);
        final json = stewardToJson(steward);

        expect(json['isOwner'], isTrue);
      });

      test('stewardFromJson parses isOwner field', () {
        final json = {
          'id': 'test-id',
          'pubkey': 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          'name': 'Owner',
          'status': 'holdingKey',
          'isOwner': true,
        };
        final steward = stewardFromJson(json);

        expect(steward.isOwner, isTrue);
      });

      test('stewardFromJson defaults isOwner to false for backward compatibility', () {
        final json = {
          'id': 'test-id',
          'pubkey': 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          'name': 'Old Steward',
          'status': 'holdingKey',
          // isOwner field is missing
        };
        final steward = stewardFromJson(json);

        expect(steward.isOwner, isFalse);
      });
    });

    // Tests for contactInfo field
    group('contactInfo field', () {
      test('createSteward creates steward with contactInfo when provided', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final steward = createSteward(
          pubkey: hexPubkey,
          name: 'Alice',
          contactInfo: 'alice@example.com',
        );

        expect(steward.contactInfo, equals('alice@example.com'));
      });

      test('createSteward creates steward with null contactInfo by default', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final steward = createSteward(pubkey: hexPubkey, name: 'Alice');

        expect(steward.contactInfo, isNull);
      });

      test('createSteward throws error if contactInfo exceeds max length', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final longContactInfo = 'a' * (maxContactInfoLength + 1);

        expect(
          () => createSteward(
            pubkey: hexPubkey,
            name: 'Alice',
            contactInfo: longContactInfo,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('createSteward accepts contactInfo at max length', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final maxLengthContactInfo = 'a' * maxContactInfoLength;
        final steward = createSteward(
          pubkey: hexPubkey,
          name: 'Alice',
          contactInfo: maxLengthContactInfo,
        );

        expect(steward.contactInfo, equals(maxLengthContactInfo));
      });

      test('createInvitedSteward creates steward with contactInfo when provided', () {
        final steward = createInvitedSteward(
          name: 'Bob',
          inviteCode: 'ABC123',
          contactInfo: 'bob@example.com',
        );

        expect(steward.contactInfo, equals('bob@example.com'));
      });

      test('copySteward preserves contactInfo by default', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final original = createSteward(
          pubkey: hexPubkey,
          name: 'Alice',
          contactInfo: 'alice@example.com',
        );
        final copy = original.copyWith(name: 'New Name');

        expect(copy.contactInfo, equals('alice@example.com'));
      });

      test('copySteward can update contactInfo', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final original = createSteward(
          pubkey: hexPubkey,
          name: 'Alice',
          contactInfo: 'alice@example.com',
        );
        final copy = original.copyWith(contactInfo: 'newemail@example.com');

        expect(copy.contactInfo, equals('newemail@example.com'));
      });

      test('stewardToJson includes contactInfo field', () {
        const hexPubkey = 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
        final steward = createSteward(
          pubkey: hexPubkey,
          name: 'Alice',
          contactInfo: 'alice@example.com',
        );
        final json = stewardToJson(steward);

        expect(json['contactInfo'], equals('alice@example.com'));
      });

      test('stewardFromJson parses contactInfo field', () {
        final json = {
          'id': 'test-id',
          'pubkey': 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          'name': 'Alice',
          'status': 'holdingKey',
          'contactInfo': 'alice@example.com',
        };
        final steward = stewardFromJson(json);

        expect(steward.contactInfo, equals('alice@example.com'));
      });

      test('stewardFromJson defaults contactInfo to null for backward compatibility', () {
        final json = {
          'id': 'test-id',
          'pubkey': 'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
          'name': 'Old Steward',
          'status': 'holdingKey',
          // contactInfo field is missing
        };
        final steward = stewardFromJson(json);

        expect(steward.contactInfo, isNull);
      });
    });
  });
}
