# Horcrux Nostr Event Format — Canonical Specification

This document defines the intended canonical format for all custom Horcrux
Nostr events. It supersedes the current format documented in
`nostr-event-format-reference.md`. Implementation of this format is tracked
in bead `horcrux_app-8yw`.

---

## General Principles

### Content vs Tags

All data is carried in **tags**. The `content` field is used only when a value
is too large or too structured for a single tag — specifically, the Shamir
share payload on kinds 1337 and 1339.

| Event kind | `content` | Rationale |
|------------|-----------|-----------|
| 1337 (share) | Raw share payload (base64/hex string) | Main payload; can be hundreds of bytes |
| 1337 (manifest) | `""` (empty) | No Shamir material |
| 1338–1345 | `""` (empty) | All data fits in tags |

No JSON appears in `content` for any kind.

### Naming

- **Wire keys and tag names** use `share` (not `shard`). The old `shard_*`
  names are retired.
- All tag names are `snake_case`.
- Tag values are always strings (inherent to Nostr); consumers parse as needed.

### Redundant fields removed

The following are no longer included because they are already available from
the NIP-59 seal or gift wrap:

| Removed field | Source of same data |
|---------------|---------------------|
| `initiator_pubkey` (1338) | `rumor.pubkey` — the initiator signs the rumor |
| `responder_pubkey` (1339) | `rumor.pubkey` — the steward signs the rumor |
| `steward_pubkey` (1342, 1343) | `rumor.pubkey` — the steward signs the rumor |
| `invitee_pubkey` (1340, 1341) | `rumor.pubkey` — the invitee signs the rumor |
| `owner_pubkey` (1344, 1345) | `rumor.pubkey` — the owner signs the rumor |
| `creator_pubkey` (1337) | `rumor.pubkey` — the vault owner signs the rumor |
| `recipient_pubkey` (1337) | Gift wrap `p` tag — the recipient |
| `is_received`, `received_at` (1337) | Ingest-side metadata; not published |

### Expiration

No NIP-40 `expiration` tag is set by default. A future NIP specification will
recommend setting an appropriate expiration on the gift wrap based on event
kind.

### `type` field

The `"type"` field is removed from all event content. The Nostr kind number is
the type discriminator.

### Share vs manifest on kind 1337

No explicit `share_kind` tag is needed. The `content` field is the discriminator:

- `content != ""` → normal share (the content is the Shamir payload)
- `content == ""` → manifest (no Shamir material)

This is unambiguous because a real share always has non-empty Shamir bytes.
The old v1 implicit sentinel (`shareIndex == -1`) is retired; `share_index`
is simply omitted from manifest tags.

### Recovery request ID

`recovery_request_id` is a cryptographically random string with no embedded
vault ID. (Previously: `<secureId>_<vaultId>`.)

### Timestamps

No `*_at` tags (e.g. `responded_at`, `confirmed_at`, `reported_at`, etc.).
The rumor's `created_at` is the authoritative timestamp for all event types.

---

## Kind 1337 — Share Data

### Variant A: Normal Share

**Content:** Raw Shamir share payload string (base64 or hex encoding).

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `share_index` | ✅ | `"2"` | 0-based slot index (string) |
| `total_shares` | ✅ | `"3"` | |
| `threshold` | ✅ | `"2"` | |
| `prime_mod` | ✅ | `"<hex>"` | |
| `vault_id` | ✅ | `"<uuid>"` | |
| `vault_name` | ✅ | `"My Secret"` | |
| `owner_name` | ❌ | `"Alice"` | Display name of the vault owner |
| `instructions` | ❌ | `"Keep this safe!"` | Free text for stewards |
| `distribution_version` | ✅ | `"1"` | Monotonically increasing; used for stale-detection |
| `push_enabled` | ❌ | `"true"` | Whether the owner has opted in to push notifications. Auto-redistributed on change, so always reflects current state |
| `steward` | ✅ (≥1) | `"0"`, `"Alice"`, `"<hex>"` | Repeated tag: `["steward", "<slot>", "<name>", "<pubkey>", "<contact_info>"]`; 5th element always present — empty string `""` if no contact info |
| `relay` | ✅ (≥1) | `"wss://relay.example.com"` | Repeated tag, one per relay |

