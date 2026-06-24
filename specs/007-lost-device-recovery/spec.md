# Feature Specification: Lost Device Recovery

**Feature Branch**: `007-lost-device-recovery`  
**Created**: 2025-01-09  
**Status**: Draft  
**Parent Plan**: Owner-Initiated Vault Recovery (Phases 8-11)

---

## Summary

Enable vault owners who have lost their device to recover their vault from a fresh installation. The owner generates a temporary Nostr key, creates a recovery initiation link containing their vault name and identity, and sends it to a steward out-of-band. The steward initiates recovery on the owner's behalf, with shards being sent directly to the owner's temporary key.

---

## User Scenarios & Testing

### Primary User Story

As a vault owner who has lost my device, I want to recover my vault from a fresh Horcrux installation, so that I can regain access to my sensitive data even without my original Nostr key.

### Acceptance Scenarios

#### Onboarding Flow

1. **Given** a user opens Horcrux for the first time, **When** they complete the welcome screen, **Then** they see a "What brings you to Horcrux?" screen with three options

2. **Given** a user is on the "What brings you here?" screen, **When** they tap "I need to recover my vault", **Then** they are guided through the recovery initiation flow

3. **Given** a user is on the "What brings you here?" screen, **When** they tap "I want to start backing up data", **Then** they proceed to the existing account choice screen

4. **Given** a user is on the "What brings you here?" screen, **When** they tap "I received an invitation from a friend", **Then** they are prompted to enter/paste the invitation link

#### Recovery Initiation Link Generation

5. **Given** a user chooses "I need to recover my vault", **When** they begin the recovery flow, **Then** a temporary Nostr key is generated for them automatically

6. **Given** a user is creating a recovery request, **When** they enter their vault name and their name, **Then** a shareable recovery initiation link is generated

7. **Given** a recovery initiation link is generated, **When** the user views it, **Then** it contains their temporary pubkey, vault name, and their name embedded in the URL

8. **Given** a user has a recovery initiation link, **When** they share it with a steward out-of-band, **Then** the steward can tap the link to open Horcrux

#### Steward Processes Link

9. **Given** a steward taps a recovery initiation link, **When** Horcrux opens, **Then** they see the owner's claimed name and vault name

10. **Given** a steward views the recovery initiation screen, **When** they see the claimed identity, **Then** they also see a list of vaults they are steward for

11. **Given** a steward selects a vault to recover, **When** they confirm, **Then** a recovery request is initiated with `ownerRecoveryPubkey` set to the owner's temp key

12. **Given** a steward initiates recovery on behalf of owner, **When** other stewards respond, **Then** their shards are sent to the owner's temp key (not the initiating steward)

#### Owner Receives Shards

13. **Given** an owner is waiting for recovery, **When** the first shard arrives, **Then** the app automatically creates a local vault stub using metadata from the shard (vault ID, name)

14. **Given** an owner is waiting for recovery, **When** stewards approve and send shards, **Then** the owner's app receives the shards via their temp key and adds them to the vault stub

15. **Given** enough shards are collected, **When** threshold is met, **Then** the vault content is reconstructed on the owner's fresh device

16. **Given** recovery is complete, **When** the owner views the vault, **Then** they can see their recovered content

### Edge Cases

- **What if owner sends link to multiple stewards?** Each steward who taps the link can independently initiate recovery, resulting in multiple recovery sessions. UI should warn about this.
- **What if steward doesn't recognize the owner's claimed name?** Steward should be able to deny/ignore the request. They see the claimed info and must manually match to a vault.
- **What if owner's claimed vault name doesn't match any vault?** Steward selects from their list; the claimed name is just a hint to help identify.
- **What if steward has no vaults for this owner?** Show message "You don't appear to be a steward for any vaults that match this request."
- **What if owner's temp key expires or they lose the fresh device?** They must start over with a new temp key and link.
- **What if relay URLs in link differ from original vault relays?** Requests use original relays (from shard data), responses use link's relays (where owner listens). Stewards should add the link's relay URLs to their vault config so future communication uses consistent relays.
- **What relays does owner use on fresh device?** Default to Horcrux relay (configurable). These relays are embedded in the recovery initiation link and stewards add them to their vault config.
- **How does owner's fresh device know which vault to reconstruct?** When first recovery response (shard) arrives, automatically create a local vault stub using metadata from the shard (vault ID, vault name from shard data). Subsequent shards are added to this vault.

