# Data Model: Post-Recovery Key Management & Key Rotation

**Feature**: 008-key-rotation  
**Date**: 2025-01-09

---

## New Models

### Key Detection Result

**File**: `lib/utils/key_detection.dart`

```dart
/// Result of scanning content for Nostr keys
typedef KeyDetectionResult = ({
  List<String> nsecKeys,    // Found nsec1... keys
  List<String> npubKeys,    // Found npub1... keys (informational)
  List<String> hexKeys,     // Found hex private keys (64 chars)
});

/// Scan content for Nostr key patterns
KeyDetectionResult detectNostrKeys(String content) {
  // nsec1 pattern (Bech32 private key)
  final nsecRegex = RegExp(r'nsec1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{58}', caseSensitive: false);
  
  // npub1 pattern (Bech32 public key) - for informational purposes
  final npubRegex = RegExp(r'npub1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{58}', caseSensitive: false);
  
  // Hex private key pattern (64 hex chars, be careful with false positives)
  final hexRegex = RegExp(r'\b[a-fA-F0-9]{64}\b');
  
  return (
    nsecKeys: nsecRegex.allMatches(content).map((m) => m.group(0)!).toSet().toList(),
    npubKeys: npubRegex.allMatches(content).map((m) => m.group(0)!).toSet().toList(),
    hexKeys: hexRegex.allMatches(content).map((m) => m.group(0)!).toSet().toList(),
  );
}

/// Validate nsec format and decodability
bool isValidNsec(String nsec) {
  if (!nsec.startsWith('nsec1')) return false;
  try {
    // Use NDK to decode - this validates checksum too
    final keypair = Nip01.decodeNsec(nsec);
    return keypair != null;
  } catch (e) {
    return false;
  }
}
```

---

## New Nostr Event Kind

### Key Rotation Event (Kind 1360)

**File**: `lib/models/nostr_kinds.dart`

**Addition**:
```dart
enum NostrKind {
  // ... existing kinds ...
  keyRotation(1360),  // NEW: Owner notifies stewards of key change
}
```

**Event Structure**:
```json
{
  "kind": 1360,
  "pubkey": "<new_owner_pubkey>",
  "created_at": 1234567890,
  "tags": [
    ["p", "<steward_pubkey>"],
    ["vault_id", "<vault_id>"],
    ["d", "key_rotation_<vault_id>_<new_pubkey>"]
  ],
  "content": "<encrypted payload>",
  "sig": "..."
}
```

**Encrypted Payload**:
```json
{
  "type": "key_rotation",
  "vault_id": "abc123",
  "old_pubkey": "aabbcc...",
  "new_pubkey": "ddeeff...",
  "recovery_request_id": "req_123",  // Optional reference
  "rotated_at": "2025-01-09T12:00:00Z"
}
```

---

## Existing Models (No Changes Required)

### Vault

Already has `recoveryPubkey` field from feature 007:
```dart
final String? recoveryPubkey;  // Set when steward approves recovery
```

This field is used for validation:
- Set during recovery approval (in feature 007)
- Checked during key rotation validation (this feature)

---

## State Flows

### Post-Recovery Key Detection Flow

```
[Recovery Complete]
        │
        ▼
[Scan vault.content for keys]
        │
   ┌────┴────┐
   │         │
 Keys      No Keys
 Found     Found
   │         │
   ▼         ▼
[Show      [Show
 "Switch    "Continue"
 to Key"    options]
 prompt]
   │
   ├──(user taps "Switch")──▶ [Login with recovered key]
   │                                    │
   │                                    ▼
   │                          [Clean up temp key]
   │                                    │
   │                                    ▼
   │                          [Authenticated with old key]
   │
   └──(user taps "Continue")──▶ [Continue with current key]
```

### Key Rotation Flow

```
[Owner wants to rotate key]
        │
        ▼
[KeyRotationScreen]
        │
        ├── Show eligible stewards (have recoveryPubkey)
        ├── Show ineligible stewards (no recoveryPubkey)
        │
        ▼
[Owner taps "Send Rotation"]
        │
        ▼
[Send key_rotation event to each eligible steward]
        │
        ▼ (on steward device)
[Steward receives key_rotation event]
        │
        ▼
[Validate: event.pubKey == vault.recoveryPubkey?]
        │
   ┌────┴────┐
   │         │
  Yes        No
   │         │
   ▼         ▼
[Update    [Reject,
 vault      log
 owner]     warning]
```

### Steward Eligibility for Rotation

A steward can receive rotation if:
1. They participated in recovery (approved a recovery request)
2. The recovery request had `ownerRecoveryPubkey` set
3. They stored `recoveryPubkey` on the vault when approving

```dart
bool canReceiveRotation(Vault vault, Steward steward) {
  // Steward must have pubkey
  if (steward.pubkey == null) return false;
  
  // Vault must have recoveryPubkey set
  // (indicates steward participated in recovery with ownerRecoveryPubkey)
  return vault.recoveryPubkey != null;
}
```

---

## Validation Logic

### Key Rotation Validation (Steward Side)

```dart
/// Validate a key rotation event
/// Returns true if rotation should be accepted
bool validateKeyRotation({
  required String eventSenderPubkey,  // Who sent the rotation event
  required Vault vault,                // Local vault data
  required Map<String, dynamic> payload,
}) {
  // 1. Check vault has recoveryPubkey (steward participated in recovery)
  if (vault.recoveryPubkey == null) {
    Log.warning('Key rotation rejected: vault has no recoveryPubkey');
    return false;
  }
  
  // 2. Check event sender matches recoveryPubkey
  // The person who recovered must be the one rotating
  if (eventSenderPubkey != vault.recoveryPubkey) {
    Log.warning(
      'Key rotation rejected: sender $eventSenderPubkey '
      'does not match recoveryPubkey ${vault.recoveryPubkey}'
    );
    return false;
  }
  
  // 3. Check new_pubkey matches event sender
  // The rotation must be to the same key that sent the event
  final newPubkey = payload['new_pubkey'] as String?;
  if (newPubkey != eventSenderPubkey) {
    Log.warning('Key rotation rejected: new_pubkey does not match sender');
    return false;
  }
  
  // 4. Check vault_id matches
  final vaultId = payload['vault_id'] as String?;
  if (vaultId != vault.id) {
    Log.warning('Key rotation rejected: vault_id mismatch');
    return false;
  }
  
  return true;
}
```

---

## Security Notes

### Why recoveryPubkey Validation Works

1. **Set at recovery time**: When steward approves recovery with `ownerRecoveryPubkey`, they store it locally
2. **Not transmitted in rotation**: The `recoveryPubkey` stored locally is compared against event sender
3. **Cryptographically verified**: Nostr event signatures prove sender identity
4. **Independent validation**: Each steward validates against their own stored data

### Attack Resistance

- **Impersonation**: Attacker can't forge rotation without the recovery key's private key
- **Replay**: Each rotation is to a specific vault, and steward tracks current owner
- **Race conditions**: Even if multiple rotations attempted, signature validation ensures only valid ones accepted

---

## Backwards Compatibility

- `recoveryPubkey` on Vault was added in feature 007
- Stewards without `recoveryPubkey` simply can't receive rotation (graceful degradation)
- No migration needed