**Example rumor:**

```jsonc
{
  "kind": 1337,
  "pubkey": "<owner_hex_64>",
  "content": "aGVsbG8gd29ybGQ=",    // raw share payload
  "tags": [
    ["share_index", "2"],
    ["total_shares", "3"],
    ["threshold", "2"],
    ["prime_mod", "<hex_prime>"],
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["vault_name", "My Secret"],
    ["owner_name", "Alice"],
    ["instructions", "Keep this safe!"],
    ["distribution_version", "1"],
    ["push_enabled", "true"],
    ["steward", "0", "Alice",   "<alice_hex_64>", ""],
    ["steward", "1", "Bob",     "<bob_hex_64>",  "bob@example.com"],
    ["steward", "2", "Carol",   "<carol_hex_64>", ""],
    ["relay", "wss://relay.damus.io"],
    ["relay", "wss://relay.nostr.band"]
  ],
  "created_at": 1734567890
}
```

### Variant B: Manifest

**Content:** `""` (empty string).

**Tags:** Same as above except `share_index` is
omitted, and `content` is empty.

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `total_shares` | ✅ | `"3"` | |
| `threshold` | ✅ | `"2"` | |
| `prime_mod` | ✅ | `"<hex>"` | From the first real share |
| `vault_id` | ✅ | `"<uuid>"` | |
| `vault_name` | ✅ | `"My Secret"` | |
| `owner_name` | ❌ | `"Alice"` | |
| `instructions` | ❌ | `"Keep this safe!"` | |
| `distribution_version` | ✅ | `"1"` | |
| `push_enabled` | ❌ | `"true"` | |
| `steward` | ✅ (≥1) | `"0"`, `"Alice"`, `"<hex>"` | Same format as normal share |
| `relay` | ✅ (≥1) | `"wss://relay.example.com"` | |

**Example rumor:**

```jsonc
{
  "kind": 1337,
  "pubkey": "<owner_hex_64>",
  "content": "",
  "tags": [
    ["total_shares", "3"],
    ["threshold", "2"],
    ["prime_mod", "<hex_prime>"],
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["vault_name", "My Secret"],
    ["owner_name", "Alice"],
    ["instructions", "Keep this safe!"],
    ["distribution_version", "1"],
    ["push_enabled", "true"],
    ["steward", "0", "Alice",   "<alice_hex_64>", ""],
    ["steward", "1", "Bob",     "<bob_hex_64>", ""],
    ["steward", "2", "Carol",   "<carol_hex_64>", ""],
    ["relay", "wss://relay.damus.io"]
  ],
  "created_at": 1734567890
}
```

---

## Kind 1338 — Recovery Request

**Content:** `""` (empty).

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `recovery_request_id` | ✅ | `"<secure_random_id>"` | No embedded vault ID |
| `vault_id` | ✅ | `"<uuid>"` | |
| `is_practice` | ❌ | `"false"` | Absent = `false` |

**Example rumor:**

```jsonc
{
  "kind": 1338,
  "pubkey": "<initiator_hex_64>",
  "content": "",
  "tags": [
    ["recovery_request_id", "a1b2c3d4e5f6"],
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["is_practice", "false"]
  ],
  "created_at": 1734567890
}
```

---

## Kind 1339 — Recovery Response

**Content:** Raw Shamir share payload string when approved and not practice;
`""` (empty) otherwise.

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `recovery_request_id` | ✅ | `"a1b2c3d4e5f6"` | Matches the request |
| `vault_id` | ✅ | `"<uuid>"` | |
| `is_practice` | ❌ | `"false"` | Absent = `false` |
| `share_index` | conditional | `"1"` | Required when content is non-empty |
| `total_shares` | conditional | `"3"` | Same conditions as `share_index` |
| `threshold` | conditional | `"2"` | Same conditions as `share_index` |
| `prime_mod` | conditional | `"<hex>"` | Same conditions as `share_index` |
| `distribution_version` | conditional | `"1"` | Same conditions as `share_index` |
| `steward` | conditional | `"0"`, `"Alice"`, `"<hex>"` | Same format as 1337; same conditions as `share_index` |
| `relay` | conditional | `"wss://relay.example.com"` | Same conditions as `share_index` |

