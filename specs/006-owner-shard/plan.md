# Implementation Plan: Owner Self-Shard & Content Deletion

**Branch**: `006-owner-shard` | **Date**: 2025-01-09 | **Spec**: [spec.md](./spec.md)  
**Parent Plan**: Owner-Initiated Vault Recovery (Phases 4-6)

---

## Summary

Enable vault owners to opt-in to holding their own shard during backup configuration, optionally delete local vault content after distribution, and initiate recovery when they have a shard but no content.

---

## Technical Context

**Language/Version**: Dart 3.5.3, Flutter 3.35.0  
**Primary Dependencies**: flutter_riverpod, ndk (Nostr), shared_preferences

**Affected Files**:
- `lib/models/steward.dart` - Add `isOwner` field
- `lib/models/backup_config.dart` - Handle owner in steward list
- `lib/screens/backup_config_screen.dart` - Self-shard toggle UI
- `lib/services/shard_distribution_service.dart` - Include owner in distribution, post-distribution delete option
- `lib/screens/vault_detail_screen.dart` - Owner-steward UI (initiate recovery, update content)
- `lib/widgets/vault_detail_button_stack.dart` - Conditional buttons
- `lib/widgets/steward_list.dart` - Owner indicator in list

---

## Implementation Approach

### Part A: Owner Self-Shard (Phases 4-5 tasks)

#### Model Changes

Add `isOwner` to Steward:

```dart
// In lib/models/steward.dart
class Steward {
  // ... existing fields ...
  final bool isOwner;  // NEW: True when this steward is the vault owner
}
```

Update steward factory functions:

```dart
Steward createSteward({required String? pubkey, String? name, bool isOwner = false}) {
  // ... include isOwner
}

Steward createOwnerSteward({required String pubkey, String? name}) {
  return createSteward(pubkey: pubkey, name: name ?? 'You', isOwner: true);
}
```

#### UI Changes - Backup Config

Add toggle to backup_config_screen.dart:

```dart
SwitchListTile(
  title: Text('Include yourself as a shard holder'),
  subtitle: Text('You\'ll receive a shard, allowing you to participate in recovery.'),
  value: _includeOwnerShard,
  onChanged: (value) {
    setState(() => _includeOwnerShard = value);
    _updateOwnerInStewardList(value);
  },
)
```

#### Service Changes - Distribution

Update shard_distribution_service.dart:
- When distributing, check if owner is in steward list with `isOwner: true`
- If so, store owner's shard locally (same as other stewards receive theirs)

### Part B: Delete Local Content (Phase 5 tasks)

#### Post-Distribution UI

After successful distribution, show option:

```dart
ElevatedButton(
  onPressed: () => _showDeleteContentDialog(),
  child: Text('Delete Local Copy'),
)

void _showDeleteContentDialog() {
  showDialog(
    // ... confirmation with warning text
    // On confirm: call repository.saveVault(vault.copyWith(content: null))
  );
}
```

#### State Transition

When content is deleted:
- `vault.content = null`
- `vault.shards` remain intact
- `vault.state` returns `VaultState.steward` (because shards exist, content is null)

### Part C: Owner Initiates Recovery (Phase 6 tasks)

#### Vault Detail Screen Logic

```dart
// Determine what buttons to show
if (vault.state == VaultState.steward) {
  final ownerShard = vault.shards.firstWhereOrNull((s) => s.isOwner == true);
  if (ownerShard != null) {
    // Owner has shard but no content
    // Show: "Initiate Recovery" and "Update Content" buttons
  }
}
```

#### Update Content Warning

When owner taps "Update Content":

```dart
showDialog(
  // Warning: "This will overwrite the current vault contents. 
  // Any changes made by stewards will be lost."
  // On confirm: navigate to edit screen
);
```

---

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/models/steward.dart` | Modify | Add `isOwner` field, update factory functions |
| `lib/models/backup_config.dart` | Modify | Handle owner steward in helpers |
| `lib/screens/backup_config_screen.dart` | Modify | Add self-shard toggle |
| `lib/services/shard_distribution_service.dart` | Modify | Include owner in distribution, add delete content flow |
| `lib/screens/vault_detail_screen.dart` | Modify | Owner-steward buttons (initiate recovery, update content) |
| `lib/widgets/vault_detail_button_stack.dart` | Modify | Conditional button logic |
| `lib/widgets/steward_list.dart` | Modify | Show "Owner" indicator |
| `lib/providers/vault_provider.dart` | Modify | Handle content deletion state transition |

---

## Testing Strategy

### Manual Testing

**Self-Shard Flow:**
1. Create vault, go to backup config
2. Enable "Include yourself as a shard holder"
3. Verify owner appears in steward list with "Owner" badge
4. Complete distribution
5. Verify owner has shard stored locally

**Delete Content Flow:**
1. After distribution, tap "Delete Local Copy"
2. Confirm deletion
3. Verify vault shows in "steward" state
4. Verify vault content is null but shard exists

**Owner Recovery Flow:**
1. As owner with shard but no content, view vault detail
2. Verify "Initiate Recovery" button visible
3. Initiate recovery
4. Verify recovery flow works (requests sent to stewards)
5. Complete recovery, verify content restored

### Unit Tests

- `Steward` model: `isOwner` serialization
- `BackupConfig`: Owner in steward list calculations
- Content deletion: State transition to steward

### Integration Tests

- Full self-shard flow: enable → distribute → verify shard
- Full delete flow: distribute → delete → verify state
- Owner recovery: delete content → initiate recovery → reconstruct

---

## Risk Assessment

**Low Risk**:
- Model changes are additive
- UI changes are self-contained
- Reuses existing recovery infrastructure

**Medium Risk**:
- Threshold calculations must correctly include owner
- Content deletion must not delete shards
- Need clear state transitions

**Mitigations**:
- Unit tests for threshold calculations
- Separate storage for content vs shards (already exists)
- Manual verification of state transitions

---

## Estimated Effort

- Model changes: 1 hour
- Self-shard UI + service: 2-3 hours
- Delete content flow: 1-2 hours
- Owner recovery UI: 2 hours
- Testing: 2-3 hours
- **Total**: 8-11 hours
