# Implementation Plan: Practice Recovery

## Tech Stack

- **Flutter 3.35.0** with Dart SDK ^3.5.3
- **Riverpod** for state management
- **Material Design 3** components for UI
- Existing theme system (horcrux3 theme)

## Architecture

### UI Components

**New Screen:**
- `PracticeRecoveryScreen` - Main screen for practice recovery flow
  - Shows vault information
  - Displays recovery plan details
  - Explains the recovery process
  - Shows what stewards would see

**Modified Components:**
- `VaultDetailButtonStack` - Update "Practice Recovery" button handler

### State Management

No new state management needed. Will use existing providers:
- `vaultProvider(vaultId)` - To get vault and backup config
- `currentPublicKeyProvider` - To verify user is vault owner

### Validation

Before showing practice recovery:
1. Verify user is vault owner
2. Verify backup config exists and is ready (`backupConfig.isReady`)
3. Verify sufficient stewards have acknowledged keys
4. Show appropriate error messages if not ready

## UI Flow

1. **Entry Point**: User taps "Practice Recovery" button on vault detail screen
2. **Validation**: Check if recovery plan is ready
   - If not ready, show error dialog with guidance
   - If ready, navigate to PracticeRecoveryScreen
3. **Practice Screen**: Show educational dialog with:
   - Vault name and information
   - Recovery plan details (stewards, threshold)
   - Explanation of recovery process
   - What stewards would see in a real recovery
   - Clarification that this is practice only
4. **Completion**: User dismisses dialog, returns to vault detail

## Design System

Follow existing design patterns from `DESIGN_GUIDE.md`:
- Use Navy-Ink (#1D2530) for primary text
- Use Umber (#7A4A2F) for secondary elements
- Use Material Design 3 Dialog component
- Follow existing typography (Archivo for headings, Roboto Mono for content)

## File Changes

### New Files
- `lib/screens/practice_recovery_screen.dart` - Main practice recovery screen

### Modified Files
- `lib/widgets/vault_detail_button_stack.dart` - Update button handler

## Testing Strategy

### Unit Tests
- No unit tests needed (simple UI flow)

### Golden Tests
- `test/screens/practice_recovery_screen_test.dart` - Golden tests for practice recovery screen
  - Test with vault that has ready recovery plan
  - Test different states (2 of 3, 3 of 5, etc.)

### Manual Testing
1. Create a vault with recovery plan
2. Distribute keys to stewards
3. Wait for steward acknowledgments
4. Tap "Practice Recovery" button
5. Verify dialog shows correct information
6. Verify no actual recovery requests are created
7. Test with vault that's not ready (should show error)

## Rollout Plan

1. Implement PracticeRecoveryScreen
2. Update VaultDetailButtonStack button handler
3. Add golden tests
4. Manual testing
5. Code review
6. Merge to main
