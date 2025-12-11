# Tasks: Owner Self-Shard & Content Deletion

**Feature**: 006-owner-shard  
**Branch**: `006-owner-shard`  
**Prerequisites**: plan.md, data-model.md

---

## Task Format

`[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)

---

## Phase 1: Model Changes

- [x] T001 Add `isOwner` boolean field to `Steward` in `lib/models/steward.dart` (default false, update typedef, createSteward, copySteward, toJson, fromJson)
- [x] T002 Add `createOwnerSteward` factory function in `lib/models/steward.dart` (convenience for creating owner steward with isOwner: true)
- [x] T003 [P] Add helper functions to `lib/models/backup_config.dart`: `hasOwnerSteward(config)`, `getOwnerSteward(config)`

---

## Phase 2: UI Stubs - Self-Shard (Outside-In)

- [x] T004 [P] Add "Include yourself as a shard holder" toggle stub to `lib/screens/backup_config_screen.dart` (non-functional UI)
- [x] T005 [P] Add "Owner" badge/indicator stub to `lib/widgets/steward_list.dart` (shows when steward.isOwner is true)
- [x] T006 Manual verification: View backup config screen with toggle, steward list with owner badge

---

## Phase 3: Self-Shard Implementation

- [x] T007 Implement self-shard toggle in `lib/screens/backup_config_screen.dart`:
  - Get current user pubkey
  - When enabled: add owner to stewards list with createOwnerSteward
  - When disabled: remove owner steward from list
  - Update threshold/total display

- [x] T008 Update `lib/services/shard_distribution_service.dart` to handle owner shard:
  - Check if owner is in steward list (isOwner: true)
  - When distributing, store owner's shard locally (same as sending to self)
  - Update owner steward status to holdingKey after distribution

- [x] T009 Implement "Owner" indicator in `lib/widgets/steward_list.dart`:
  - Check steward.isOwner
  - Show distinct badge/chip (e.g., "You" or "Owner")

---

## Phase 4: UI Stubs - Delete Content (Outside-In)

- [x] T010 [P] Add "Delete Local Copy" button stub to post-distribution success screen (identify correct screen/dialog)
- [x] T011 [P] Add confirmation dialog stub for content deletion (warning text, confirm/cancel buttons)
- [x] T012 Manual verification: View delete option after distribution, see confirmation dialog

---

## Phase 5: Delete Content Implementation

- [x] T013 Implement "Delete Local Copy" flow:
  - Show button after successful distribution
  - Show strong confirmation dialog with explicit warning
  - Require user to type vault name to confirm deletion
  - On confirm: call repository to set vault.content = null
  - Preserve vault.shards
  - Navigate back to vault detail (showing owner-steward state)

- [x] T013a Ensure owner-steward vaults show "You are the owner" in UI:
  - Check if currentUserPubkey == vault.ownerPubkey
  - Even in steward state, display owner badge/indicator
  - Show owner-specific options (not just steward options)

- [x] T014 Update `lib/providers/vault_provider.dart` if needed for content deletion:
  - Add `deleteVaultContent(vaultId)` method if not exists
  - Ensure proper state invalidation after deletion

---

## Phase 6: UI Stubs - Owner Recovery (Outside-In)

- [x] T015 [P] Add "Initiate Recovery" button stub to `lib/screens/vault_detail_screen.dart` (visible when vault.state == steward && has owner shard)
- [x] T016 [P] Add "Update Content" button stub with warning text to vault detail screen
- [x] T017 Manual verification: View owner-steward vault, see both buttons with appropriate visibility

---

## Phase 7: Owner Recovery Implementation

- [x] T018 Implement owner-steward detection in `lib/screens/vault_detail_screen.dart`:
  - Check vault.state == VaultState.steward
  - Check if current user is vault owner
  - Check if vault.shards contains owner's shard
  - Show appropriate buttons based on state

- [x] T019 Implement "Initiate Recovery" for owner in `lib/screens/vault_detail_screen.dart`:
  - Reuse existing recovery initiation flow
  - Owner's shard counts toward threshold
  - Navigate to recovery status screen

- [x] T020 Implement "Update Content" with warning in `lib/screens/vault_detail_screen.dart`:
  - Show warning dialog: "This will overwrite current vault contents"
  - On confirm: navigate to edit vault screen
  - Handle save (creates new content, triggers redistribution prompt)

- [x] T021 Update `lib/widgets/vault_detail_button_stack.dart` for owner-steward state:
  - Add conditional logic for which buttons to show
  - Handle all vault states consistently

---

## Phase 8: Edge Cases

- [x] T022 Handle 1-of-1 owner-only backup (warn that this defeats purpose of distributed backup)
- [x] T023 Handle owner deleting content without having a shard (warn they'll rely entirely on stewards)
  - Note: Delete button only shows when owner IS a steward (hasOwnerSteward check), so this case is prevented by design
- [x] T024 Handle disabling self-shard after shard already exists (keep shard until next redistribution)
- [x] T025 Block "Initiate Recovery" during active recovery (show status instead)

---

## Phase 9: Testing

- [x] T026 [P] Unit test: `Steward` model with `isOwner` field in `test/models/steward_test.dart`
- [x] T027 [P] Unit test: `BackupConfig` helpers (hasOwnerSteward, getOwnerSteward) in `test/models/backup_config_test.dart`
- [x] T028 [P] Unit test: Content deletion preserves shards in `test/services/vault_service_test.dart`
- [x] T029 [P] Widget test: Self-shard toggle in backup config in `test/screens/backup_config_screen_test.dart`
- [x] T030 [P] Widget test: Owner-steward vault detail buttons in `test/screens/vault_detail_screen_test.dart`
- [ ] T031 Integration test: Full self-shard flow (enable → distribute → verify) in `test/integration/owner_shard_test.dart` (deferred - requires E2E setup)
- [ ] T032 Integration test: Full delete content flow (distribute → delete → verify state) in `test/integration/delete_content_test.dart` (deferred - requires E2E setup)
- [ ] T033 Integration test: Owner recovery flow (delete → initiate → reconstruct) in `test/integration/owner_recovery_test.dart` (deferred - requires E2E setup)

---

## Dependencies

```
T001-T002 → T003 (model before helpers)
T001-T003 → T007-T009 (model before implementation)
T004-T005 → T006 (stubs before verification)
T006 → T007-T009 (verification before implementation)
T007-T009 → T010-T014 (self-shard before delete content)
T010-T011 → T012 (stubs before verification)
T012 → T013-T014 (verification before implementation)
T013-T014 → T015-T021 (delete before owner recovery)
T015-T016 → T017 (stubs before verification)
T017 → T018-T021 (verification before implementation)
T018-T021 → T022-T025 (implementation before edge cases)
T022-T025 → T026-T033 (edge cases before testing)
```

---

## Parallel Execution Examples

```
# Launch T004-T005 together (UI stubs - self-shard):
Task: "Add self-shard toggle stub to backup_config_screen.dart"
Task: "Add Owner badge stub to steward_list.dart"

# Launch T010-T011 together (UI stubs - delete content):
Task: "Add Delete Local Copy button stub"
Task: "Add confirmation dialog stub"

# Launch T015-T016 together (UI stubs - owner recovery):
Task: "Add Initiate Recovery button stub for owner-steward"
Task: "Add Update Content button stub with warning"

# Launch T026-T030 together (unit/widget tests):
Task: "Unit test Steward model with isOwner"
Task: "Unit test BackupConfig helpers"
Task: "Unit test content deletion preserves shards"
Task: "Widget test self-shard toggle"
Task: "Widget test owner-steward vault detail"
```

---

## Validation Checklist

- [x] `isOwner` flag persists through JSON serialization
- [x] Owner appears in steward list with distinct badge
- [x] Owner's shard is stored locally after distribution
- [x] Threshold calculation includes owner when enabled
- [x] Content deletion sets content to null, preserves shards
- [x] Vault state transitions correctly after content deletion
- [x] "Initiate Recovery" visible only for owner-steward vaults
- [x] "Update Content" shows overwrite warning
- [x] Cannot initiate recovery during active recovery
