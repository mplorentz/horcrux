# Feature Specification: Post-Recovery Key Management & Key Rotation

**Feature Branch**: `008-key-rotation`  
**Created**: 2025-01-09  
**Status**: Draft  
**Parent Plan**: Owner-Initiated Vault Recovery (Phases 11-12)

---

## Summary

After a vault owner recovers their vault (especially via lost device flow), they need to transition back to a normal state. This includes detecting if their old Nostr key was in the vault, offering to switch to it, and notifying stewards of a key change so they can update their records. Stewards validate key rotation requests using the `recoveryPubkey` they stored when approving the recovery.

---

## User Scenarios & Testing

### Primary User Stories

**Story 1 - Key Detection**: As a vault owner who just recovered my vault, I want the app to detect if my old Nostr key is in the recovered content, so that I can easily switch back to my original identity.

**Story 2 - Key Switch**: As a vault owner who recovered my Nostr key, I want to switch to it easily, so that I can resume using my original identity without manual import.

**Story 3 - Key Rotation**: As a vault owner with a new key, I want to notify my stewards of the key change, so that they can update their records and I can set up a new vault with proper ownership.

### Acceptance Scenarios

#### Post-Recovery Key Detection

1. **Given** recovery is complete, **When** the owner views the recovered content, **Then** the app scans for Nostr key patterns (nsec1...)

2. **Given** an nsec is found in recovered content, **When** the owner views the recovery complete screen, **Then** they see a prompt "Did you recover your Nostr key?"

3. **Given** the owner confirms they recovered their key, **When** they tap "Switch to recovered key", **Then** the app re-authenticates with the recovered key

4. **Given** the owner switches to recovered key, **When** login completes, **Then** they are now using their original identity and the temp key is discarded

5. **Given** no nsec is found in recovered content, **When** the owner views the recovery complete screen, **Then** they see options to "Continue with new key" or "Set up new vault"

#### Key Rotation to Stewards

6. **Given** an owner has recovered via lost device flow, **When** they view vault settings, **Then** they see "Notify Stewards of Key Change" option

7. **Given** an owner taps "Notify Stewards of Key Change", **When** they confirm, **Then** a key rotation event is sent to all stewards

8. **Given** a steward receives a key rotation event, **When** they process it, **Then** they validate the sender matches the `recoveryPubkey` they stored

9. **Given** validation passes, **When** the steward accepts the rotation, **Then** they update the vault's `ownerPubkey` to the new key

