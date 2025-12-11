# Implementation Plan: Lost Device Recovery

**Branch**: `007-lost-device-recovery` | **Date**: 2025-01-09 | **Spec**: [spec.md](./spec.md)  
**Parent Plan**: Owner-Initiated Vault Recovery (Phases 8-11)

---

## Summary

Enable vault owners who lost their device to recover from a fresh Horcrux installation. Implementation involves refactoring onboarding to support recovery entry, creating recovery initiation links, processing links as a steward, and routing shard responses to the owner's temporary key.

---

## Technical Context

**Language/Version**: Dart 3.5.3, Flutter 3.35.0  
**Primary Dependencies**: flutter_riverpod, ndk (Nostr), app_links, shared_preferences

**New Files**:
- `lib/screens/what_brings_you_screen.dart`
- `lib/screens/owner_recovery_screen.dart`
- `lib/screens/steward_recovery_accept_screen.dart`
- `lib/models/recovery_initiation_link.dart`

**Modified Files**:
- `lib/screens/onboarding_screen.dart`
- `lib/services/deep_link_service.dart`
- `lib/services/recovery_service.dart`
- `lib/services/ndk_service.dart`
- `lib/models/recovery_request.dart`
- `lib/models/vault.dart`

---

## Implementation Approach

### Part A: Onboarding Refactor (Phase 8)

Create new entry point screen after welcome:

```dart
// lib/screens/what_brings_you_screen.dart
class WhatBringsYouScreen extends StatelessWidget {
  // Three cards:
  // 1. "I received an invitation" → invitation entry flow
  // 2. "I need to recover my vault" → owner recovery flow
  // 3. "I want to start backing up" → existing AccountChoiceScreen
}
```

Update onboarding flow:
```dart
// In OnboardingScreen, navigate to WhatBringsYouScreen
// instead of directly to AccountChoiceScreen
```

### Part B: Recovery Initiation Link (Phase 9)

Create recovery flow for owner on fresh device:

```dart
// lib/screens/owner_recovery_screen.dart
class OwnerRecoveryScreen extends ConsumerStatefulWidget {
  // 1. Generate temp keypair automatically
  // 2. Form: vault name, owner name
  // 3. Generate link with embedded data
  // 4. Share functionality
  // 5. "I've sent the link" → waiting screen
}
```

Create link model:
```dart
// lib/models/recovery_initiation_link.dart
typedef RecoveryInitiationLink = ({
  String code,
  String ownerTempPubkey,
  String vaultName,
  String ownerName,
  List<String> relayUrls,
  DateTime createdAt,
});

RecoveryInitiationLink createRecoveryInitiationLink({...});
String recoveryInitiationLinkToUrl(RecoveryInitiationLink link);
RecoveryInitiationLink? parseRecoveryInitiationUrl(Uri uri);
```

### Part C: Steward Processes Link (Phase 10)

Handle `/recover/` deep links:

```dart
// In DeepLinkService
Future<void> _processRecoveryLink(Uri uri) async {
  final linkData = parseRecoveryInitiationLink(uri);
  // Navigate to StewardRecoveryAcceptScreen
}

// lib/screens/steward_recovery_accept_screen.dart
class StewardRecoveryAcceptScreen extends ConsumerStatefulWidget {
  final RecoveryInitiationLinkData linkData;
  
  // Show: owner's claimed name, vault name
  // List: vaults steward holds keys for
  // Action: select vault, initiate recovery with ownerRecoveryPubkey
}
```

Update recovery initiation:
```dart
// In RecoveryService.initiateRecovery
Future<RecoveryRequest> initiateRecovery(
  String vaultId, {
  required String initiatorPubkey,
  required List<String> stewardPubkeys,
  required int threshold,
  String? ownerRecoveryPubkey,        // NEW
  List<String>? responseRelayUrls,    // NEW
}) async {
  // Include new fields in RecoveryRequest
}
```

### Part D: Response Routing (Phase 11)

Route responses to owner's temp key:

```dart
// In RecoveryService.sendRecoveryResponseViaNostr
Future<String> sendRecoveryResponseViaNostr(
  RecoveryRequest request,
  ShardData shardData,
  bool approved, {
  required List<String> relays,
}) async {
  // Determine recipient
  final recipient = request.ownerRecoveryPubkey ?? request.initiatorPubkey;
  
  // Determine relays for response
  final responseRelays = request.responseRelayUrls ?? relays;
  
  // Send to recipient via responseRelays
}
```

Owner listens for responses:
```dart
// Owner's fresh device needs to subscribe to events
// addressed to their temp pubkey on the specified relays
```

Store recovery pubkey for validation:
```dart
// When steward approves recovery request with ownerRecoveryPubkey,
// store that pubkey on the vault for future key rotation validation
vault.copyWith(recoveryPubkey: request.ownerRecoveryPubkey);
```

---

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/screens/what_brings_you_screen.dart` | **New** | Entry point with three options |
| `lib/screens/owner_recovery_screen.dart` | **New** | Recovery link generation for owner |
| `lib/screens/steward_recovery_accept_screen.dart` | **New** | Steward processes recovery link |
| `lib/models/recovery_initiation_link.dart` | **New** | Link model and helpers |
| `lib/screens/onboarding_screen.dart` | Modify | Navigate to WhatBringsYouScreen |
| `lib/services/deep_link_service.dart` | Modify | Handle `/recover/` links |
| `lib/services/recovery_service.dart` | Modify | Accept ownerRecoveryPubkey, route responses |
| `lib/services/ndk_service.dart` | Modify | Listen for responses to temp key |
| `lib/models/recovery_request.dart` | Modify | Add ownerRecoveryPubkey, responseRelayUrls |
| `lib/models/vault.dart` | Modify | Add recoveryPubkey field |

---

## Testing Strategy

### Manual Testing

**Onboarding Flow:**
1. Fresh install → see WhatBringsYouScreen
2. Tap each option → verify correct navigation
3. "Recover vault" → see recovery form

**Owner Recovery Link:**
1. Enter vault name + owner name
2. Generate link → verify format
3. Copy/share link
4. Navigate to waiting screen

**Steward Processing:**
1. As steward, tap recovery link
2. See owner's claimed info
3. See list of vaults you steward
4. Select vault → initiate recovery
5. Verify recovery request has ownerRecoveryPubkey

**Full Flow:**
1. Owner generates link on fresh device
2. Steward taps link, initiates recovery
3. Other stewards receive requests, approve
4. Owner receives shards via temp key
5. Owner's vault is reconstructed

### Unit Tests

- `RecoveryInitiationLink` model and URL parsing
- `RecoveryRequest` with `ownerRecoveryPubkey` serialization
- Response routing logic (recipient selection)

### Integration Tests

- Full lost device recovery flow
- Deep link handling for `/recover/` URLs

---

## Risk Assessment

**High Complexity**:
- New onboarding flow affects first-run experience
- Deep link handling for new URL pattern
- Response routing logic is critical path

**Mitigations**:
- Extensive manual testing of onboarding paths
- Reuse existing deep link infrastructure (from invitations)
- Unit tests for response routing logic
- Clear error handling for edge cases

---

## Estimated Effort

- Onboarding refactor: 2-3 hours
- Recovery initiation link: 3-4 hours
- Steward processing: 3-4 hours
- Response routing: 2-3 hours
- Testing: 3-4 hours
- **Total**: 13-18 hours