**Example rumor — approval with share:**

Approval is implicit: `content` is non-empty (real share payload).

```jsonc
{
  "kind": 1339,
  "pubkey": "<steward_hex_64>",
  "content": "aGVsbG8gd29ybGQ=",    // raw share payload
  "tags": [
    ["recovery_request_id", "a1b2c3d4e5f6"],
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["share_index", "1"],
    ["total_shares", "3"],
    ["threshold", "2"],
    ["prime_mod", "<hex_prime>"],
    ["distribution_version", "1"],
    ["steward", "0", "Alice",   "<alice_hex_64>", ""],
    ["steward", "1", "Bob",     "<bob_hex_64>", ""],
    ["steward", "2", "Carol",   "<carol_hex_64>", ""],
    ["relay", "wss://relay.damus.io"]
  ],
  "created_at": 1734567900
}
```

**Example rumor — practice approval:**

No share payload; `is_practice=true` signals approval.

```jsonc
{
  "kind": 1339,
  "pubkey": "<steward_hex_64>",
  "content": "",
  "tags": [
    ["recovery_request_id", "a1b2c3d4e5f6"],
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["is_practice", "true"]
  ],
  "created_at": 1734567900
}
```

**Example rumor — denial:**

Empty content with no `is_practice`.

```jsonc
{
  "kind": 1339,
  "pubkey": "<steward_hex_64>",
  "content": "",
  "tags": [
    ["recovery_request_id", "a1b2c3d4e5f6"],
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"]
  ],
  "created_at": 1734567900
}
```

---

## Kind 1340 — Invitation Acceptance

**Content:** `""` (empty).

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `invite_code` | ✅ | `"<code>"` | |
| `vault_id` | ✅ | `"<uuid>"` | |

**Example rumor:**

```jsonc
{
  "kind": 1340,
  "pubkey": "<invitee_hex_64>",
  "content": "",
  "tags": [
    ["invite_code", "abc123def456"],
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"]
  ],
  "created_at": 1734568000
}
```

---

## Kind 1341 — Invitation Denial

**Content:** `""` (empty).

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `invite_code` | ✅ | `"<code>"` | |

**Example rumor:**

```jsonc
{
  "kind": 1341,
  "pubkey": "<invitee_hex_64>",
  "content": "",
  "tags": [
    ["invite_code", "abc123def456"]
  ],
  "created_at": 1734568100
}
```

---

## Kind 1342 — Share Confirmation

**Content:** `""` (empty).

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `vault_id` | ✅ | `"<uuid>"` | |
| `share_index` | ✅ | `"2"` | Confirmed share slot |
| `distribution_version` | ✅ | `"1"` | Enables stale-ack detection |

**Example rumor:**

```jsonc
{
  "kind": 1342,
  "pubkey": "<steward_hex_64>",
  "content": "",
  "tags": [
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["share_index", "2"],
    ["distribution_version", "1"]
  ],
  "created_at": 1734568200
}
```

---

## Kind 1343 — Share Error

**Content:** `""` (empty).

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `vault_id` | ✅ | `"<uuid>"` | |
| `share_index` | ✅ | `"2"` | |
| `error` | ✅ | `"Failed to decrypt share"` | |

**Example rumor:**

```jsonc
{
  "kind": 1343,
  "pubkey": "<steward_hex_64>",
  "content": "",
  "tags": [
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"],
    ["share_index", "2"],
    ["error", "Failed to decrypt share"]
  ],
  "created_at": 1734568300
}
```

---

## Kind 1344 — Invitation Invalid

**Content:** `""` (empty).

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `invite_code` | ✅ | `"<code>"` | |
| `reason` | ✅ | `"Already used"` | |

**Example rumor:**

```jsonc
{
  "kind": 1344,
  "pubkey": "<owner_hex_64>",
  "content": "",
  "tags": [
    ["invite_code", "abc123def456"],
    ["reason", "This invitation has already been used"]
  ],
  "created_at": 1734568400
}
```

---

## Kind 1345 — Steward Removed

**Content:** `""` (empty).

**Tags:**

