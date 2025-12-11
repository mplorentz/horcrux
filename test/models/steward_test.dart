import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

void main() {
  group('KeyHolder', () {
    // Helper function to create KeyHolder records directly for testing
    Steward createTestKeyHolder(String pubkey, {String? name}) {
      return (
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
        isOwner: false,
      );
    }

    test('should return bech32 npub when pubkey is in hex format', () {
      // Given: A KeyHolder with valid hex pubkey from the test npub (Nostr convention: no 0x prefix)
      const hexPubkey =
          'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final keyHolder = createTestKeyHolder(hexPubkey, name: 'Test Steward');

      // When: Getting the npub
      final npub = keyHolder.npub;

      // Then: Should return a valid bech32 npub
      expect(npub, isNotNull);
      expect(npub, startsWith('npub1'));
      expect(npub!.length, greaterThan(60));
      expect(npub.length, lessThan(70));

      // Verify it matches the expected npub
      expect(
        npub,
        equals(
          'npub16zsllwrkrwt5emz2805vhjewj6nsjrw0ge0latyrn2jv5gxf5k0q5l92l7',
        ),
      );
    });

    test('should return bech32 npub when pubkey is hex without 0x prefix', () {
      // Given: A KeyHolder with hex pubkey without 0x prefix (Nostr convention)
      const hexPubkey =
          'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final keyHolder = createTestKeyHolder(hexPubkey, name: 'Test Steward');

      // When: Getting the npub
      final npub = keyHolder.npub;

      // Then: Should return a valid bech32 npub
      expect(npub, isNotNull);
      expect(npub, startsWith('npub1'));
      expect(npub!.length, greaterThan(60));
      expect(npub.length, lessThan(70));

      // Verify it matches the expected npub
      expect(
        npub,
        equals(
          'npub16zsllwrkrwt5emz2805vhjewj6nsjrw0ge0latyrn2jv5gxf5k0q5l92l7',
        ),
      );
    });

    test('displayName uses npub when name is null', () {
      // Given: A KeyHolder with hex pubkey (Nostr convention: no 0x prefix)
      const hexPubkey =
          'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
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
      const hexPubkey =
          'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';
      final keyHolder = createTestKeyHolder(hexPubkey, name: 'Alice');

      // When: Getting the display name
      final displayName = keyHolder.displayName;

      // Then: Should return the name, not npub
      expect(displayName, equals('Alice'));
    });
  });
}