10. **Given** validation fails (sender doesn't match recoveryPubkey), **When** the steward receives the event, **Then** they reject it and log a warning

11. **Given** an owner sends key rotation, **When** some stewards didn't participate in recovery, **Then** those stewards won't have `recoveryPubkey` and can't validate (owner is informed)

12. **Given** key rotation is complete, **When** the owner views their vault, **Then** they can set up new backup distribution with their new key as owner

### Edge Cases

- **What if owner doesn't want to switch to recovered key?** They can continue with temp key or create new account
- **What if multiple nsec patterns are found?** Show list and let owner choose which to use
- **What if recovered nsec is invalid?** Show error, allow manual retry or continue with current key
- **What if steward didn't approve recovery?** They won't have `recoveryPubkey`, show owner which stewards can't receive rotation
- **What if steward already deleted the vault?** Rotation event arrives but vault doesn't exist; ignore gracefully
- **What if owner wants to rotate without recovery?** This feature is specifically for post-recovery; manual key rotation could be separate feature

---

## Requirements

### Functional Requirements - Key Detection

- **FR-001**: System MUST scan recovered vault content for Nostr key patterns (nsec1...)
- **FR-002**: System MUST display prompt when nsec is found: "Did you recover your Nostr key?"
- **FR-003**: System MUST allow owner to switch to recovered key with one tap
- **FR-004**: System MUST re-authenticate user with recovered key
- **FR-005**: System MUST clean up temporary key after successful switch
- **FR-006**: System MUST handle case where no key is found (offer alternatives)
- **FR-007**: System MUST handle case where multiple keys are found (offer selection)
- **FR-008**: System MUST validate recovered key format before attempting switch

### Functional Requirements - Key Rotation

- **FR-009**: System MUST add "Notify Stewards of Key Change" action in vault settings (post-recovery)
- **FR-010**: System MUST create new Nostr event kind for key rotation (suggest kind 1360)
- **FR-011**: System MUST send key rotation event to all stewards who have `recoveryPubkey` set
- **FR-012**: System MUST include old pubkey, new pubkey, and vault ID in rotation event
- **FR-013**: Stewards MUST validate rotation sender matches stored `recoveryPubkey`
- **FR-014**: Stewards MUST update vault's `ownerPubkey` on successful validation
- **FR-015**: Stewards MUST reject and log warning for invalid rotation attempts
- **FR-016**: System MUST inform owner which stewards cannot receive rotation (no recoveryPubkey)
- **FR-017**: System MUST allow owner to proceed with rotation even if some stewards excluded

---

## User Interface Flow

### Recovery Complete Screen (Key Detected)

```
┌─────────────────────────────────────┐
│ ✓ Recovery Complete                 │
├─────────────────────────────────────┤
│                                     │
│ Your vault has been recovered!      │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔑 Nostr Key Detected           │ │
│ │                                 │ │
│ │ It looks like your recovered    │ │
│ │ content contains a Nostr key.   │ │
│ │                                 │ │
│ │ Would you like to switch to     │ │
│ │ your recovered key?             │ │
│ │                                 │ │
│ │   [Switch to Recovered Key]     │ │
│ │                                 │ │
│ │   [Continue with Current Key]   │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [View Vault Contents]       │
│                                     │
└─────────────────────────────────────┘
```

### Recovery Complete Screen (No Key Found)

```
┌─────────────────────────────────────┐
│ ✓ Recovery Complete                 │
├─────────────────────────────────────┤
│                                     │
│ Your vault has been recovered!      │
│                                     │
│ You are currently using a           │
│ temporary key. You can:             │
│                                     │
│ • Continue with this key            │
│ • Import your old key manually      │
│ • Set up a new vault with this key  │
│                                     │
│   [Continue with Current Key]       │
│                                     │
│   [Import Key from Settings]        │
│                                     │
│         [View Vault Contents]       │
│                                     │
└─────────────────────────────────────┘
```

### Key Rotation Screen

```
┌─────────────────────────────────────┐
│ ← Notify Stewards of Key Change     │
├─────────────────────────────────────┤
│                                     │
│ After recovering your vault with    │
│ a new key, you can notify stewards  │
│ to update their records.            │
│                                     │
│ Stewards who can be notified:       │
│ ✓ Alice                             │
│ ✓ Bob                               │
│                                     │
│ Stewards who cannot be notified:    │
│ ✗ Carol (didn't participate in      │
│         recovery)                   │
│                                     │
│ ⚠️ Stewards who cannot be notified  │
│ will still have your old key as     │
│ the vault owner.                    │
│                                     │
│      [Send Key Rotation]            │
│                                     │
│      [Skip for Now]                 │
│                                     │
└─────────────────────────────────────┘
```

### Steward Receives Rotation

```
┌─────────────────────────────────────┐
│ Key Rotation Request                │
├─────────────────────────────────────┤
│                                     │
│ The owner of "My Passwords" has     │
│ changed their Nostr key after       │
│ recovery.                           │
│                                     │
│ Old key: npub1abc...                │
│ New key: npub1xyz...                │
│                                     │
│ ✓ Verified: Sender matches the key  │
│   you approved for recovery.        │
│                                     │
│      [Accept Key Change]            │
│                                     │
│      [Ignore]                       │
│                                     │
└─────────────────────────────────────┘
```

---

## Key Entities

### Key Rotation Event (New Nostr Kind)

**Kind**: 1360 (suggested)

**Payload**:
```json
{
  "type": "key_rotation",
  "vault_id": "...",
  "old_pubkey": "...",     // Previous owner pubkey
  "new_pubkey": "...",     // New owner pubkey (sender of event)
  "recovery_request_id": "...",  // Optional: link to recovery
  "rotated_at": "..."
}
```

### Vault (Modified - from 007)

Already has `recoveryPubkey` field from feature 007.

---

## Security Considerations

### Validation Flow

```
Steward receives key rotation event
         │
         ▼
Check: Does vault have recoveryPubkey?
         │
    ┌────┴────┐
    │         │
   Yes        No
    │         │
    ▼         ▼
Check: Does    Reject event
event sender   (log warning)
match 
recoveryPubkey?
    │
┌───┴───┐
│       │
Yes     No
│       │
▼       ▼
Accept  Reject event
rotation (log security warning)
```

### Why This Is Secure

1. **recoveryPubkey is set during recovery**: Only when a steward approves a recovery request with `ownerRecoveryPubkey`, they store that pubkey
2. **Only recovery pubkey holder can rotate**: The rotation event must come from the key that was used for recovery
3. **Stewards independently validate**: Each steward checks their own stored `recoveryPubkey`
4. **No trust required for rotation**: Steward doesn't need to trust the rotation request; they verify cryptographically

---

## Dependencies

- Requires `recoveryPubkey` field on Vault (from 007-lost-device-recovery)
- Requires completed recovery with `ownerRecoveryPubkey` set
- Should be built after Lost Device Recovery (007)

---

## Out of Scope

- Manual key rotation (without recovery flow)
- Multi-key support
- Key backup to stewards (owner's key in vault is user's choice)
- Automatic key switching (always prompts user)