---

## Requirements

### Functional Requirements - Onboarding

- **FR-001**: System MUST show "What brings you to Horcrux?" screen after welcome/onboarding
- **FR-002**: Screen MUST have three options: "I received an invitation", "I need to recover my vault", "I want to start backing up"
- **FR-003**: "Start backing up" MUST lead to existing account choice screen
- **FR-004**: "Received invitation" MUST prompt for invitation link/code
- **FR-005**: "Recover vault" MUST lead to recovery initiation flow

### Functional Requirements - Recovery Initiation Link

- **FR-006**: System MUST generate temporary Nostr keypair when owner starts recovery flow
- **FR-007**: System MUST prompt owner to enter vault name they want to recover
- **FR-008**: System MUST prompt owner to enter their name (for steward identification)
- **FR-009**: System MUST generate recovery initiation link with format: `horcrux://horcrux.app/recover/{code}?owner={tempPubkey}&vault={name}&name={ownerName}&relays={urls}`
- **FR-009a**: System MUST default to Horcrux relay URL, but allow owner to configure different relays
- **FR-009b**: Stewards MUST add the relay URLs from recovery initiation link to their vault's relay config for consistent communication
- **FR-010**: System MUST create `RecoveryInitiationLink` model to track the link
- **FR-011**: System MUST allow owner to copy/share the link

### Functional Requirements - Steward Processing

- **FR-012**: System MUST parse `/recover/` deep links in DeepLinkService
- **FR-013**: System MUST show steward the owner's claimed name and vault name
- **FR-014**: System MUST show steward a list of vaults they are steward for
- **FR-015**: System MUST allow steward to select which vault to initiate recovery for
- **FR-016**: System MUST set `ownerRecoveryPubkey` on RecoveryRequest when initiating on behalf
- **FR-017**: System MUST set `responseRelayUrls` from the recovery initiation link

### Functional Requirements - Response Routing

- **FR-018**: System MUST route recovery responses to `ownerRecoveryPubkey` when set (instead of `initiatorPubkey`)
- **FR-019**: System MUST use `responseRelayUrls` for sending responses when set
- **FR-020**: System MUST use original relay URLs (from shard data) for sending requests to stewards
- **FR-021**: Owner's app MUST listen for recovery responses addressed to their temp key
- **FR-022**: System MUST store `recoveryPubkey` on vault when steward approves (for future key rotation)
- **FR-023**: When first recovery response arrives on fresh device, system MUST automatically create a local vault stub using metadata from the shard (vault ID, vault name, owner pubkey)
- **FR-024**: Subsequent recovery responses MUST be added to the existing vault stub

---

## User Interface Flow

### What Brings You Here Screen

