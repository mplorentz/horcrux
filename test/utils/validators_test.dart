import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/utils/validators.dart';

void main() {
  group('isValidHexPubkey', () {
    test('validates correct 64-character hex pubkey (lowercase)', () {
      const pubkey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
      expect(isValidHexPubkey(pubkey), isTrue);
    });

    test('validates correct 64-character hex pubkey (uppercase)', () {
      const pubkey = 'AB1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCD'; // 64 chars
      expect(isValidHexPubkey(pubkey), isTrue);
    });

    test('validates correct 64-character hex pubkey (mixed case)', () {
      const pubkey = '3bF0c63Fcb93463407aF97a5e5Ee64fa883d107eF9e558472c4eb9aaaefa459D';
      expect(isValidHexPubkey(pubkey), isTrue);
    });

    test('rejects pubkey with wrong length (too short)', () {
      const pubkey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459'; // 63 chars
      expect(isValidHexPubkey(pubkey), isFalse);
    });

    test('rejects pubkey with wrong length (too long)', () {
      const pubkey =
          '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459da'; // 65 chars
      expect(isValidHexPubkey(pubkey), isFalse);
    });

    test('rejects pubkey with invalid characters', () {
      const pubkey =
          '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459g'; // contains 'g'
      expect(isValidHexPubkey(pubkey), isFalse);
    });

    test('rejects pubkey with 0x prefix', () {
      const pubkey = '0x3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
      expect(isValidHexPubkey(pubkey), isFalse);
    });

    test('rejects empty string', () {
      expect(isValidHexPubkey(''), isFalse);
    });

    test('rejects pubkey with special characters', () {
      const pubkey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459-';
      expect(isValidHexPubkey(pubkey), isFalse);
    });
  });

  group('isValidHexPrivkey', () {
    test('validates correct 64-character hex privkey', () {
      const privkey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
      expect(isValidHexPrivkey(privkey), isTrue);
    });

    test('rejects invalid privkey', () {
      const privkey = 'invalid';
      expect(isValidHexPrivkey(privkey), isFalse);
    });

    test('delegates to isValidHexPubkey', () {
      // Should behave identically to isValidHexPubkey
      const validKey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
      const invalidKey = 'invalid';

      expect(isValidHexPrivkey(validKey), equals(isValidHexPubkey(validKey)));
      expect(
        isValidHexPrivkey(invalidKey),
        equals(isValidHexPubkey(invalidKey)),
      );
    });
  });

  group('isValidEventId', () {
    test('validates correct 64-character hex event ID', () {
      const eventId = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
      expect(isValidEventId(eventId), isTrue);
    });

    test('rejects invalid event ID', () {
      const eventId = 'invalid';
      expect(isValidEventId(eventId), isFalse);
    });

    test('delegates to isValidHexPubkey', () {
      // Should behave identically to isValidHexPubkey
      const validId = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
      const invalidId = 'invalid';

      expect(isValidEventId(validId), equals(isValidHexPubkey(validId)));
      expect(isValidEventId(invalidId), equals(isValidHexPubkey(invalidId)));
    });
  });

  group('isValidHexString', () {
    test('validates hex string of any valid length', () {
      expect(isValidHexString('a'), isTrue);
      expect(isValidHexString('ab'), isTrue);
      expect(isValidHexString('abc'), isTrue);
      expect(isValidHexString('1234567890abcdef'), isTrue);
      expect(
        isValidHexString(
          '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d',
        ),
        isTrue,
      );
    });

    test('validates uppercase hex string', () {
      expect(isValidHexString('ABCDEF'), isTrue);
    });

    test('validates mixed case hex string', () {
      expect(isValidHexString('aBcDeF'), isTrue);
    });

    test('validates numeric-only hex string', () {
      expect(isValidHexString('1234567890'), isTrue);
    });

    test('rejects empty string', () {
      expect(isValidHexString(''), isFalse);
    });

    test('rejects hex string with invalid characters', () {
      expect(isValidHexString('hello'), isFalse); // contains 'h', 'e', 'l', 'o'
      expect(isValidHexString('xyz'), isFalse);
      expect(isValidHexString('123g'), isFalse);
    });

    test('rejects hex string with special characters', () {
      expect(isValidHexString('abc-def'), isFalse);
      expect(isValidHexString('abc def'), isFalse);
      expect(isValidHexString('0x123'), isFalse);
    });
  });

  group('isValidRelayUrl', () {
    test('validates secure WebSocket URL (wss://)', () {
      expect(isValidRelayUrl('wss://relay.example.com'), isTrue);
      expect(isValidRelayUrl('wss://relay.nostr.com'), isTrue);
      expect(isValidRelayUrl('wss://relay.damus.io'), isTrue);
    });

    test('validates insecure WebSocket URL (ws://)', () {
      expect(isValidRelayUrl('ws://localhost:7000'), isTrue);
      expect(isValidRelayUrl('ws://127.0.0.1:7000'), isTrue);
      expect(isValidRelayUrl('ws://relay.example.com'), isTrue);
    });

    test('validates WebSocket URL with path', () {
      expect(isValidRelayUrl('wss://relay.example.com/path'), isTrue);
      expect(isValidRelayUrl('wss://relay.example.com/nostr'), isTrue);
    });

    test('validates WebSocket URL with query parameters', () {
      expect(isValidRelayUrl('wss://relay.example.com?param=value'), isTrue);
    });

    test('rejects HTTP URL', () {
      expect(isValidRelayUrl('https://relay.example.com'), isFalse);
      expect(isValidRelayUrl('http://relay.example.com'), isFalse);
    });

    test('rejects empty string', () {
      expect(isValidRelayUrl(''), isFalse);
    });

    test('rejects invalid URL format', () {
      expect(isValidRelayUrl('not a url'), isFalse);
      expect(isValidRelayUrl('relay.example.com'), isFalse); // missing scheme
    });

    test('rejects URL with empty host', () {
      expect(isValidRelayUrl('wss://'), isFalse);
      expect(isValidRelayUrl('ws://'), isFalse);
    });

    test('rejects non-WebSocket schemes', () {
      expect(isValidRelayUrl('ftp://relay.example.com'), isFalse);
      expect(isValidRelayUrl('file://relay.example.com'), isFalse);
      expect(isValidRelayUrl('mailto:relay@example.com'), isFalse);
    });
  });

  group('isValidInviteCode', () {
    test('validates correct Base64URL invite code', () {
      const code = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
      expect(isValidInviteCode(code), isTrue);
    });

    test('validates Base64URL with hyphens', () {
      expect(isValidInviteCode('abc-def-ghi'), isTrue);
      expect(isValidInviteCode('test-code-123'), isTrue);
    });

    test('validates Base64URL with underscores', () {
      expect(isValidInviteCode('abc_def_ghi'), isTrue);
      expect(isValidInviteCode('test_code_123'), isTrue);
    });

    test('validates Base64URL with mixed characters', () {
      expect(isValidInviteCode('ABC123def-ghi_JKL'), isTrue);
      expect(isValidInviteCode('a1b2c3d4e5f6'), isTrue);
    });

    test('rejects empty string', () {
      expect(isValidInviteCode(''), isFalse);
    });

    test('rejects Base64URL with padding (=)', () {
      expect(isValidInviteCode('abc='), isFalse);
      expect(isValidInviteCode('abc=='), isFalse);
    });

    test('rejects Base64URL with invalid characters (+/)', () {
      expect(isValidInviteCode('abc+def'), isFalse); // contains '+'
      expect(isValidInviteCode('abc/def'), isFalse); // contains '/'
    });

    test('rejects Base64URL with spaces', () {
      expect(isValidInviteCode('abc def'), isFalse);
      expect(isValidInviteCode('test code'), isFalse);
    });

    test('rejects Base64URL with special characters', () {
      expect(isValidInviteCode('abc@def'), isFalse);
      expect(isValidInviteCode('abc#def'), isFalse);
      expect(isValidInviteCode('abc%def'), isFalse);
    });
  });

  group('isValidBase64', () {
    test('validates correct Base64 string', () {
      expect(
        isValidBase64('SGVsbG8gV29ybGQ='),
        isTrue,
      ); // "Hello World" (16 chars, multiple of 4)
      expect(
        isValidBase64('SGVsbG8='),
        isTrue,
      ); // "Hello" (8 chars, multiple of 4)
      expect(
        isValidBase64('SGVsbG8g'),
        isTrue,
      ); // "Hello " (8 chars, multiple of 4, no padding)
    });

    test('validates Base64 with single padding', () {
      expect(isValidBase64('SGVsbG8='), isTrue);
    });

    test('validates Base64 with double padding', () {
      expect(isValidBase64('SGVsbG8gV29ybGQ='), isTrue);
    });

    test('validates Base64 with plus and slash', () {
      expect(isValidBase64('+/=='), isTrue); // valid Base64 characters
      expect(isValidBase64('abc+/def'), isTrue);
    });

    test('rejects empty string', () {
      expect(isValidBase64(''), isFalse);
    });

    test('rejects Base64 with invalid length (not multiple of 4)', () {
      expect(isValidBase64('abc'), isFalse); // 3 chars
      expect(isValidBase64('ab'), isFalse); // 2 chars
      expect(isValidBase64('a'), isFalse); // 1 char
    });

    test('rejects Base64 with invalid characters', () {
      expect(isValidBase64('abc-def'), isFalse); // contains '-'
      expect(isValidBase64('abc_def'), isFalse); // contains '_'
      expect(isValidBase64('abc def'), isFalse); // contains space
    });

    test('rejects Base64 with too much padding', () {
      expect(isValidBase64('abc==='), isFalse); // 3 padding chars
    });

    test('rejects Base64 with invalid padding position', () {
      expect(isValidBase64('=abc'), isFalse); // padding at start
      expect(isValidBase64('ab=c'), isFalse); // padding in middle
    });
  });

  group('isValidBase64Url', () {
    test('validates correct Base64URL string', () {
      expect(isValidBase64Url('SGVsbG8gV29ybGQ'), isTrue);
      expect(isValidBase64Url('abc123DEF'), isTrue);
      expect(isValidBase64Url('test-code_123'), isTrue);
    });

    test('validates Base64URL with hyphens and underscores', () {
      expect(isValidBase64Url('abc-def-ghi'), isTrue);
      expect(isValidBase64Url('abc_def_ghi'), isTrue);
      expect(isValidBase64Url('abc-def_123'), isTrue);
    });

    test('rejects empty string', () {
      expect(isValidBase64Url(''), isFalse);
    });

    test('rejects Base64URL with padding', () {
      expect(isValidBase64Url('abc='), isFalse);
      expect(isValidBase64Url('abc=='), isFalse);
    });

    test('rejects Base64URL with plus and slash', () {
      expect(isValidBase64Url('abc+def'), isFalse); // contains '+'
      expect(isValidBase64Url('abc/def'), isFalse); // contains '/'
    });

    test('rejects Base64URL with spaces', () {
      expect(isValidBase64Url('abc def'), isFalse);
    });

    test('rejects Base64URL with special characters', () {
      expect(isValidBase64Url('abc@def'), isFalse);
      expect(isValidBase64Url('abc#def'), isFalse);
    });
  });

  group('isValidVaultId', () {
    test('validates non-empty vault ID', () {
      expect(isValidVaultId('vault-123'), isTrue);
      expect(isValidVaultId('uuid-format-id'), isTrue);
      expect(isValidVaultId('a'), isTrue);
    });

    test('validates vault ID with whitespace (trimmed)', () {
      expect(isValidVaultId('  vault-123  '), isTrue);
      expect(isValidVaultId(' vault '), isTrue);
    });

    test('rejects empty string', () {
      expect(isValidVaultId(''), isFalse);
    });

    test('rejects vault ID with only whitespace', () {
      expect(isValidVaultId('   '), isFalse);
      expect(isValidVaultId('\t'), isFalse);
      expect(isValidVaultId('\n'), isFalse);
    });
  });

  group('isValidName', () {
    test('validates non-empty name', () {
      expect(isValidName('Alice'), isTrue);
      expect(isValidName('Bob Smith'), isTrue);
      expect(isValidName('a'), isTrue);
    });

    test('validates name with whitespace (trimmed)', () {
      expect(isValidName('  Alice  '), isTrue);
      expect(isValidName(' Bob Smith '), isTrue);
    });

    test('rejects empty string', () {
      expect(isValidName(''), isFalse);
    });

    test('rejects name with only whitespace', () {
      expect(isValidName('   '), isFalse);
      expect(isValidName('\t'), isFalse);
      expect(isValidName('\n'), isFalse);
      expect(isValidName('\r\n'), isFalse);
    });

    test('validates name with special characters', () {
      expect(isValidName("O'Brien"), isTrue);
      expect(isValidName('José'), isTrue);
      expect(isValidName('Müller'), isTrue);
    });

    test('validates name with numbers', () {
      expect(isValidName('Alice123'), isTrue);
      expect(isValidName('User2'), isTrue);
    });
  });
}
