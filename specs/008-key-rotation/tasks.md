# Tasks: Post-Recovery Key Management & Key Rotation

**Feature**: 008-key-rotation  
**Branch**: `008-key-rotation`  
**Prerequisites**: plan.md, data-model.md, 007-lost-device-recovery complete

---

## Task Format

`[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)

---

## Phase 1: Key Detection Utilities

- [ ] T001 Create `lib/utils/key_detection.dart` with `detectNostrKeys` function (regex patterns for nsec1, npub1, hex keys)
- [ ] T002 Add `isValidNsec` validation function to `lib/utils/key_detection.dart` (decode and verify using NDK)
- [ ] T003 [P] Add `keyRotation` kind (1360) to `lib/models/nostr_kinds.dart`

---

## Phase 2: UI Stubs - Recovery Complete (Outside-In)

- [ ] T004 Create `RecoveryCompleteScreen` stub in `lib/screens/recovery_complete_screen.dart` (key detected UI, no key UI, non-functional buttons)
- [ ] T005 Manual verification: View recovery complete screen with both key-detected and no-key states

---

## Phase 3: UI Stubs - Key Rotation (Outside-In)

- [ ] T006 Create `KeyRotationScreen` stub in `lib/screens/key_rotation_screen.dart` (eligible/ineligible steward lists, send button)
- [ ] T007 Manual verification: View key rotation screen layout

---

## Phase 4: Recovery Complete Implementation

- [ ] T008 Implement key scanning in `RecoveryCompleteScreen`:
  - On init, load vault content
  - Call `detectNostrKeys` on content
  - Update UI based on results

- [ ] T009 Implement "Switch to Recovered Key" flow:
  - Validate selected nsec
  - Show confirmation dialog
  - Call LoginService to switch key
  - Navigate to main app

- [ ] T010 Add `switchToRecoveredKey` to `lib/services/login_service.dart`:
  - Validate nsec format
  - Decode nsec to keypair
  - Store new keypair securely
  - Delete temp recovery key
  - Reinitialize services

- [ ] T011 Implement "Continue with Current Key" flow:
  - Dismiss recovery complete screen
  - Navigate to vault detail or main app

- [ ] T012 Handle multiple keys found:
  - Show list of detected keys
  - Allow user to select which to use
  - Proceed with selected key

- [ ] T013 Handle no keys found:
  - Show alternative options
  - "Continue with current key"
  - "Import key from settings"

---

## Phase 5: Navigate to Recovery Complete

- [ ] T014 Update recovery flow to navigate to `RecoveryCompleteScreen` after successful vault reconstruction
- [ ] T015 Pass vaultId and recoveryRequestId to `RecoveryCompleteScreen`

---

## Phase 6: Key Rotation Sending

- [ ] T016 Add `sendKeyRotationToStewards` to `lib/services/recovery_service.dart`:
  - Accept vaultId, oldPubkey, newPubkey
  - Get vault and backup config
  - Filter to stewards with shards (they participated in recovery)
  - Create rotation payload
  - Send encrypted event to each

- [ ] T017 Implement `KeyRotationScreen`:
  - Load vault and steward list
  - Determine eligible stewards (participated in recovery)
  - Determine ineligible stewards (didn't participate)
  - Display both lists with explanation

- [ ] T018 Implement "Send Key Rotation" in `KeyRotationScreen`:
  - Show confirmation dialog
  - Call `sendKeyRotationToStewards`
  - Show progress/result
  - Handle partial failures gracefully

- [ ] T019 Add "Notify Stewards of Key Change" action to vault settings (post-recovery):
  - Only show if vault was recovered via lost device flow
  - Navigate to KeyRotationScreen

---

## Phase 7: Key Rotation Receiving

- [ ] T020 Add `processKeyRotationEvent` to `lib/services/recovery_service.dart`:
  - Parse event payload
  - Find local vault by vault_id
  - Validate sender against recoveryPubkey
  - Update vault.ownerPubkey on success
  - Log warning on failure

- [ ] T021 Update `NdkService` to listen for key rotation events (kind 1360)

- [ ] T022 Wire up key rotation event stream to `processKeyRotationEvent`

- [ ] T023 Add UI notification for steward when rotation is received and processed:
  - Show snackbar or notification
  - "Vault owner has changed their key"

---

## Phase 8: Edge Cases

- [ ] T024 Handle invalid nsec format when switching (show error, allow retry)
- [ ] T025 Handle key decode failure (show error with helpful message)
- [ ] T026 Handle rotation to vault that doesn't exist locally (ignore gracefully)
- [ ] T027 Handle rotation from unknown pubkey (log warning, reject)
- [ ] T028 Handle network failures during rotation send (retry logic, user feedback)

---

## Phase 9: Testing

- [ ] T029 [P] Unit test: `detectNostrKeys` patterns in `test/utils/key_detection_test.dart`
- [ ] T030 [P] Unit test: `isValidNsec` validation in `test/utils/key_detection_test.dart`
- [ ] T031 [P] Unit test: Key rotation validation logic in `test/services/recovery_service_test.dart`
- [ ] T032 [P] Unit test: Key rotation event creation in `test/services/recovery_service_test.dart`
- [ ] T033 [P] Widget test: `RecoveryCompleteScreen` states in `test/screens/recovery_complete_screen_test.dart`
- [ ] T034 [P] Widget test: `KeyRotationScreen` in `test/screens/key_rotation_screen_test.dart`
- [ ] T035 Integration test: Key switch flow in `test/integration/key_switch_test.dart`
- [ ] T036 Integration test: Key rotation send/receive in `test/integration/key_rotation_test.dart`

---

## Dependencies

```
T001-T002 → T008-T013 (detection before use)
T003 → T016-T023 (event kind before rotation)
T004 → T005 (stub before verification)
T005 → T008-T013 (verification before implementation)
T006 → T007 (stub before verification)
T007 → T017-T019 (verification before implementation)
T008-T013 → T014-T015 (screen before navigation)
T010 → T008-T009 (service before UI)
T016 → T017-T019 (service before UI)
T020-T022 → T023 (processing before notification)
T014-T023 → T024-T028 (implementation before edge cases)
T024-T028 → T029-T036 (edge cases before testing)
```

---

## Parallel Execution Examples

```
# Launch T001-T003 together (utilities and constants):
Task: "Create key_detection.dart with detectNostrKeys"
Task: "Add isValidNsec validation function"
Task: "Add keyRotation kind (1360) to nostr_kinds.dart"

# Launch T029-T034 together (unit/widget tests):
Task: "Unit test detectNostrKeys patterns"
Task: "Unit test isValidNsec validation"
Task: "Unit test key rotation validation logic"
Task: "Unit test key rotation event creation"
Task: "Widget test RecoveryCompleteScreen"
Task: "Widget test KeyRotationScreen"
```

---

## Validation Checklist

- [ ] nsec patterns correctly detected in vault content
- [ ] Multiple nsec patterns handled (user can choose)
- [ ] Key switch successfully authenticates with recovered key
- [ ] Temp key cleaned up after switch
- [ ] Key rotation event has correct structure (kind 1360)
- [ ] Rotation only sent to stewards who participated in recovery
- [ ] Stewards correctly validate rotation (check recoveryPubkey)
- [ ] Invalid rotation attempts rejected and logged
- [ ] Vault ownerPubkey updated on successful rotation
- [ ] Owner informed which stewards can/cannot receive rotation
