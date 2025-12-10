# Implementation Plan: Post-Recovery Key Management & Key Rotation

**Branch**: `008-key-rotation` | **Date**: 2025-01-09 | **Spec**: [spec.md](./spec.md)  
**Parent Plan**: Owner-Initiated Vault Recovery (Phases 11-12)

---

## Summary

Enable post-recovery key management: detect Nostr keys in recovered content, offer to switch to recovered key, and notify stewards of key changes. Stewards validate rotation requests using the `recoveryPubkey` they stored during recovery approval.

---

## Technical Context

**Language/Version**: Dart 3.5.3, Flutter 3.35.0  
**Primary Dependencies**: flutter_riverpod, ndk (Nostr), bip340 (key handling)

**New Files**:
- `lib/screens/recovery_complete_screen.dart`
- `lib/screens/key_rotation_screen.dart`
- `lib/utils/key_detection.dart`

**Modified Files**:
- `lib/services/recovery_service.dart`
- `lib/services/ndk_service.dart`
- `lib/services/login_service.dart`
- `lib/models/nostr_kinds.dart`

---

## Implementation Approach

### Part A: Key Detection (Phase 11)

Create utility for scanning content:

```dart
// lib/utils/key_detection.dart

/// Scan text content for Nostr key patterns
List<String> detectNostrKeys(String content) {
  // Match nsec1... pattern (Bech32 encoded private key)
  final nsecRegex = RegExp(r'nsec1[a-zA-HJ-NP-Z0-9]{58}');
  final matches = nsecRegex.allMatches(content);
  return matches.map((m) => m.group(0)!).toList();
}

/// Validate an nsec is properly formatted and can be decoded
bool isValidNsec(String nsec) {
  try {
    // Use NDK or bip340 to decode and validate
    final keypair = KeyPair.fromNsec(nsec);
    return keypair != null;
  } catch (e) {
    return false;
  }
}
```

### Part B: Recovery Complete Screen (Phase 11)

Show appropriate UI based on key detection:

```dart
// lib/screens/recovery_complete_screen.dart
class RecoveryCompleteScreen extends ConsumerStatefulWidget {
  final String vaultId;
  final String recoveryRequestId;
  
  @override
  _RecoveryCompleteScreenState createState() => _RecoveryCompleteScreenState();
}

class _RecoveryCompleteScreenState extends ConsumerState<RecoveryCompleteScreen> {
  List<String> _detectedKeys = [];
  
  @override
  void initState() {
    super.initState();
    _scanForKeys();
  }
  
  Future<void> _scanForKeys() async {
    final vault = await ref.read(vaultRepositoryProvider).getVault(widget.vaultId);
    if (vault?.content != null) {
      setState(() {
        _detectedKeys = detectNostrKeys(vault!.content!);
      });
    }
  }
  
  // UI shows different options based on _detectedKeys
}
```

### Part C: Key Switch (Phase 11)

Implement key switching:

```dart
// In login_service.dart
Future<void> switchToRecoveredKey(String nsec) async {
  // 1. Validate nsec
  if (!isValidNsec(nsec)) {
    throw ArgumentError('Invalid Nostr key format');
  }
  
  // 2. Create keypair from nsec
  final keypair = KeyPair.fromNsec(nsec);
  
  // 3. Store new keypair securely
  await _secureStorage.write(key: 'nostr_private_key', value: keypair.privateKey);
  
  // 4. Clean up temp key (if exists)
  await _secureStorage.delete(key: 'temp_recovery_key');
  
  // 5. Reinitialize services with new key
  // ...
}
```

### Part D: Key Rotation (Phase 12)

Add new Nostr event kind:

```dart
// In nostr_kinds.dart
enum NostrKind {
  // ... existing kinds ...
  keyRotation(1360),
}
```

Implement rotation sending:

