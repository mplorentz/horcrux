# NIP-XX: Shamir's Secret Sharing for Distributed Backup

`draft` `optional`

## Abstract

This NIP defines a protocol for backup and recovery of sensitive data with peers via the Nostr network. It uses [Shamir's Secret Sharing](https://en.wikipedia.org/wiki/Shamir%27s_secret_sharing) algorithm to break secret data (a *vault*) into a number of shares which are distributed via encrypted Nostr events to a pre-defined set of trusted peers (called *stewards*). These stewards can then combine their shares in order to recover the original secret.

## Overview

The system consists of several phases:

1. **Invitation Phase** (optional): Vault owner invites stewards via unique invitation codes
2. **Distribution Phase**: Vault owner splits the secret into shares and distributes them to stewards via encrypted events
4. **Recovery Phase**: Any steward can initiate recovery, requesting shares from other stewards. Once enough shares are assembled the key can be decrypted.

*TODO: Say something about the p2p assumptions made here. One share == one device atm*

## Event Kinds

This protocol defines the following custom event kinds:

*TODO: all event kinds subject to change*

- `713`: Share Distribution *(was 1337)*
- `714`: Recovery Request *(was 1338)*
- `715`: Recovery Response *(was 1339)*
- `716`: Invitation Acceptance *(was 1340)*
- `717`: Invitation Denial *(was 1341)*
- `718`: Share Confirmation *(was 1342)* — *TODO: is there some generic ACK kind already we should reuse here?*
- `719`: Share Error *(was 1343)*
- `720`: Invitation Invalid *(was 1344)*
- `721`: Key Holder Removed *(was 1345)*

All events MUST be wrapped using NIP-59 gift wrap (kind 1059) for privacy and MAY include NIP-40 expiration tags.

## Event Flow

The event flow goes something like this:

- Owner optionally distributes invitiation codes via a link or some other method. Each steward should receive a unique code that they can include in an Invititation Acceptance (or Invitation Denial) event. This event represents consent from the steward to hold a share and serves as a convenient way for the owner to learn the steward's preferred npub.
- After all stewards have been added, the owner distributes a share to each steward in a Share Distribution event. Stewards MUST respond with a Share Confirmation event after receiving their share. The owner MAY decide to keep a share for themselves and destroy the secret.
- From here any steward or the owner can initiate recovery by sending Recovery Requests to all stewards. Stewards respond with a Recovery Response, which includes their share if they approved the request.
- At any point the owner may change the secret or other parameters and send new Share Distribution events for the same vault, incrementing the distribution_version number in the event content. *TODO: Stewards MUST destroy the old shares once everyone has confirmed that they have the new shares, but how will they know? Probably we need another event.*
- At any point a Steward may receive a Steward Removed event from the owner. If received the steward MUST destroy their share.

*TODO: How do we version this protocol to support i.e. large files in the future*

## Event Structures

### Share Distribution (Kind 1337)

Used to distribute a Shamir secret share to a steward.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap (kind 1059 containing kind 13 seal) before publishing.

*TODO: **sigh** should I put the share data in the tags or stringified JSON in the contents? 🤷‍♂️*

```json
{
  "kind": 1337,
  "pubkey": "<creator-pubkey-hex>",
  "tags": [
    ["p", "<recipient-pubkey-hex>"]
  ],
  "created_at": <timestamp>,
  "content": {
    "share": "<base64-encoded-share-bytes>",
    "threshold": 3,
    "share_index": 0,
    "total_shares": 5,
    "scheme": "gf256_v1",
    "creator_pubkey": "<creator-pubkey-hex>", // *TODO: this is redundant*
    "created_at": <unix-timestamp>,
    "vault_id": "<unique-vault-identifier>",
    "vault_name": "My Secret Vault",
    "peers": [
      {"name": "Alice", "pubkey": "<alice-pubkey-hex>"},
      {"name": "Bob", "pubkey": "<bob-pubkey-hex>"}
    ],
    "owner_name": "Charlie",
    "instructions": "Contact me if you receive a recovery request",
    "relay_urls": ["wss://relay1.com", "wss://relay2.com"],
    "distribution_version": 1
  }
}
```

**Field Descriptions**:
- `share`: Base64-encoded Shamir share bytes
- `threshold`: Minimum number of shares required to reconstruct the secret
- `share_index`: Zero-based index of this specific share
- `total_shares`: Total number of shares created
- `scheme`: Shamir scheme identifier. `gf256_v1` for GF(2⁸) with Rijndael polynomial (0x11b).
  Legacy `prime_mod` values are accepted for backward compatibility but SHOULD NOT be used for new shares.
- `creator_pubkey`: Public key of the vault owner (hex format)
- `created_at`: Unix timestamp when share was created
- `vault_id`: Unique identifier for the vault
- `vault_name`: Human-readable name of the vault
- `peers`: List of other stewards (excludes the recipient)
- `owner_name`: Display name of the vault owner
- `instructions`: Optional instructions for stewards
- `relay_urls`: List of relay URLs for communication
- `distribution_version`: Version number to track redistributions

### Invitation Acceptance (Kind 1340)

Sent by an invitee to accept an invitation and become a steward.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap before publishing.

```json
{
  "kind": 1340,
  "pubkey": "<invitee-pubkey-hex>",
  "tags": [
    ["p", "<owner-pubkey-hex>"],
    ["invite", "<invite-code>"]
  ],
  "created_at": <timestamp>,
  "content": {
    "invite_code": "<unique-invite-code>",
    "pubkey": "<invitee-pubkey-hex>",
    "timestamp": "2025-11-24T10:00:00Z"
  }
}
```

### Invitation Denial (Kind 1341)

Sent by an invitee to decline an invitation.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap before publishing.

```json
{
  "kind": 1341,
  "pubkey": "<invitee-pubkey-hex>",
  "tags": [
    ["p", "<owner-pubkey-hex>"],
    ["invite", "<invite-code>"]
  ],
  "created_at": <timestamp>,
  "content": {
    "invite_code": "<unique-invite-code>",
    "timestamp": "2025-11-24T10:00:00Z",
    "reason": "Optional reason for denial"
  }
}
```

### Share Confirmation (Kind 1342)

Sent by a steward after successfully receiving and storing their share.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap before publishing.

```json
{
  "kind": 1342,
  "pubkey": "<steward-pubkey-hex>",
  "tags": [
    ["p", "<owner-pubkey-hex>"],
    ["vault", "<vault-id>"],
    ["share", "<share-index>"]
  ],
  "created_at": <timestamp>,
  "content": {
    "vault_id": "<vault-id>",
    "share_index": 0,
    "timestamp": "2025-11-24T10:00:00Z"
  }
}
```

### Share Error (Kind 1343)

Sent by a steward when share processing fails.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap before publishing.

```json
{
  "kind": 1343,
  "pubkey": "<steward-pubkey-hex>",
  "tags": [
    ["p", "<owner-pubkey-hex>"],
    ["vault", "<vault-id>"],
    ["share", "<share-index>"]
  ],
  "created_at": <timestamp>,
  "content": {
    "vault_id": "<vault-id>",
    "share_index": 0,
    "error": "Failed to decrypt share",
    "timestamp": "2025-11-24T10:00:00Z"
  }
}
```

### Invitation Invalid (Kind 1344)

Sent by the vault owner to notify an invitee that their invitation code is invalid or already used.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap before publishing.

```json
{
  "kind": 1344,
  "pubkey": "<owner-pubkey-hex>",
  "tags": [
    ["p", "<invitee-pubkey-hex>"],
    ["invite", "<invite-code>"]
  ],
  "created_at": <timestamp>,
  "content": {
    "invite_code": "<invite-code>",
    "reason": "Code already used"
  }
}
```

### Key Holder Removed (Kind 721)

Sent by the vault owner to notify a steward when they are removed from the backup configuration.

Following the canonical format, all data is placed in tags and content is empty.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap before publishing.

```json
{
  "kind": 721,
  "pubkey": "<owner-pubkey-hex>",
  "tags": [
    ["p", "<removed-steward-pubkey-hex>"],
    ["vault_id", "<vault-id>"],
    ["reason", "<reason>"]
  ],
  "created_at": <timestamp>,
  "content": ""
}
```

The `reason` tag distinguishes the cause of the removal:
- `steward_removed`: The owner removed this steward from the vault's backup configuration
- `vault_deleted`: The owner deleted the entire vault

### Recovery Request (Kind 1338)

Sent by any steward to initiate recovery of a vault.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap before publishing.

```json
{
  "kind": 1338,
  "pubkey": "<initiator-pubkey-hex>",
  "tags": [
    ["p", "<steward-pubkey-hex>"],
    ["vault", "<vault-id>"]
  ],
  "created_at": <timestamp>,
  "content": {
    "vault_id": "<vault-id>",
    "vault_name": "My Secret Vault",
    "initiator_pubkey": "<initiator-pubkey-hex>",
    "initiator_name": "Alice",
    "threshold": 3,
    "timestamp": "2025-11-24T10:00:00Z"
  }
}
```

### Recovery Response (Kind 1339)

Sent by a steward in response to a recovery request.

**Note:** This event MUST be wrapped in a NIP-59 gift wrap before publishing.

```json
{
  "kind": 1339,
  "pubkey": "<steward-pubkey-hex>",
  "tags": [
    ["p", "<initiator-pubkey-hex>"],
    ["vault", "<vault-id>"],
    ["e", "<recovery-request-event-id>"]
  ],
  "created_at": <timestamp>,
  "content": {
    // If approved:
    "vault_id": "<vault-id>",
    "approved": true,
    "share_data": {
      "share": "<base64-encoded-share-bytes>",
      "threshold": 3,
      "share_index": 0,
      "total_shares": 5,
      "scheme": "gf256_v1",
      "creator_pubkey": "<creator-pubkey-hex>",
      "created_at": <unix-timestamp>
    },
    "timestamp": "2025-11-24T10:30:00Z"
    
    // OR if denied:
    // "vault_id": "<vault-id>",
    // "approved": false,
    // "reason": "Unable to verify request authenticity",
    // "timestamp": "2025-11-24T10:30:00Z"
  }
}
```

## Threat Model

**What this protocol protects against**:
- Single point of failure (no single steward can access the secret)
- Centralized service compromise (fully decentralized)
- Relay censorship (use multiple relays)
- Steward unavailability (redundancy through n > t)

**What this protocol does NOT protect against**:
- Collusion of ≥ t stewards
- Compromise of the vault owner's device before distribution
- Social engineering attacks on stewards during recovery
- Malicious stewards providing false recovery responses