# Feature Specification: Owner Self-Shard & Content Deletion

**Feature Branch**: `006-owner-shard`  
**Created**: 2025-01-09  
**Status**: Draft  
**Parent Plan**: Owner-Initiated Vault Recovery (Phases 4-6)

---

## Summary

Allow vault owners to hold their own shard (opt-in during backup configuration) and optionally delete local vault content after distribution. When an owner has a shard but no content, they can initiate recovery like any steward. These are independent features that can be used separately or together.

---

## User Scenarios & Testing

### Primary User Stories

**Story 1 - Owner Self-Shard**: As a vault owner, I want to hold my own shard alongside my stewards, so that I can participate in recovery and have additional redundancy.

**Story 2 - Delete Local Content**: As a vault owner, I want to delete my local vault contents after distribution, so that my device doesn't hold the sensitive data and I must go through recovery to access it.

**Story 3 - Owner Initiates Recovery**: As a vault owner who has a shard but deleted my content, I want to initiate recovery, so that I can access my vault contents when needed.

### Acceptance Scenarios

#### Owner Self-Shard

1. **Given** a vault owner is configuring backup, **When** they view the steward configuration screen, **Then** they see a toggle "Include yourself as a shard holder"

2. **Given** an owner enables "Include yourself as a shard holder", **When** they view the steward list, **Then** they see themselves listed as a steward with "Owner" indicator

3. **Given** an owner has enabled self-shard, **When** shard distribution completes, **Then** the owner receives and stores their own shard locally

4. **Given** an owner has enabled self-shard, **When** threshold is calculated, **Then** the owner counts as one of the N shares

#### Delete Local Content

5. **Given** shard distribution has completed, **When** the owner views the success screen, **Then** they see an option "Delete local copy of vault contents"

6. **Given** an owner chooses to delete local content, **When** they confirm, **Then** the vault content is set to null but shards are retained

7. **Given** an owner has deleted local content, **When** they view the vault in the list, **Then** the vault shows in "steward" state (has shard, no content)

8. **Given** an owner views a vault where they deleted content, **When** they want to see the contents, **Then** they must initiate a full recovery

#### Owner Initiates Recovery

9. **Given** an owner has a shard but no content (deleted or never had it), **When** they view the vault detail screen, **Then** they see "Initiate Recovery" button

