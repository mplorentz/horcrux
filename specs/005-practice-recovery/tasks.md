# Tasks: Practice Recovery

**Feature**: 005-practice-recovery  
**Branch**: `005-practice-recovery`  
**Prerequisites**: plan.md, data-model.md

---

## Task Format

`[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)

---

## Phase 1: Model Changes

- [X] T001 Add `isPractice` boolean field to `RecoveryRequest` in `lib/models/recovery_request.dart` (default false, update constructor, copyWith, toJson, fromJson)

---

## Phase 2: Service Changes

- [X] T002 Update `RecoveryService.initiateRecovery` in `lib/services/recovery_service.dart` to accept optional `isPractice` parameter and pass to RecoveryRequest
- [X] T003 Update `RecoveryService.sendRecoveryRequestViaNostr` to include `is_practice` in event payload
- [X] T004 Update `RecoveryService.respondToRecoveryRequestWithShard` to skip shard data retrieval when responding to practice requests
- [X] T005 Update `RecoveryService.sendRecoveryResponseViaNostr` to omit `shard_data` for practice responses

---

## Phase 3: UI Stubs (Outside-In)

- [X] T006 [P] Add "Practice Recovery" button stub to `lib/screens/vault_detail_screen.dart` (non-functional, visible only when shards distributed and no active recovery) - Note: Implemented via vault_detail_button_stack.dart with full functionality
- [X] T007 [P] Add practice mode banner stub to `lib/screens/recovery_status_screen.dart` (shows "Practice Recovery" header when `request.isPractice`)
- [X] T008 [P] Add practice request styling stub to `lib/screens/recovery_request_detail_screen.dart` (shows "PRACTICE REQUEST" header and explanatory text)
- [X] T009 [P] Add practice badge stub to `lib/widgets/recovery_notification_overlay.dart` (visual indicator for practice requests)
- [x] T010 Manual verification: Navigate through stubbed practice UI and verify layout/styling

---

## Phase 4: UI Implementation

- [X] T011 Implement "Practice Recovery" button in `lib/screens/vault_detail_screen.dart`:
  - Check `backupConfig.stewards` has at least one with `holdingKey` status
  - Check no active non-practice recovery in progress
  - Show confirmation dialog
  - Call `RecoveryService.initiateRecovery` with `isPractice: true`
  - Navigate to recovery status screen
  - Note: Implemented via PracticeRecoveryScreen with "Start Practice Recovery" button that calls initiateRecovery with isPractice: true

- [ ] T012 Implement practice mode in `lib/screens/recovery_status_screen.dart`:
  - Different header/banner styling for practice
  - "End Practice" button instead of "End Recovery"
  - Summary text: "X of Y stewards responded"

- [ ] T013 Implement practice request display in `lib/screens/recovery_request_detail_screen.dart`:
  - "PRACTICE REQUEST" header
  - Explanatory text: "This is a practice request. No vault data will be shared."
  - Same approve/deny flow (response won't include shard)

- [ ] T014 Implement practice badge in `lib/widgets/recovery_notification_overlay.dart`:
  - Check `recoveryRequest.isPractice`
  - Add "Practice" badge/chip with distinct color
  - Different background styling

---

## Phase 5: Edge Cases

- [ ] T015 Block practice initiation when real recovery is in progress in `lib/screens/vault_detail_screen.dart` (show message if user tries)
- [ ] T016 Handle case where steward hasn't received shard yet but receives practice request (allow response, maybe show warning)
- [ ] T017 Allow owner to cancel practice mid-way (reuse existing cancel recovery logic)

---

## Phase 6: Testing

- [ ] T018 [P] Unit test: `RecoveryRequest` model with `isPractice` flag in `test/models/recovery_request_test.dart`
- [ ] T019 [P] Unit test: `RecoveryService` practice mode logic in `test/services/recovery_service_test.dart` (verify no shard data in practice responses)
- [ ] T020 [P] Widget test: Practice Recovery button visibility conditions in `test/screens/vault_detail_screen_test.dart`
- [ ] T021 [P] Widget test: Practice mode styling in recovery status screen in `test/screens/recovery_status_screen_test.dart`
- [ ] T022 Integration test: Full practice recovery flow in `test/integration/practice_recovery_test.dart`

---

## Dependencies

```
T001 → T002, T003, T004, T005 (model before services)
T002-T005 → T011-T014 (services before UI implementation)
T006-T009 → T010 (stubs before manual verification)
T010 → T011-T014 (verification before implementation)
T011-T014 → T015-T017 (implementation before edge cases)
T015-T017 → T018-T022 (edge cases before testing)
```

---

## Parallel Execution Examples

```
# Launch T006-T009 together (UI stubs):
Task: "Add Practice Recovery button stub to vault_detail_screen.dart"
Task: "Add practice mode banner stub to recovery_status_screen.dart"
Task: "Add practice request styling stub to recovery_request_detail_screen.dart"
Task: "Add practice badge stub to recovery_notification_overlay.dart"

# Launch T018-T021 together (unit/widget tests):
Task: "Unit test RecoveryRequest model with isPractice flag"
Task: "Unit test RecoveryService practice mode logic"
Task: "Widget test Practice Recovery button visibility"
Task: "Widget test Practice mode styling in recovery status screen"
```

---

## Validation Checklist

- [X] `isPractice` flag persists through JSON serialization
- [ ] Practice requests clearly labeled in all UI screens
- [X] Practice responses do NOT include shard data
- [ ] Cannot start practice during active real recovery
- [ ] Practice Recovery button only visible when shards distributed
- [ ] End Practice archives the request properly