| Tag | Required | Example | Notes |
|-----|----------|---------|-------|
| `vault_id` | ✅ | `"<uuid>"` | |

**Example rumor:**

```jsonc
{
  "kind": 1345,
  "pubkey": "<owner_hex_64>",
  "content": "",
  "tags": [
    ["vault_id", "f47ac10b-58cc-4372-a567-0e02b2c3d479"]
  ],
  "created_at": 1734568500
}
```

---

## Changes from Current Format

| Change | Affected kinds | Rationale |
|--------|---------------|-----------|
| `shard` → `share` in all wire keys and tag names | 1337, 1338, 1339 | Consistency with Dart model; no deployed clients require backward compat |
| No `share_kind` tag — `content` emptiness discriminates share vs manifest | 1337 | Empty content = manifest, non-empty = share; unambiguous since real shares always have Shamir bytes |
| Removed all tags from 1337 rumor (old tags); new tags carry all data | 1337 | Old tags (`backup_config_id`, `shard_index`, `d`) were redundant with content |
| `content` is raw payload string, not JSON | 1337, 1339 | Tags carry structure; content carries the one large blob |
| `content` is empty | 1338, 1340–1345 | All data in tags; no JSON in content |
| Removed `"type"` field from content | 1338–1345 | Kind number is the type |
| Removed `initiator_pubkey`, `responder_pubkey`, `steward_pubkey`, `invitee_pubkey`, `owner_pubkey`, `creator_pubkey`, `recipient_pubkey` | all | Redundant with `rumor.pubkey` or gift wrap `p` tag |
| Removed `is_received`, `received_at`, `nostr_event_id` from 1337 content | 1337 | Ingest-side metadata; never should have been published |
| `recovery_request_id` is bare random ID | 1338 | No embedded vault ID suffix |
| Removed `requested_at` from 1338 tags | 1338 | Redundant with `rumor.created_at` |
| Removed `expires_at` from 1338 tags | 1338 | Would collide with NIP-40 `expiration` tag on the gift wrap |
| Removed `threshold` from 1338 tags | 1338 | Steward derives it from their held share; initiator already has it locally |
| Removed `steward` roster from 1338 tags | 1338 | Each steward gets their own gift-wrapped copy; they don't need the roster |
| Removed `approved` from 1339 tags | 1339 | Derivable: non-empty content = approved, `is_practice=true` = practice approved, otherwise denied |
| Removed all `*_at` timestamp tags (`responded_at`, `confirmed_at`, `reported_at`, `invalidated_at`, `removed_at`) | 1340–1345 | Redundant with `rumor.created_at` |
| Removed `removed_pubkey` from 1345 tags | 1345 | Recipient is the removed steward (gift wrap targets them); they already know it's themselves |
| Unified tag names: `vault_id`, `share_index` everywhere | all | Was `backup_config_id` / `vault` / `shard` depending on kind |
| `distribution_version` required on share confirmation | 1342 | Enables stale-ack detection |
| No default NIP-40 expiration | all | Defer to NIP recommendation |
| Stewards list as repeated `steward` tags | 1337, 1339 | Replaces nested JSON array |

## Backward Compatibility

Since Horcrux is alpha software with no other deployed clients, no backward
compatibility layer is required. The receiver should accept only the new
format. If a transition period is needed, receivers can fall back to the old
format when `content` contains JSON (old format) instead of a raw payload
string (new format). The `shareIndex == -1` sentinel still identifies
manifests in the old format.

---

## Summary Table

| Kind | Name | Content | Direction |
|------|------|---------|-----------|
| 1337 | Share / Manifest | Share payload string (or `""`) | Owner → Steward/Owner |
| 1338 | Recovery Request | `""` | Initiator → Stewards |
| 1339 | Recovery Response | Share payload string (or `""`) | Steward → Initiator |
| 1340 | Invitation Acceptance | `""` | Invitee → Owner |
| 1341 | Invitation Denial | `""` | Invitee → Owner |
| 1342 | Share Confirmation | `""` | Steward → Owner |
| 1343 | Share Error | `""` | Steward → Owner |
| 1344 | Invitation Invalid | `""` | Owner → Invitee |
| 1345 | Steward Removed | `""` | Owner → Steward |