10. **Given** an owner initiates recovery, **When** the request is sent, **Then** it goes to all stewards (including the owner's shard counting toward threshold)

11. **Given** an owner has initiated recovery, **When** enough shards are collected, **Then** the vault content is reconstructed and displayed

12. **Given** an owner has content but wants to update it (after previous deletion), **When** they tap "Update Content", **Then** they see a warning "This will overwrite the current vault contents"

### Edge Cases

- **What if owner is the only steward?** Allow it (1-of-1 recovery), but warn that this defeats the purpose of distributed backup
- **What if owner disables self-shard after already having a shard?** Keep the existing shard until next redistribution
- **What if owner deletes content but has no shard?** They must rely entirely on stewards for recovery (warn about this)
- **What if owner tries to update content without having current content?** Allow it with warning about overwrite
- **What if owner has shard and is also in active recovery?** Show recovery status, not "Initiate Recovery" button
- **Owner vs steward state confusion** - Even when vault is in "steward" state (no content), if logged-in user matches vault.ownerPubkey, UI should clearly indicate "You are the owner" and show owner-specific options

---

## Requirements

### Functional Requirements - Owner Self-Shard

- **FR-001**: System MUST add `isOwner` boolean field to `Steward` model
- **FR-002**: System MUST show "Include yourself as a shard holder" toggle in backup config screen
- **FR-003**: System MUST add owner to steward list when toggle enabled, with `isOwner: true`
- **FR-004**: System MUST include owner in threshold/total calculations
- **FR-005**: System MUST distribute a shard to the owner during shard distribution
- **FR-006**: System MUST display owner in steward list with distinct "Owner" indicator

### Functional Requirements - Delete Local Content

- **FR-007**: System MUST offer "Delete local copy" option after successful shard distribution
- **FR-008**: System MUST show strong confirmation dialog with explicit warning: "This will permanently delete your local copy. You will need to complete a full recovery with your stewards to view contents again. This cannot be undone."
- **FR-008a**: System MUST require user to type confirmation text (e.g., vault name) before allowing deletion
- **FR-009**: System MUST delete vault content (set to null) while preserving shards
- **FR-010**: System MUST transition vault state from `owned` to `steward` after content deletion
- **FR-011**: System MUST allow deletion regardless of whether owner holds a shard

### Functional Requirements - Owner Initiates Recovery

- **FR-012**: System MUST show "Initiate Recovery" button when vault state is `steward` and shard has `isOwner: true`
- **FR-013**: System MUST allow owner to initiate recovery using existing recovery flow
- **FR-014**: System MUST count owner's shard toward recovery threshold
- **FR-015**: System MUST show "Update Content" option for owner-steward vaults with warning about overwrite
- **FR-016**: System MUST NOT show "Initiate Recovery" during active recovery (show status instead)

---

## User Interface Flow

### Backup Config - Self-Shard Toggle

```
┌─────────────────────────────────────┐
│ Backup Configuration                │
├─────────────────────────────────────┤
│                                     │
│ Stewards                            │
│ ┌─────────────────────────────────┐ │
│ │ [Toggle] Include yourself as a  │ │
│ │          shard holder           │ │
│ │                                 │ │
│ │ You'll receive a shard like     │ │
│ │ your stewards, allowing you to  │ │
│ │ participate in recovery.        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ • Alice (Steward)          ✓ Ready  │
│ • Bob (Steward)            ✓ Ready  │
│ • You (Owner)              ✓ Ready  │ ← Shows when enabled
│                                     │
│ Threshold: 2 of 3                   │
└─────────────────────────────────────┘
```

### Post-Distribution - Delete Content Option

```
┌─────────────────────────────────────┐
│ ✓ Distribution Complete             │
├─────────────────────────────────────┤
│                                     │
│ Your vault is now secured with      │
│ your stewards.                      │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ [Button] Delete Local Copy      │ │
│ │                                 │ │
│ │ Remove vault contents from this │ │
│ │ device. You'll need to complete │ │
│ │ a full recovery to view them    │ │
│ │ again.                          │ │
│ └─────────────────────────────────┘ │
│                                     │
│           [Done]                    │
└─────────────────────────────────────┘
```

### Vault Detail - Owner as Steward

```
┌─────────────────────────────────────┐
│ My Passwords                        │
│ You are a steward for this vault    │
├─────────────────────────────────────┤
│                                     │
│ Owner: You                          │
│ Status: Content deleted             │
│                                     │
│ You have a shard for this vault.    │
│ Initiate recovery to view contents. │
│                                     │
│    [Initiate Recovery]              │
│                                     │
│    [Update Content]                 │
│    ⚠️ This will overwrite current   │
│       vault contents                │
│                                     │
└─────────────────────────────────────┘
```

---

## Key Entities

### Steward (Modified)

```dart
bool isOwner;  // True when this steward is the vault owner
```

### Vault State Transitions

```
[Owned] ──(delete content)──▶ [Steward with isOwner shard]
                                      │
                                      ▼
                              [Initiate Recovery]
                                      │
                                      ▼
                               [Recovery Mode]
                                      │
                                      ▼
                                  [Owned]
```

---

## Dependencies

- Requires shard distribution to be functional
- Requires existing recovery infrastructure
- Should be built after Practice Recovery (005) for testing

---

## Out of Scope

- Automatic deletion after distribution (always user-initiated)
- Scheduled/timed content deletion
- Partial content deletion
- Owner holding multiple shards