```
┌─────────────────────────────────────┐
│           Horcrux                   │
├─────────────────────────────────────┤
│                                     │
│   What brings you to Horcrux?       │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📨 I received an invitation     │ │
│ │    from a friend                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔄 I need to recover my vault   │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ➕ I want to start backing      │ │
│ │    up data                      │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### Owner Recovery Screen (Fresh Device)

```
┌─────────────────────────────────────┐
│ ← Recover Your Vault                │
├─────────────────────────────────────┤
│                                     │
│ To recover your vault, you'll send  │
│ a link to one of your stewards who  │
│ can help restore your access.       │
│                                     │
│ Vault Name                          │
│ ┌─────────────────────────────────┐ │
│ │ My Passwords                    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Your Name                           │
│ ┌─────────────────────────────────┐ │
│ │ Alice                           │ │
│ └─────────────────────────────────┘ │
│                                     │
│ This helps your steward identify    │
│ you and find the right vault.       │
│                                     │
│      [Generate Recovery Link]       │
│                                     │
└─────────────────────────────────────┘
```

### Owner Recovery Link Generated

```
┌─────────────────────────────────────┐
│ ← Recovery Link Ready               │
├─────────────────────────────────────┤
│                                     │
│ ✓ Your recovery link is ready!      │
│                                     │
│ Send this link to ONE of your       │
│ stewards. They will initiate        │
│ recovery on your behalf.            │
│                                     │
│ ⚠️ Sending to multiple stewards     │
│ may create duplicate recovery       │
│ sessions.                           │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ horcrux://horcrux.app/recover/  │ │
│ │ abc123...                       │ │
│ │                     [Copy] 📋   │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [Share Link]                │
│                                     │
│    [I've Sent the Link]             │
│                                     │
└─────────────────────────────────────┘
```

### Owner Waiting for Recovery

```
┌─────────────────────────────────────┐
│ ← Waiting for Recovery              │
├─────────────────────────────────────┤
│                                     │
│ 🔄 Waiting for your steward...      │
│                                     │
│ Once your steward initiates         │
│ recovery, you'll see progress here. │
│                                     │
│ Vault: My Passwords                 │
│ Status: Waiting for steward         │
│                                     │
│ ────────────────────────────────    │
│                                     │
│ When stewards approve, their        │
│ responses will appear below.        │
│                                     │
│ Responses: 0 of ? (threshold: ?)    │
│                                     │
│      [Cancel Recovery]              │
│                                     │
└─────────────────────────────────────┘
```

### Steward Recovery Accept Screen

```
┌─────────────────────────────────────┐
│ ← Recovery Request                  │
├─────────────────────────────────────┤
│                                     │
│ Someone is trying to recover        │
│ their vault:                        │
│                                     │
│ Claims to be: Alice                 │
│ Vault name: My Passwords            │
│                                     │
│ ─────────────────────────────────── │
│                                     │
│ Select the vault to recover:        │
│                                     │
│ ○ Alice's Passwords (Alice)         │
│ ○ Family Vault (Bob)                │
│ ○ Work Secrets (Carol)              │
│                                     │
│ ⚠️ Only initiate recovery if you    │
│ trust this request is from the      │
│ real vault owner.                   │
│                                     │
│      [Initiate Recovery]            │
│                                     │
│      [Ignore Request]               │
│                                     │
└─────────────────────────────────────┘
```

---

## Key Entities

### RecoveryInitiationLink (New)

```dart
typedef RecoveryInitiationLink = ({
  String code,              // Unique identifier
  String ownerTempPubkey,   // Owner's temporary key (hex)
  String vaultName,         // Claimed vault name
  String ownerName,         // Claimed owner name
  List<String> relayUrls,   // Where owner is listening
  DateTime createdAt,
});
```

### RecoveryRequest (Modified)

```dart
String? ownerRecoveryPubkey;    // Owner's temp key for lost-device flow
List<String>? responseRelayUrls; // Relays for sending responses
```

### Vault (Modified)

```dart
String? recoveryPubkey;  // Set when steward approves recovery for owner's temp key
```

---

## Deep Link Format

```
horcrux://horcrux.app/recover/{code}?owner={tempPubkey}&vault={encodedVaultName}&name={encodedOwnerName}&relays={relay1,relay2,relay3}
```

**Parameters:**
- `code`: Unique recovery initiation code
- `owner`: Owner's temporary pubkey (64 hex chars)
- `vault`: URL-encoded vault name (hint for steward)
- `name`: URL-encoded owner name (for identification)
- `relays`: Comma-separated relay URLs (where owner listens)

---

## Dependencies

- Requires existing recovery infrastructure
- Requires deep link handling (from invitation links feature)
- Should be built after Owner Self-Shard (006)


---

## Out of Scope

- Automatic steward discovery (owner must know who to contact)
- Multi-vault recovery in single flow (one vault at a time)
- Key rotation (covered in 008-key-rotation spec)
- Post-recovery key switching (covered in 008)
