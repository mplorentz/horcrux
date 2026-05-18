# Horcrux Nostr Event Format Reference

This document catalogs every custom Nostr event kind that Horcrux publishes,
showing the full on-the-wire structure of the **rumor** (the unencrypted inner
event inside the NIP-59 gift wrap). All events are delivered as NIP-59
gift wraps (outer kind 1059); the inner kinds listed below are what
application code reads after unwrapping.

> **Scope:** This covers the *current* format as of the codebase at HEAD.
> Known inconsistencies and potential improvements are noted inline and
> collected in the [Open Issues](#open-issues) section. Bead
> `horcrux_app-8yw` tracks the format refactor.

---

## Envelope: NIP-59 Gift Wrap (kind 1059)

Every Horcrux event is wrapped in a NIP-59 gift wrap for encryption and sender
anonymity. The outer structure is always:

```jsonc
{
  "id": "<event_id>",
  "kind": 1059,                 // NIP-59 gift wrap
  "pubkey": "<ephemeral_pubkey>", // NOT the sender — random per wrap
  "content": "<nip44_encrypted_seal>",
  "tags": [
    ["p", "<recipient_pubkey_hex>"],   // who it's for
    ["expiration", "<unix_seconds>"]    // NIP-40; defaults to 7 days
  ],
  "created_at": <unix_seconds>
}
```

The recipient decrypts the seal to reveal the **rumor** (inner event), whose
`kind` and `content` are described below.

### Expiration policy (current)

`NdkService._buildGiftWrapEvent` adds an `expiration` tag to every gift wrap.
When `nip40Expiration` is not explicitly passed:

| Condition | Behavior |
|-----------|----------|
| `nip40Expiration == null` | Adds 7-day expiration (default) |
| `nip40Expiration == Duration.zero` | **No** expiration tag added |
| `nip40Expiration == some Duration` | Expiration = `now + duration` |

**Current state:** No caller passes `nip40Expiration`, so **all** events get a
7-day expiration. This is too short for share/manifest events that stewards
may need to fetch long after publication.

---

## Kind 1337 — Share Data

**Purpose:** Distribute a Shamir secret share to a steward, or carry a
manifest-only metadata snapshot to the vault owner.

**Sender:** Vault owner (`customPubkey` = owner's hex pubkey)
**Recipient:** Each steward gets their own gift wrap; the owner gets a
separate manifest-only gift wrap if they are not a self-steward.

### Variant A: Normal Share

The `content` field contains JSON with the Shamir share material and
recovery-plan metadata:

```jsonc
{
  // ── Shamir material (required) ──
  "shard": "<base64_or_hex_shamir_share>",
  "shard_index": 2,             // 0-based slot index
  "total_shards": 3,
  "threshold": 2,
  "prime_mod": "<hex_prime_modulus>",

  // ── Provenance ──
  "creator_pubkey": "<owner_hex_pubkey_64chars>",
  "created_at": 1734567890,     // Unix seconds

  // ── Recovery plan metadata (optional but always present in current code) ──
  "vault_id": "<uuid>",
  "vault_name": "My Secret",
  "owner_name": "Alice",
  "instructions": "Please keep this safe!",
  "stewards": [
    {
      "name": "Alice",
      "pubkey": "<hex_64chars>",
      "shard_index": "0",        // STRING, not int; 0-based slot
      "contactInfo": "alice@example.com"  // optional
    },
    {
      "name": "Bob",
      "pubkey": "<hex_64chars>",
      "shard_index": "1"
    },
    {
      "name": "Carol",
      "pubkey": "<hex_64chars>",
      "shard_index": "2"
    }
  ],

  // ── Routing & versioning ──
  "recipient_pubkey": "<this_steward_hex_64chars>",
  "relay_urls": ["wss://relay.example.com"],
  "distribution_version": 1,    // monotonically increasing int

  // ── Receipt metadata (set on ingest, not on publish) ──
  "is_received": true,           // steward-side only
  "received_at": "2025-11-18T15:30:00.000Z",

  // ── Push notifications ──
  "push_enabled": true           // whether owner has opted in to push
}
```

### Variant B: Manifest-Only (owner rehydration)

When the vault owner is **not** a self-steward, a manifest-only 1337 is sent
to the owner's pubkey with `shard` = `""` and `shard_index` = `-1` as the
implicit discriminator. This carries all the metadata (vault name, stewards,
instructions, etc.) but no Shamir material, so the owner can reconstruct their
`BackupConfig` on a fresh device without holding a steward slot.

```jsonc
{
  "shard": "",                    // empty — no Shamir material
  "shard_index": -1,              // sentinel: means "manifest"
  "total_shards": 3,
  "threshold": 2,
  "prime_mod": "<hex_from_first_real_share>",
  "creator_pubkey": "<owner_hex>",
  "created_at": 1734567890,
  "vault_id": "<uuid>",
  "vault_name": "My Secret",
  "owner_name": "Alice",
  "instructions": "Keep safe!",
  "stewards": [ /* same as normal share */ ],
  "recipient_pubkey": "<owner_hex>",
  "relay_urls": ["wss://relay.example.com"],
  "distribution_version": 1,
  "push_enabled": true

  // NOTE: is_received, received_at, nostr_event_id are NOT set on manifest
}
```

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `shard_<vaultId>_<index>` | NIP-33 style replaceable distinguisher for normal shares |
| `d` | `manifest_<vaultId>` | For manifest-only variant |
| `backup_config_id` | `<vaultId>` | Redundant with `vault_id` in content |
| `shard_index` | `"2"` or `"-1"` | String form of share index |

---

## Kind 1338 — Recovery Request

**Purpose:** A vault owner (or their device) asks stewards to return their
Shamir shares for vault recovery.

**Sender:** Recovery initiator (`customPubkey` = initiator's hex pubkey)
**Recipient:** Each steward gets their own gift wrap.

### Rumor content

```jsonc
{
  "type": "recovery_request",
  "recovery_request_id": "<secure_random_id>_<vaultId>",
  "vault_id": "<uuid>",
  "initiator_pubkey": "<hex_64chars>",
  "requested_at": "2025-11-18T15:30:00.000Z",
  "expires_at": null,             // optional; null in current code
  "threshold": 2,
  "is_practice": false            // true for practice recovery
}
```

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `recovery_request_<requestId>` | |
| `vault_id` | `<uuid>` | |
| `recovery_request_id` | `<requestId>` | |

### ⚠️ Known issue

The `steward_pubkeys` field is **not** included in the published request. The
incoming handler in `NdkService._handleRecoveryRequestData` constructs
`RecoveryRequest.makeFromParticipants` with `stewardPubkeys: const []`.
This means the initiator cannot reconstruct the participant roster from their
own published event.

---

## Kind 1339 — Recovery Response

**Purpose:** A steward approves or denies a recovery request, optionally
including their Shamir share material.

**Sender:** Steward (`customPubkey` = steward's hex pubkey, or omitted for
default identity)
**Recipient:** The recovery initiator.

### Rumor content — Approval with share

```jsonc
{
  "type": "recovery_response",
  "recovery_request_id": "<requestId>",
  "vault_id": "<uuid>",
  "responder_pubkey": "<steward_hex>",
  "approved": true,
  "responded_at": "2025-11-18T15:45:00.000Z",
  "is_practice": false,
  "shard_data": {                 // only when approved && !isPractice
    "shard": "<shamir_share>",
    "shard_index": 1,
    "total_shards": 3,
    "threshold": 2,
    "prime_mod": "<hex>",
    "creator_pubkey": "<owner_hex>",
    "created_at": 1734567890,
    "vault_id": "<uuid>",
    "vault_name": "My Secret",
    "owner_name": "Alice",
    "stewards": [ /* ... */ ],
    "relay_urls": ["wss://relay.example.com"],
    "distribution_version": 1
    // ... all Share fields
  }
}
```

### Rumor content — Denial (or practice approval)

```jsonc
{
  "type": "recovery_response",
  "recovery_request_id": "<requestId>",
  "vault_id": "<uuid>",
  "responder_pubkey": "<steward_hex>",
  "approved": false,
  "responded_at": "2025-11-18T15:45:00.000Z",
  "is_practice": false
  // no shard_data key
}
```

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `recovery_response_<requestId>_<stewardPubkey>` | |
| `vault_id` | `<uuid>` | |
| `recovery_request_id` | `<requestId>` | |
| `approved` | `"true"` / `"false"` | String, not boolean |

---

## Kind 1340 — Invitation Acceptance

**Purpose:** An invitee accepts an invitation to become a steward.

**Sender:** Invitee (default identity)
**Recipient:** Vault owner.

### Rumor content

```jsonc
{
  "invite_code": "<invite_code_string>",
  "vault_id": "<uuid>",
  "invitee_pubkey": "<invitee_hex_64chars>",
  "responded_at": "2025-11-18T16:00:00.000Z"
}
```

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `invitation_acceptance_<inviteCode>` | |
| `invite` | `<inviteCode>` | |

---

## Kind 1341 — Invitation Denial

**Purpose:** An invitee declines an invitation to become a steward.

**Sender:** Invitee (default identity)
**Recipient:** Vault owner.

### Rumor content

```jsonc
{
  "invite_code": "<invite_code_string>",
  "invitee_pubkey": "<invitee_hex_64chars>",
  "responded_at": "2025-11-18T16:00:00.000Z",
  "reason": "I can't help right now"   // optional
}
```

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `invitation_denial_<inviteCode>` | |
| `invite` | `<inviteCode>` | |

---

## Kind 1342 — Share Confirmation

**Purpose:** A steward confirms successful receipt and storage of a Shamir
share. This is the "ack" that moves the steward's status from `awaitingKey`
to `holdingKey`.

**Sender:** Steward (default identity)
**Recipient:** Vault owner.

### Rumor content

```jsonc
{
  "type": "shard_confirmation",
  "vault_id": "<uuid>",
  "shard_index": 2,             // int in content JSON
  "steward_pubkey": "<steward_hex>",
  "confirmed_at": "2025-11-18T16:10:00.000Z"
}
```

> **Note:** VaultShareService also publishes 1342 with **empty** `content`
> (`""`) and puts all data in tags instead. The owner-side processor
> (`ShareDistributionService.processShareConfirmationEvent`) reads exclusively
> from tags. This is an inconsistency — the content JSON is written but
> ignored.

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `shard_confirmation_<vaultId>_<shareIndex>` | |
| `vault_id` | `<uuid>` | |
| `shard_index` | `"2"` | String in tag (vs int in content) |
| `steward_pubkey` | `<hex>` | Written by VaultShareService only |
| `confirmed_at` | ISO-8601 | Written by VaultShareService only |
| `distribution_version` | `"1"` | Optional, written by VaultShareService |

---

## Kind 1343 — Share Error

**Purpose:** A steward reports an error processing share material (e.g.,
decryption failure, invalid share).

**Sender:** Steward (default identity)
**Recipient:** Vault owner.

### Rumor content

```jsonc
{
  "type": "shard_error",
  "vault_id": "<uuid>",
  "shard_index": 2,
  "steward_pubkey": "<steward_hex>",
  "error": "Failed to decrypt shard",
  "reported_at": "2025-11-18T16:15:00.000Z"
}
```

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `shard_error_<vaultId>_<shareIndex>` | |
| `vault_id` | `<vaultId>` | Tag key is `vault_id` |
| `shard` | `"2"` | **Inconsistent**: tag key is `shard`, not `shard_index` |
| `p` | `<owner_hex>` | Recipient |

### ⚠️ Tag naming inconsistency

The tag uses `shard` for the share index, while kind 1342 uses `shard_index`.
The content JSON uses `shard_index`. The processing code
(`processShareErrorEvent`) reads `vault` (not `vault_id`) for the vault ID
tag.

---

## Kind 1344 — Invitation Invalid

**Purpose:** Vault owner notifies an invitee that their invitation code is
invalid (e.g., already used, expired, wrong vault).

**Sender:** Vault owner (default identity)
**Recipient:** Invitee.

### Rumor content

```jsonc
{
  "type": "invitation_invalid",
  "invite_code": "<code>",
  "owner_pubkey": "<owner_hex>",
  "reason": "This invitation has already been used",
  "invalidated_at": "2025-11-18T16:20:00.000Z"
}
```

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `invitation_invalid_<inviteCode>` | |
| `invite_code` | `<code>` | |

---

## Kind 1345 — Steward Removed

**Purpose:** Vault owner notifies a steward that they have been removed from
the vault's recovery plan. The steward should archive the vault and delete
their held share.

**Sender:** Vault owner (default identity)
**Recipient:** The removed steward.

### Rumor content

```jsonc
{
  "type": "steward_removed",
  "vault_id": "<uuid>",
  "removed_pubkey": "<steward_hex>",
  "owner_pubkey": "<owner_hex>",
  "removed_at": "2025-11-18T16:25:00.000Z"
}
```

### Tags on the rumor

| Tag | Example | Notes |
|-----|---------|-------|
| `d` | `steward_removed_<vaultId>_<removedPubkey>` | |
| `vault_id` | `<uuid>` | |
| `removed_pubkey` | `<hex>` | |

---

## Open Issues & Inconsistencies

### 1. `shard` vs `share` naming

The wire JSON uses `shard_*` keys (`shard`, `shard_index`, `total_shards`),
while the Dart model uses `Share`, `shareIndex`, `totalShares`. The code
comments say "wire keys remain shard_* per protocol stability" but this was a
decision made before any other clients existed. Now is the time to pick one
direction and migrate.

- **Option A (align wire to Dart):** Rename wire keys to `share`,
  `share_index`, `total_shares`. Accept both old and new for a grace period.
- **Option B (keep wire as-is):** Document the split and accept it.

### 2. Manifest discriminator is implicit

Kind 1337 manifests are identified by `shard == ""` and `shard_index == -1`.
There is no explicit `share_kind` field, making the contract fragile and
requiring special-case logic in `Share.isValid`. The bead `horcrux_app-8yw`
proposes adding an explicit `share_kind` field with values `"share"` and
`"manifest"`.

### 3. Per-kind expiration policy

All gift wraps get a 7-day NIP-40 expiration because no caller passes
`nip40Expiration`. This is wrong for:
- **Share data / manifests (1337):** Should be long-lived (30+ days) or
  have no expiration. Stewards may join late or reinstall.
- **Recovery requests (1338):** 7 days is reasonable.
- **Recovery responses (1339):** 7 days is reasonable; may want shorter.
- **Confirmations / errors (1342, 1343):** 7 days is fine.
- **Steward removal (1345):** Should be long-lived; the removed steward
  needs to see it eventually.

### 4. Redundant data in tags vs content

Kind 1342 (share confirmation) puts data in **both** content JSON and tags.
The owner-side processor only reads tags. This duplication is confusing.

Some events (1337, 1338, 1339) have `vault_id` in both content and rumor
tags. The tag-based `vault_id` is useful for relay filtering without
decryption, but the content-based one is what application code reads.

### 5. Tag naming inconsistencies

| Kind | Tag key for share index | Tag key for vault ID |
|------|------------------------|----------------------|
| 1337 | `shard_index` | `backup_config_id` |
| 1342 | `shard_index` | `vault_id` |
| 1343 | `shard` | `vault` |
| 1345 | — | `vault_id` |

Kind 1337 uses `backup_config_id` (not `vault_id`), and kind 1343 uses
`shard` (not `shard_index`) and `vault` (not `vault_id`).

### 6. Missing `steward_pubkeys` in recovery request (1338)

The recovery request payload does not include the list of steward pubkeys.
The incoming handler hardcodes `stewardPubkeys: const []`. The initiator
cannot reconstruct the participant roster from their own published request.
See the bead note on this.

### 7. `type` field only on some events

Kinds 1338, 1339, 1342, 1343, 1344, 1345 include a `"type"` field in their
content JSON (e.g., `"type": "recovery_request"`). Kind 1337 does **not**
have a `"type"` field — it relies entirely on the Nostr kind number for
dispatch. This inconsistency is minor but worth noting.

### 8. `shard_index` type varies

In content JSON, `shard_index` is an **int**. In rumor tags, it's a
**string**. In the `stewards` array within kind 1337, each steward's
`shard_index` is a **string** (despite being numeric). This is inherent to
Nostr tags (always strings) but the stewards-array inconsistency is a
code choice.

### 9. `approved` tag on kind 1339 is a string

The tag `["approved", "true"]` is a string `"true"`, not a boolean. This is
correct for Nostr tags (always strings) but worth documenting for consumers.

---

## Summary Table

| Kind | Name | Direction | Has content JSON | Content `type` field | Expiration (default) |
|------|------|-----------|-----------------|---------------------|---------------------|
| 1337 | Share Data / Manifest | Owner → Steward (or Owner) | ✅ | ❌ | 7 days |
| 1338 | Recovery Request | Initiator → Stewards | ✅ | `"recovery_request"` | 7 days |
| 1339 | Recovery Response | Steward → Initiator | ✅ | `"recovery_response"` | 7 days |
| 1340 | Invitation Acceptance | Invitee → Owner | ✅ | ❌ | 7 days |
| 1341 | Invitation Denial | Invitee → Owner | ✅ | ❌ | 7 days |
| 1342 | Share Confirmation | Steward → Owner | ✅ (or empty) | `"shard_confirmation"` | 7 days |
| 1343 | Share Error | Steward → Owner | ✅ | `"shard_error"` | 7 days |
| 1344 | Invitation Invalid | Owner → Invitee | ✅ | `"invitation_invalid"` | 7 days |
| 1345 | Steward Removed | Owner → Steward | ✅ | `"steward_removed"` | 7 days |
