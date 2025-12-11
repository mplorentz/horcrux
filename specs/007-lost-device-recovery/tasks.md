# Tasks: Lost Device Recovery

**Feature**: 007-lost-device-recovery  
**Branch**: `007-lost-device-recovery`  
**Prerequisites**: plan.md, data-model.md

---

## Task Format

`[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)

---

## Phase 1: Model Changes

- [ ] T001 Add `ownerRecoveryPubkey` and `responseRelayUrls` fields to `RecoveryRequest` in `lib/models/recovery_request.dart` (update constructor, copyWith, toJson, fromJson)
- [ ] T002 [P] Add `recoveryPubkey` field to `Vault` in `lib/models/vault.dart` (for key rotation validation)
- [ ] T003 [P] Create `RecoveryInitiationLink` model in `lib/models/recovery_initiation_link.dart` (typedef, factory, toUrl, toJson, fromJson)

---

## Phase 2: UI Stubs - Onboarding (Outside-In)

- [ ] T004 Create `WhatBringsYouScreen` stub in `lib/screens/what_brings_you_screen.dart` (three cards, non-functional navigation)
- [ ] T005 Manual verification: View WhatBringsYouScreen layout and card styling

---

## Phase 3: UI Stubs - Owner Recovery (Outside-In)

- [ ] T006 [P] Create `OwnerRecoveryScreen` stub in `lib/screens/owner_recovery_screen.dart` (form fields, generate button, non-functional)
- [ ] T007 [P] Create "Link Generated" screen/dialog stub (copy button, share button, "I've sent it" button)
- [ ] T008 [P] Create "Waiting for Recovery" screen stub (status display, cancel button)
- [ ] T009 Manual verification: Navigate through owner recovery flow stubs

---

## Phase 4: UI Stubs - Steward Accept (Outside-In)

- [ ] T010 Create `StewardRecoveryAcceptScreen` stub in `lib/screens/steward_recovery_accept_screen.dart` (shows claimed info, vault list, initiate button)
- [ ] T011 Manual verification: View steward accept screen layout

---

## Phase 5: Onboarding Implementation

- [ ] T012 Implement `WhatBringsYouScreen` navigation in `lib/screens/what_brings_you_screen.dart`:
  - "I received an invitation" → prompt for link, then invitation flow
  - "I need to recover my vault" → OwnerRecoveryScreen
  - "I want to start backing up" → AccountChoiceScreen

- [ ] T013 Update `lib/screens/onboarding_screen.dart` to navigate to WhatBringsYouScreen (instead of AccountChoiceScreen)

---

## Phase 6: Recovery Initiation Link Implementation

- [ ] T014 Implement temp key generation in `OwnerRecoveryScreen`:
  - Generate keypair on screen init
  - Store via LoginService (same as normal key)
  - Mark key as temporary (add `isTempRecoveryKey` flag to storage)
  - Display nothing about key to user (just used internally)

- [ ] T014a Add `isTempRecoveryKey` flag to LoginService storage:
  - Store alongside keypair
  - Used to identify temp keys for later cleanup
  - Cleared when user switches to recovered key or creates permanent account

- [ ] T015 Implement link generation in `OwnerRecoveryScreen`:
  - Validate vault name and owner name inputs
  - Default to keydex relay URL (allow user to change)
  - Create RecoveryInitiationLink
  - Generate shareable URL
  - Store link locally for tracking

- [ ] T016 Implement "Link Generated" screen:
  - Display truncated link
  - Copy to clipboard functionality
  - Share via platform share sheet
  - "I've sent the link" navigates to waiting screen

- [ ] T017 Implement "Waiting for Recovery" screen:
  - Listen for recovery responses addressed to temp pubkey
  - Show progress when responses arrive
  - Show completion when threshold met
  - Allow cancellation

---

## Phase 7: Deep Link Handling

- [ ] T018 Add `parseRecoveryInitiationLink` to `lib/services/deep_link_service.dart`:
  - Handle `/recover/{code}` path
  - Extract owner pubkey, vault name, owner name, relay URLs
  - Validate all parameters
  - Return RecoveryInitiationLinkData or throw exception

- [ ] T019 Update `_processLink` in `lib/services/deep_link_service.dart`:
  - Check for `/recover/` path (in addition to `/invite/`)
  - Route to recovery link handler
  - Navigate to StewardRecoveryAcceptScreen

---

## Phase 8: Steward Accept Implementation

- [ ] T020 Implement `StewardRecoveryAcceptScreen`:
  - Display owner's claimed name and vault name
  - Load list of vaults user is steward for
  - Filter/sort to help steward find matching vault
  - Allow selection of vault to recover

- [ ] T021 Implement vault matching hints in steward accept screen:
  - Highlight vaults where owner name matches vault.ownerName
  - Show vault name alongside owner name for each option

- [ ] T022 Implement "Initiate Recovery" action in steward accept screen:
  - Call RecoveryService.initiateRecovery with:
    - ownerRecoveryPubkey from link
    - responseRelayUrls from link
  - Navigate to recovery status screen

---

## Phase 9: Response Routing Implementation

- [ ] T023 Update `RecoveryService.initiateRecovery` to accept `ownerRecoveryPubkey` and `responseRelayUrls` parameters

- [ ] T024 Update `RecoveryService.sendRecoveryRequestViaNostr` to include `ownerRecoveryPubkey` and `responseRelayUrls` in event payload

- [ ] T025 Update `RecoveryService.sendRecoveryResponseViaNostr` to route responses:
  - If `request.ownerRecoveryPubkey` is set, send to that pubkey
  - If `request.responseRelayUrls` is set, use those relays
  - Otherwise use initiatorPubkey and shard relays

- [ ] T026 Update `NdkService` to support listening for events on temp pubkey:
  - Owner's fresh device needs to subscribe to their temp key
  - May need to set up subscription during recovery wait

- [ ] T027 Store `recoveryPubkey` on vault when steward approves:
  - In respondToRecoveryRequest, if request has ownerRecoveryPubkey
  - Update vault with recoveryPubkey = ownerRecoveryPubkey

---

## Phase 10: Edge Cases

- [ ] T028 Handle invalid recovery initiation links (malformed, missing params) in DeepLinkService
- [ ] T029 Handle case where steward has no matching vaults (show helpful message)
- [ ] T030 Handle owner cancellation during wait (clean up temp key, show confirmation)
- [ ] T031 Warn about sending link to multiple stewards (in link generated screen)
- [ ] T032 Handle relay URL differences (requests use shard relays, responses use link relays)
- [ ] T032a Steward adds link's relay URLs to vault config when processing recovery initiation

## Phase 10.5: Vault Stub Creation on Fresh Device

- [ ] T032b Implement automatic vault stub creation when first recovery response arrives:
  - Extract vault metadata from shard data (vault ID, vault name, owner pubkey)
  - Check if vault already exists locally (shouldn't on fresh device)
  - Create vault stub with: id, name, ownerPubkey from shard, content=null, shards=[]
  - Add incoming shard to vault stub
  - Save vault to local storage

- [ ] T032c Handle subsequent recovery responses:
  - Look up existing vault stub by vault ID from shard
  - Add shard to vault.shards list
  - Check if threshold met for reconstruction
  - If threshold met, trigger reconstruction flow

---

## Phase 11: Testing

- [ ] T033 [P] Unit test: `RecoveryInitiationLink` model in `test/models/recovery_initiation_link_test.dart`
- [ ] T034 [P] Unit test: `RecoveryRequest` with new fields in `test/models/recovery_request_test.dart`
- [ ] T035 [P] Unit test: `parseRecoveryInitiationLink` in `test/services/deep_link_service_test.dart`
- [ ] T036 [P] Unit test: Response routing logic in `test/services/recovery_service_test.dart`
- [ ] T037 [P] Widget test: `WhatBringsYouScreen` navigation in `test/screens/what_brings_you_screen_test.dart`
- [ ] T038 [P] Widget test: `OwnerRecoveryScreen` form in `test/screens/owner_recovery_screen_test.dart`
- [ ] T039 [P] Widget test: `StewardRecoveryAcceptScreen` in `test/screens/steward_recovery_accept_screen_test.dart`
- [ ] T040 Integration test: Full lost device recovery flow in `test/integration/lost_device_recovery_test.dart`

---

## Dependencies

```
T001-T003 → T014-T027 (models before implementation)
T004 → T005 (stub before verification)
T005 → T012-T013 (verification before implementation)
T006-T008 → T009 (stubs before verification)
T009 → T014-T017 (verification before implementation)
T010 → T011 (stub before verification)
T011 → T020-T022 (verification before implementation)
T012-T013 → T014-T017 (onboarding before owner recovery)
T003, T018-T019 → T020-T022 (link parsing before steward accept)
T001, T020-T022 → T023-T027 (request fields before response routing)
T023-T027 → T028-T032 (implementation before edge cases)
T028-T032 → T033-T040 (edge cases before testing)
```

---

## Parallel Execution Examples

```
# Launch T001-T003 together (model changes):
Task: "Add ownerRecoveryPubkey and responseRelayUrls to RecoveryRequest"
Task: "Add recoveryPubkey to Vault"
Task: "Create RecoveryInitiationLink model"

# Launch T006-T008 together (owner recovery stubs):
Task: "Create OwnerRecoveryScreen stub"
Task: "Create Link Generated screen stub"
Task: "Create Waiting for Recovery screen stub"

# Launch T033-T039 together (unit/widget tests):
Task: "Unit test RecoveryInitiationLink model"
Task: "Unit test RecoveryRequest with new fields"
Task: "Unit test parseRecoveryInitiationLink"
Task: "Unit test response routing logic"
Task: "Widget test WhatBringsYouScreen"
Task: "Widget test OwnerRecoveryScreen"
Task: "Widget test StewardRecoveryAcceptScreen"
```

---

## Validation Checklist

- [ ] WhatBringsYouScreen shows three options with correct navigation
- [ ] Owner can generate recovery link with vault name and their name
- [ ] Recovery link contains all required parameters
- [ ] Steward can tap link and see owner's claimed info
- [ ] Steward can select vault and initiate recovery
- [ ] Recovery request includes ownerRecoveryPubkey and responseRelayUrls
- [ ] Responses are sent to owner's temp pubkey
- [ ] Responses use relays from recovery initiation link
- [ ] Owner receives shards and can reconstruct vault
- [ ] recoveryPubkey stored on vault after steward approval
