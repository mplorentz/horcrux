# Implementation Plan: Practice Recovery

**Branch**: `005-practice-recovery` | **Date**: 2025-01-09 | **Spec**: [spec.md](./spec.md)  
**Parent Plan**: Owner-Initiated Vault Recovery (Phases 1-3)

---

## Summary

Add practice recovery functionality allowing vault owners to test steward responsiveness without exposing vault data. Implementation involves adding an `isPractice` flag to recovery requests, updating UI to show practice mode clearly, and ensuring practice responses don't include shard data.

---

## Technical Context

**Language/Version**: Dart 3.5.3, Flutter 3.35.0  
**Primary Dependencies**: flutter_riverpod, ndk (Nostr), shared_preferences  
**Affected Files**: 
- `lib/models/recovery_request.dart`
- `lib/services/recovery_service.dart`
- `lib/screens/vault_detail_screen.dart`
- `lib/screens/recovery_status_screen.dart`
- `lib/screens/recovery_request_detail_screen.dart`
- `lib/widgets/recovery_notification_overlay.dart`

**Reused Infrastructure**:
- Existing `RecoveryRequest` and `RecoveryResponse` models
- Existing recovery request/response Nostr event flow
- Existing notification overlay
- Existing recovery status screen

---

## Implementation Approach

### Phase 1: Model Changes

Add `isPractice` flag to `RecoveryRequest`:

```dart
// In lib/models/recovery_request.dart
class RecoveryRequest {
  // ... existing fields ...
  final bool isPractice;  // NEW: True for practice recovery sessions
  
  // Update constructor, copyWith, toJson, fromJson
}
```

### Phase 2: Service Changes

Update `RecoveryService` to handle practice mode:

1. **`initiateRecovery`**: Accept optional `isPractice` parameter
2. **`sendRecoveryRequestViaNostr`**: Include `isPractice` in event payload
3. **`respondToRecoveryRequest`**: Skip shard data when responding to practice requests
4. **`sendRecoveryResponseViaNostr`**: Don't include shard data for practice

### Phase 3: UI Changes

**Vault Detail Screen** (`lib/screens/vault_detail_screen.dart`):
- Add "Practice Recovery" button (visible when: shards distributed, no active recovery)
- Button initiates practice recovery request

**Recovery Status Screen** (`lib/screens/recovery_status_screen.dart`):
- Show "Practice Recovery" banner when `request.isPractice`
- Different styling (e.g., orange/yellow theme vs red for real recovery)
- "End Practice" button instead of "End Recovery"

**Recovery Request Detail Screen** (`lib/screens/recovery_request_detail_screen.dart`):
- Show "PRACTICE REQUEST" header when practice
- Explanatory text: "This is a practice request. No vault data will be shared."
- Same approve/deny buttons

**Notification Overlay** (`lib/widgets/recovery_notification_overlay.dart`):
- Add "Practice" badge to practice requests
- Different color/styling for practice notifications

---

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/models/recovery_request.dart` | Modify | Add `isPractice` field |
| `lib/services/recovery_service.dart` | Modify | Handle practice mode in initiate/respond methods |
| `lib/screens/vault_detail_screen.dart` | Modify | Add Practice Recovery button |
| `lib/screens/recovery_status_screen.dart` | Modify | Practice mode UI styling |
| `lib/screens/recovery_request_detail_screen.dart` | Modify | Practice request display |
| `lib/widgets/recovery_notification_overlay.dart` | Modify | Practice badge on notifications |
| `lib/widgets/vault_detail_button_stack.dart` | Modify | Include practice button logic |

---

## Testing Strategy

### Manual Testing (Outside-In)

1. As owner: Distribute shards to stewards
2. As owner: Tap "Practice Recovery" → confirm dialog
3. As steward: See practice request in notification overlay with badge
4. As steward: Tap request → see practice labeling → approve
5. As owner: See steward response in practice status screen
6. As owner: Tap "End Practice" → return to vault detail

### Unit Tests

- `RecoveryRequest` model: Verify `isPractice` serialization
- `RecoveryService`: Verify practice requests don't include shard data in responses

### Integration Tests

- Full practice flow: initiate → steward response → view results → end practice

---

## Risk Assessment

**Low Risk**: 
- Minimal changes to existing code
- Reuses existing infrastructure
- No security implications (practice mode explicitly avoids real data)

**Considerations**:
- Ensure `isPractice` flag cannot be spoofed to bypass security
- Clear UI differentiation to prevent user confusion

---

## Dependencies

- Existing recovery infrastructure must be working
- Steward notification overlay must be functional
- At least one steward must have received shards

---

## Estimated Effort

- Model changes: 0.5 hours
- Service changes: 1 hour
- UI changes: 2-3 hours
- Testing: 1-2 hours
- **Total**: 5-7 hours