```dart
// In recovery_service.dart
Future<List<String>> sendKeyRotationToStewards(
  String vaultId,
  String oldPubkey,
  String newPubkey,
) async {
  final vault = await repository.getVault(vaultId);
  final stewards = vault?.backupConfig?.stewards ?? [];
  
  // Filter to stewards who have recoveryPubkey set
  // (they participated in recovery)
  final eligibleStewards = stewards.where((s) => 
    s.pubkey != null && 
    // Check if vault has recoveryPubkey for this steward's shard
    true // Logic to determine eligibility
  );
  
  final payload = {
    'type': 'key_rotation',
    'vault_id': vaultId,
    'old_pubkey': oldPubkey,
    'new_pubkey': newPubkey,
    'rotated_at': DateTime.now().toIso8601String(),
  };
  
  // Send to each eligible steward
  final eventIds = await _ndkService.publishEncryptedEventToMultiple(
    content: json.encode(payload),
    kind: NostrKind.keyRotation.value,
    recipientPubkeys: eligibleStewards.map((s) => s.pubkey!).toList(),
    // ...
  );
  
  return eventIds;
}
```

Implement rotation receiving:

```dart
// In recovery_service.dart or new key_rotation_service.dart
Future<void> processKeyRotationEvent(Nip01Event event) async {
  final payload = json.decode(event.content);
  final vaultId = payload['vault_id'];
  final oldPubkey = payload['old_pubkey'];
  final newPubkey = payload['new_pubkey'];
  
  // Find vault
  final vault = await repository.getVault(vaultId);
  if (vault == null) return;
  
  // Validate: sender must match recoveryPubkey
  if (vault.recoveryPubkey != event.pubKey) {
    Log.warning('Key rotation rejected: sender ${event.pubKey} does not match recoveryPubkey ${vault.recoveryPubkey}');
    return;
  }
  
  // Update vault owner
  final updatedVault = vault.copyWith(ownerPubkey: newPubkey);
  await repository.saveVault(updatedVault);
  
  Log.info('Key rotation accepted for vault $vaultId: $oldPubkey -> $newPubkey');
}
```

---

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/screens/recovery_complete_screen.dart` | **New** | Post-recovery UI with key detection |
| `lib/screens/key_rotation_screen.dart` | **New** | UI for sending rotation to stewards |
| `lib/utils/key_detection.dart` | **New** | Utilities for scanning content for keys |
| `lib/services/recovery_service.dart` | Modify | Add sendKeyRotation, processKeyRotation |
| `lib/services/login_service.dart` | Modify | Add switchToRecoveredKey |
| `lib/services/ndk_service.dart` | Modify | Listen for key rotation events |
| `lib/models/nostr_kinds.dart` | Modify | Add keyRotation kind (1360) |

---

## Testing Strategy

### Manual Testing

**Key Detection:**
1. Create vault with nsec in content
2. Complete recovery
3. Verify key detected and prompt shown
4. Switch to recovered key
5. Verify authenticated with recovered key

**Key Rotation:**
1. Complete lost device recovery
2. Navigate to key rotation screen
3. Verify eligible/ineligible stewards shown
4. Send rotation
5. As steward, verify rotation received and validated
6. Verify vault owner updated

### Unit Tests

- Key detection regex patterns
- Nsec validation
- Rotation event creation
- Rotation validation logic

### Integration Tests

- Full key switch flow
- Full key rotation flow with steward validation

---

## Risk Assessment

**Medium Risk**:
- Key handling is security-sensitive
- Rotation validation must be bulletproof

**Mitigations**:
- Use existing NDK/bip340 for key operations
- Extensive logging for rotation attempts
- Clear error messages for validation failures
- Unit tests for all validation paths

---

## Estimated Effort

- Key detection utilities: 1-2 hours
- Recovery complete screen: 2-3 hours
- Key switch implementation: 2 hours
- Key rotation sending: 2-3 hours
- Key rotation receiving: 2-3 hours
- Testing: 2-3 hours
- **Total**: 11-16 hours
