# Refactor Data Layer (epic horcrux_app-hvc)

## TL;DR

Replace SharedPreferences with a SQLCipher‑encrypted SQLite database (drift) and reshape the on‑device data model around the "owner is the hub, Nostr is the durable event log, on‑device storage is a cache" mental model. Cache is normalized; the Nostr wire format stays denormalized. Owner devices never persist Shamir share material destined for other stewards; recovery initiators persist response fragments only for the lifetime of an active recovery session, then delete them. Ships in eight phases of one PR each (Phase 0 → 7), with no on‑device data migration because the app is not yet deployed.

## Non‑goals (explicitly out of scope for this epic)

- **Multi‑device concurrent edit policy** for the same vault. Today is last‑write‑wins on Nostr `created_at`. Tracked as a follow‑up.
- **Nostr private‑key rotation.** v1 assumes the key is stable for the lifetime of the DB. Rotation orphans the DB; documented as a known limitation.
- **Cross‑version recovery reconciliation UX.** Manage‑recovery warnings, steward‑side serving of an older version when requested, and "wrong version → mark steward as error" toast logic. Schema lays groundwork (snapshot fields on `recovery_requests`, version on `held_shares`); UX/logic is deferred.
- **Initiator → owner promotion.** Once recovery completes, the initiator's device sees the content and stops there. Becoming the owner of a recovered vault is a separate, explicit user flow handled in another epic.
- **Stalled‑outbox cleanup policy.** "All relays fail forever → drop and restart distribution at a fresh version" — actor (manual button vs. auto after T time), retry budget, and version‑rollback semantics are deferred. The schema accommodates whichever policy we pick.
- **Per‑item `kind` filtering, attachments, conflict resolution between owner devices** — out of scope.

(Tracking beads filed in the Risks section below.)

## Framing

The app is **not yet deployed**, so there is no SharedPreferences data to migrate. We can land schema changes freely, with no compatibility shims for prior on-device shapes.

The Nostr layer is the **durable event log**. On-device storage — both today's SharedPreferences and the new drift database — is a **cache** of a projection of those events. Any on-device row should be reproducible from a replay of the events we've ingested. This framing is the correctness check we use whenever a schema decision is unclear: if rebuilding from a relay replay would fail or diverge, the schema is wrong.

This refactor does two things at once because they're inseparable:

1. **Engine swap**: SharedPreferences → drift + SQLCipher (transactions, schema versioning, reactive `watch()`, in-memory test DB).
2. **Domain reshape**: take the one-time chance to redesign the on-device model from first principles, around the owner-as-hub / Nostr-as-event-log mental model.

## Stack

- **drift** (sqlite + codegen + reactive `watch()`).
- **sqlcipher_flutter_libs** for whole-DB encryption.
- **DB key**: HKDF‑SHA‑256 from the Nostr private key already held in `FlutterSecureStorage` (single trust root, no new secret).
  - **Salt**: random 32 bytes, generated on first launch, persisted to `FlutterSecureStorage` under key `db_key_salt`. Lost salt = lost DB.
  - **Info string**: `"horcrux/db-key/v1"` — versioned so a future re‑derivation is unambiguous.
  - **Output**: 32 bytes, passed to SQLCipher as a raw key (`PRAGMA key = "x'…'"`), not as a passphrase (skips SQLCipher's KDF, which would be redundant on top of HKDF). The outer double‑quote wrapper is **required** — bare blob literals (`x'…'`) are not valid pragma‑values in SQLite's grammar and cause a syntax error at DB open time. See https://www.zetetic.net/sqlcipher/sqlcipher-api/ for the canonical format reference.
  - **Key‑material sanitization**: the `PRAGMA key` execution is wrapped in a try/catch that re‑throws failures as a `StateError` with the original error type but **not** the original message, because the raw error contains the full SQL statement with the key embedded and would leak key material into crash reporters and logs.
  - **Key lifetime**: held in process memory after the first decrypt; cleared on logout, on `wipeLocalDataForCorruptedSecureStorage`, and on app termination. We do **not** clear on app background in v1 (would force re‑derive on every foreground); revisit if threat model demands.
  - **Key rotation is not supported in v1.** If the Nostr private key changes, the DB becomes orphaned ciphertext. Documented as a known limitation; owner data loss is the failure mode.
- **SQLCipher v1 pragmas (pinned)**: `cipher_page_size=4096`, `cipher_kdf_algorithm=PBKDF2_HMAC_SHA512` (irrelevant when raw key is used, but pinned in case derivation strategy ever changes), `cipher_use_hmac=ON` (default), `cipher_memory_security=ON` on platforms that support mlock, **`PRAGMA secure_delete=ON`** (zero pages on delete so deleted share material is not recoverable from compacted pages under future key compromise). After every transaction that deletes share material (`recovery_responses` cleanup), run `PRAGMA wal_checkpoint(TRUNCATE)` to flush the WAL — otherwise fragments live in `-wal` until the next natural checkpoint.
- **NIP-44 retained only for `vaults.content`** (because that same ciphertext is also the on-wire payload the user replicates to their own Nostr profile — one ciphertext, two stores, identical threat model).
- **Application‑layer plaintext columns (SQLCipher‑only)**: `held_shares.share_payload` and `recovery_responses.share_payload` are stored as Shamir‑share plaintext at the application layer; they are protected only by SQLCipher whole‑DB encryption. This is a deliberate non‑change from today and the threat model is: an attacker who extracts the SQLCipher key (e.g., via Secure Storage compromise on a rooted/jailbroken device) sees all share material this device holds. Acceptable because (a) those shares are useless without quorum, and (b) `vaults.content` (the recoverable secret) is doubly encrypted (NIP‑44 + SQLCipher).
- **Owner side: share material destined for *other stewards* never touches disk during distribution** (in‑memory generation; outbox carries already‑encrypted gift‑wraps). **Carve‑out**: the owner is also a steward of their own vault and holds one share themselves; that share *is* persisted in `held_shares` like any steward's. The invariant we test is "no plaintext share material exists on the owner's disk that was destined for a *different* steward."
- **Initiator side during recovery: share fragments persist in `recovery_responses.share_payload`** for the lifetime of an active recovery session, then are deleted on session end. Different rule, different threat model — see "Share material lifecycle" below.

## Share material lifecycle

The owner side and the initiator-during-recovery side have different threat models and different rules. The asymmetry is deliberate.

### Why the asymmetry

| | Owner: distribution | Initiator: recovery |
|---|---|---|
| Source of share material | `vaults.content` (local, regeneratable) | Stewards' gift-wraps (remote, not regeneratable on demand) |
| Session length | Seconds to minutes | Hours to days, possibly longer |
| Need to access fragments after session start | No (publish once and forget) | Yes (every "view content" tap, across app restarts) |
| Cost of relay re-fetch | N/A | Slow, fragile, depends on relay retention policies |
| **On-disk policy** | **In-memory only** | **Persist for active session, delete on end** |

Relays are transport, not durable storage; designing recovery to depend on relay retention is fragile. During an active recovery, the user expects "tap to view content" to work across app restarts and connectivity changes without round-tripping to relays.

### Owner-side distribution (in-memory only)

1. In memory: read `vaults.content`, generate N Shamir shares.
2. In memory: for each steward, build the NIP-59 gift-wrap event (encrypted to the recipient's pubkey — opaque to the owner from this point).
3. In one transaction: insert the `distributions` row, insert N `distribution_shares` rows (tracking metadata only; `gift_wrap_event_id` is **captured in memory at gift‑wrap construction time and stored before commit** — it is not later‑reproducible from `(recipient, share_index, distribution_version)` because the NIP‑59 wrap is signed by an ephemeral key with randomized `created_at` jitter), insert N `outbox` rows whose `event_json` is the already‑encrypted gift‑wrap. Commit.
4. In-memory shares go out of scope; the GC reclaims them.
5. The outbox worker drains gift-wrap rows, publishes to relays, sets `distribution_shares.sent_at` on success.

Failure modes:
- **Single relay flake** → outbox retries.
- **Crash before commit** → rollback; shares were never persisted; nothing on disk.
- **Crash after commit** → outbox holds encrypted-to-recipient gift-wraps; publishing resumes on next launch. The owner's device cannot decrypt them.
- **All relays fail forever** → outbox rows stay queued, useless ciphertext on the owner's device. The drop‑and‑restart‑at‑a‑fresh‑version policy is **out of scope for this epic** (see Non‑goals and Risk #5); the schema accommodates it but the actor (manual button vs. auto after T time), retry budget, and version‑rollback semantics are deferred.

### Initiator-side recovery (persist for active session)

We commit to **session‑bound view** (originally drafted as "Option A — one‑shot view," renamed for accuracy): after recovery succeeds, content is shown to the user but never written to `vaults.content` on the initiator's device. The user can re‑view as many times as they like *during the session*; closing a single view does not end the session. The device does not become an owner of this vault. Taking ownership is a separate, explicit user‑driven step (out of scope for this epic).

1. Initiate: insert `recovery_requests` row; publish recovery request via outbox.
2. Each response gift‑wrap arrives: unwrap once in memory, store the fragment in `recovery_responses.share_payload`. SQLCipher protects at rest.
3. View: combine the persisted fragments in memory on demand, display content, discard plaintext when the view closes. **Plaintext content is never written to disk** on the initiator's device.
4. Session ends — any of:
   - User explicitly ends the recovery.
   - User cancels (`recovery_requests.cancelled_at` set).
   - `recovery_requests.expires_at` passes; both a **startup sweep** *and* a **periodic in‑app sweep** (every 5 minutes while the app is foregrounded) detect this and clean up. Without the periodic sweep, a long‑running foreground session would never expire.
   - User deletes the underlying held share or vault (cascade — see "Cascading deletes" below).

   → in a single transaction: delete the `recovery_responses` rows for that request, then run `PRAGMA wal_checkpoint(TRUNCATE)` to flush share material from the WAL. The contract: **no share material survives session end**.
5. **Crash mid‑recovery** → fragments are durably on disk; on restart, the recovery is resumable instantly without relay re‑fetch.
6. **Crash after the user finished viewing but before they tapped "end"** → fragments live on until expiration or the next manual action. Acceptable because (a) the device is still trusted, (b) `expires_at` provides a hard upper bound, and (c) we don't have a way to atomically observe "user has finished with this content."

### Steward side

`held_shares.share_payload` is **durable** on the steward's device — that's the steward's job. The protocol-level "please delete your share" instruction (sent when the owner removes a steward or the steward voluntarily leaves) tells the steward's app to delete the row.

### Cascading deletes

Full FK action matrix lives in "ON DELETE actions (v1)" under Target schema. Summary:

- Deleting a `vaults` row cascades to `owned_vaults`, `vault_relays`, `stewards` (history and all), `held_shares`, `distributions` (and through them `distribution_shares`), `recovery_requests` (and through them `recovery_responses`, **clearing share material**), and pending `outbox` rows for that vault.
- Deleting a `recovery_requests` row cascades to its `recovery_responses` (including `share_payload`); paired with `wal_checkpoint(TRUNCATE)` in the same transaction.
- Deleting a `held_shares` row deletes the steward's stored share material for that share version.
- `stewards` rows are **never deleted directly**, only soft‑retired via `left_at`; `distribution_shares` references are RESTRICTed to enforce that invariant.

## Architectural seams (preserve these)

- Riverpod providers stay 1:1 with today.
- Services keep their public APIs; their bodies switch from prefs to DAOs (Data Access Objects — drift-generated classes that translate between Dart objects and SQL).
- Repositories own transactions ("accept invitation = update invitation row + insert steward row + bump distribution version, atomically").
- Test infrastructure: replace [test/helpers/shared_preferences_mock.dart](../test/helpers/shared_preferences_mock.dart) usage with `NativeDatabase.memory()` factories.

## DBA review of current models (motivation for the reshape)

- **`Vault` is a god object.** Conflates user record, role-specific shares (`shards: List<ShardData>` means outgoing distribution on owner devices and the one held share on steward devices — same field, different semantics), recovery state, and backup config. Nullable `content` expresses "steward view" by absence instead of by type.
- **`BackupConfig` overcounts and over-times.** `totalKeys` duplicates `stewards.length`. `lastUpdated`/`lastContentChange`/`lastRedistribution` are derived from an event stream we already have on Nostr. `specVersion: '1.0.0'` is decoration. `relays` overlaps with the global relay list with unclear semantics.
- **`Steward` doesn't model replacement.** Today there's no `left_at` / `removal_reason`, so when a steward leaves and is replaced, the only options are mutate-in-place (loses history) or hand-roll a parallel record. The fix is an append-on-replace history pattern on `stewards`. Acknowledgment fields (`giftWrapEventId`, `acknowledgedAt`, `acknowledgedDistributionVersion`) belong on the distribution event, not on the steward.
- **Cache should be normalized; wire stays denormalized.** The fat share event is the right protocol choice. But persisting that fat snapshot as JSON on `held_shares` made the steward's view of "fellow stewards" a second source of truth and forced UI code to switch on role. Normalizing into shared `vaults` + `stewards` lets both roles render the same query.
- **`ShardData` does two jobs.** Cryptographic share (Shamir params) AND wire message (vault metadata, peer steward snapshot, delivery state). On-wire denormalization is justified; on-disk denormalization is not.
- **`RecoveryRequest.stewardResponses`** holds nested `ShardData` per response, putting share material in three places (request map, recovery cache, held-share row).

The wire protocol's "fat share event with everything the steward needs" is **kept**: it pays off in offline / bootstrap / relay-rotation scenarios. We just stop persisting the denormalized snapshot on disk; we hydrate it from normalized tables at send time.

## Target schema (initial migration v1)

NIP‑44 fields marked `[ciphertext]`. Application‑layer plaintext (SQLCipher‑only) marked `[app‑plaintext]`. All other columns are SQLCipher‑protected at the DB level. ON DELETE actions and indexes are listed after the diagram.

### ER diagram

```mermaid
erDiagram
    vaults ||--o| owned_vaults : "owner-only secret"
    vaults ||--o{ vault_relays : "relays per vault"
    vaults ||--o{ stewards : "has stewards"
    vaults ||--o{ held_shares : "steward-side payload (1+ rows; old kept)"
    vaults ||--o{ distributions : "owner versioning"
    distributions ||--o{ distribution_shares : "ack tracking"
    stewards ||--o{ distribution_shares : "delivered to"
    stewards ||--o| invitations : "may have invite"
    vaults ||--o{ recovery_requests : "may be recovered"
    recovery_requests ||--o{ recovery_responses : "collects"
    stewards ||--o{ recovery_responses : "responds via"

    vaults {
        TEXT id PK
        TEXT name
        TEXT owner_pubkey
        TEXT owner_name
        INT threshold
        TEXT prime_mod
        INT total_shares
        INT current_distribution_version
        TEXT instructions
        BOOL push_enabled
        INT archived_at "local-only soft delete"
        TEXT archived_reason
        INT last_synced_at "steward-side; null on owner"
        INT created_at
    }

    vault_relays {
        TEXT id PK
        TEXT vault_id FK
        TEXT url
        TEXT role "owner|steward — which side this list comes from"
        INT added_at
    }

    owned_vaults {
        TEXT vault_id PK_FK
        TEXT content "NIP-44 [ciphertext]"
        BLOB content_hmac "HMAC-SHA-256(plaintext) keyed under DB key"
        INT created_by_self_at
    }

    stewards {
        TEXT id PK
        TEXT vault_id FK
        INT share_index "1..N position"
        TEXT pubkey "nullable until accepted"
        TEXT name
        TEXT contact_info "shared on the wire; UI hides outside recovery flows"
        BOOL is_owner
        INT joined_at
        INT left_at "null = active"
        TEXT removal_reason
    }

    distributions {
        TEXT id PK
        TEXT vault_id FK
        INT version
        INT created_at
        INT completed_at
        BLOB content_hmac "HMAC-SHA-256(plaintext at time of distribution)"
    }

    distribution_shares {
        TEXT id PK
        TEXT distribution_id FK
        TEXT steward_id FK "row active at distribution time"
        TEXT gift_wrap_event_id "captured at gift-wrap construction time"
        INT sent_at
        INT acknowledged_at
        TEXT acknowledgment_event_id
        INT acknowledgment_distribution_version "version the steward acked; detect stale acks"
        INT acknowledgment_created_at "wire created_at of the ack event"
    }

    invitations {
        TEXT code PK
        TEXT steward_id FK
        TEXT payload
        INT created_at
        INT expires_at
        INT accepted_at
        TEXT accepted_by_pubkey
        INT revoked_at
    }

    held_shares {
        TEXT id PK
        TEXT vault_id FK
        INT share_index
        TEXT share_payload "[app-plaintext] Shamir share"
        INT distribution_version
        INT received_at "local clock"
        TEXT nostr_event_id
        TEXT last_seen_relay "relay this row was first ingested from"
        BOOL push_enabled
    }

    recovery_requests {
        TEXT id PK
        TEXT vault_id FK
        TEXT request_event_id "Nostr event id of the request rumor"
        TEXT initiator_pubkey
        INT started_at "local clock"
        INT expires_at
        INT cancelled_at
        INT completed_at
        INT distribution_version_at_start "snapshot"
        INT threshold_at_start "snapshot"
    }

    recovery_responses {
        TEXT id PK
        TEXT request_id FK
        TEXT steward_id FK "nullable; see notes"
        TEXT responder_pubkey
        TEXT share_payload "[app-plaintext] Shamir fragment; lives until session end"
        INT share_distribution_version "version the steward served"
        INT received_at "local clock"
        TEXT nostr_event_id
        TEXT replying_to_event_id "Nostr id of recovery_requests.request_event_id"
    }

    outbox {
        TEXT id PK
        TEXT vault_id FK "nullable; null for non-vault events"
        INT kind "Nostr event kind"
        TEXT event_id "Nostr event id (for dedup + ack matching)"
        INT created_at
        INT next_attempt_at
        TEXT event_json
        TEXT correlation_id
    }

    outbox_relays {
        TEXT outbox_id PK_FK
        TEXT relay_url PK
        TEXT status "pending|success|failed"
        INT attempts
        INT next_attempt_at
        TEXT last_error
    }

    kv {
        TEXT key PK
        TEXT value
    }

    viewed_notifications {
        TEXT notification_id PK
        INT viewed_at
    }

    synced_consents {
        TEXT consent_id PK
        TEXT payload
        INT synced_at
    }
```

### Indexes (v1)

```
CREATE INDEX stewards_vault_active           ON stewards(vault_id, left_at);
CREATE UNIQUE INDEX stewards_vault_position_active
    ON stewards(vault_id, share_index) WHERE left_at IS NULL;
CREATE INDEX vault_relays_vault              ON vault_relays(vault_id);
CREATE INDEX vault_relays_url                ON vault_relays(url);
CREATE UNIQUE INDEX distributions_vault_version
    ON distributions(vault_id, version);
CREATE INDEX distribution_shares_distribution ON distribution_shares(distribution_id);
CREATE INDEX distribution_shares_steward      ON distribution_shares(steward_id);
CREATE INDEX held_shares_vault                ON held_shares(vault_id);
CREATE INDEX held_shares_vault_version        ON held_shares(vault_id, distribution_version DESC);
CREATE INDEX recovery_responses_request       ON recovery_responses(request_id);
CREATE INDEX outbox_next_attempt              ON outbox(next_attempt_at);
CREATE INDEX outbox_relays_pending            ON outbox_relays(status, next_attempt_at);
CREATE INDEX invitations_steward              ON invitations(steward_id);
```

### ON DELETE actions (v1)

| Parent → child | Action | Rationale |
|---|---|---|
| `vaults` → `owned_vaults` | CASCADE | owner row is meaningless without the vault |
| `vaults` → `vault_relays` | CASCADE | relays are vault metadata |
| `vaults` → `stewards` | CASCADE | steward rows (and history) belong to the vault |
| `vaults` → `held_shares` | CASCADE | held shares are steward‑side payload for this vault |
| `vaults` → `distributions` | CASCADE | distribution history dies with the vault |
| `vaults` → `recovery_requests` | CASCADE | in‑flight recoveries die with the vault (clears share material) |
| `vaults` → `outbox` | CASCADE | pending publishes for a deleted vault are obsolete |
| `distributions` → `distribution_shares` | CASCADE | tracking rows have no meaning without their distribution |
| `stewards` → `invitations` | CASCADE | an invitation is bound to a steward slot |
| `stewards` → `distribution_shares` | RESTRICT | distribution_shares retain a pointer to the historical steward row; we never delete steward rows, only set `left_at` |
| `stewards` → `recovery_responses` | SET NULL | response from a steward who later left is preserved by pubkey; FK becomes null |
| `recovery_requests` → `recovery_responses` | CASCADE | end of session = delete responses (see Share material lifecycle) |
| `outbox` → `outbox_relays` | CASCADE | per‑relay state has no meaning without the parent event |

### Shared cache normalization (cache normalized, wire denormalized)

The wire stays as it is today — fat share events that include everything a steward needs. The on-disk **cache is normalized**: both owners and stewards read from a shared `vaults` + `stewards` core; role-specific extras live in role-specific tables (`owned_vaults` for owners, `held_shares` for stewards). Stewards write their cache rows from received share events; owners write theirs from authoring. The denormalization stays exactly where it belongs — at the protocol boundary, not in the database.

This means there is **no `peer_steward_snapshot JSON`** column anywhere. Both roles render the "fellow stewards" UI by querying `stewards WHERE vault_id = ?` directly.

### Stewards as a single history-bearing table

One table, append-on-replace. The cryptographic position is the `share_index` column.

- **Replacement = append**. To replace the steward at share_index 3: set `left_at` on the current row, insert a new row with the same `vault_id` and `share_index` and the new pubkey/name/etc.
- **Partial unique index**: `(vault_id, share_index) WHERE left_at IS NULL` enforces "exactly one active steward per position".
- **Plan structure query**: `SELECT share_index, pubkey, name FROM stewards WHERE vault_id=? AND left_at IS NULL ORDER BY share_index`.
- **History query**: `SELECT * FROM stewards WHERE vault_id=? AND share_index=3 ORDER BY joined_at`.
- **`distribution_shares.steward_id`** points to the row active at distribution time. Historical rows are preserved (with `left_at` set), giving an audit trail.
- **`pubkey` is nullable** for the legitimate state where the owner has named a steward but the invitee hasn't accepted yet.
- We deliberately do not split position and holder into two tables: they are created in the same transaction; any change forces a redistribution anyway; the position's only durable attribute is the integer `share_index`, which is a column, not a row.

### Cross-role write precedence (the one subtlety)

Both roles can upsert to `vaults` and `stewards`. To avoid a stale ingestion overwriting authoritative state, the rules are:

1. **If `owned_vaults.vault_id` exists for this vault, the owner is authoritative.** Ingestion of a share event for an owned vault writes only `held_shares` (so the owner's own owner-share is recorded as a steward role) and never touches `vaults` / `stewards`.
2. **For non-owned vaults (pure-steward case), ingestion is gated by `distribution_version`.** Upsert `vaults` and reconcile `stewards` only if the incoming event's version is `>= vaults.current_distribution_version`.
3. **Stewards reconciliation = append-on-replace**, same as on the owner side. Stewards no longer in the new snapshot get `left_at` set; new ones are inserted; matching ones are updated in place. A pure-steward device accumulates a small history they rarely look at — acceptable.

These rules are enforced in a transactional helper inside the ingestion path, not in the schema.

### Contact info, UI privacy gating

`stewards.contact_info` is **shared, populated on both owner and steward devices**. Today's wire format already carries it as an optional field on each peer in the share event, and we keep that.

Privacy is enforced at the UI, not at storage:
- **Normal vault detail viewing**: contact info is hidden from steward views (and arguably also from owner views unless they tap "show contacts").
- **During an active recovery for the vault** (a `recovery_requests` row exists with `cancelled_at IS NULL` and `expires_at > now`): contact info is revealed to all participating stewards so they can reach each other out-of-band ("haven't heard from Carol; let me email her about her share").
- The owner can choose what contact info to include for each steward; what's not entered is not synced.

### Push notification flags (interaction across roles)

Two columns control push: `vaults.push_enabled` (owner‑authored metadata that gates whether *anyone* gets push for this vault) and `held_shares.push_enabled` (per‑share preference on the steward's device). The combined rule:

- **Owner side**: `vaults.push_enabled = false` suppresses all push send paths for this vault, regardless of any steward's local opt‑in.
- **Steward side**: `held_shares.push_enabled = false` suppresses local push reception for this share even if the owner has push enabled.
- Either column being false is sufficient to suppress; both must be true (along with the global per‑user opt‑in in `kv`) to fire a notification. Documented at the receive/send sites; not enforced by a DB constraint because the two columns are owned by different roles.

### Owner-only extension tables

- `owned_vaults` — `vault_id` PK/FK to `vaults`. Holds `content [NIP‑44 ciphertext]`, `content_hmac` (HMAC‑SHA‑256 of plaintext, keyed under the DB key), `created_by_self_at`. This row's existence is the marker "I am the owner of this vault." We use HMAC rather than plain SHA so that an attacker with DB‑only access cannot use the hash as a confirmation oracle for guessed plaintext (low‑entropy content like seed phrases would otherwise be confirmable offline).
- `distributions` — one row per redistribution event. UNIQUE(vault_id, version). Carries `content_hmac` snapshot at distribution time so an ack referencing an old distribution can be matched even after content has changed.
- `distribution_shares` — one row per (distribution × steward). Tracks send + acknowledgment, including the ack's `distribution_version` (so we can detect "ack for old version" and the wire `created_at` of the ack (kept for audit; never used for "freshness" decisions — see "Time, monotonicity, clock skew" below). **No `share_payload` column** — owner never persists share material destined for other stewards.
- `invitations` — bound to a specific `stewards` row. State derived from timestamps; no `status` enum.

### Steward-side extension table

- `held_shares` — `vault_id` FK to shared `vaults`. Holds share material and steward‑side delivery state (`share_payload`, `share_index`, `distribution_version`, `received_at`, `nostr_event_id`, `last_seen_relay`, `push_enabled`). All metadata it used to carry now lives in `vaults` and `stewards`.
- **Multi‑version retention is intentional**: there is **no `UNIQUE(vault_id)` constraint on `held_shares`**. Policy is to keep a small bounded number of recent share versions per vault (see "Held‑share retention" below) so we can serve a recovery request that asks for an older `distribution_version` — important when one steward never received the newest share. Dedup against duplicate ingestion of the *same* share happens via `UNIQUE(vault_id, distribution_version, nostr_event_id)` (added in v1; not shown above in the diagram for readability).
- The owner's own self‑share lives here too on the owner's device. See the "Owner‑as‑self‑steward carve‑out" in the Stack section.

### Held‑share retention policy

- Keep the **N most recent** versions per vault, where N is small (default 3, configurable via `kv`).
- When a new share for `vault_id` arrives at a higher `distribution_version`, prune any rows beyond the retention window in the same transaction.
- Pruned rows release SQLCipher pages; pair with the post‑transaction `wal_checkpoint(TRUNCATE)` only when share material is actually deleted (not on every prune — pruning is steward‑side, lower urgency than recovery cleanup; checkpoint at next opportunity).

### Tables both roles use

- `recovery_requests`, `recovery_responses` — both roles legitimately observe these. Owner sees recoveries‑in‑flight for their vaults; steward sees requests they should respond to (and ones they initiated).
- **Recovery scope (v1)**: `recovery_requests.vault_id` is FK to `vaults.id` with no nullability and no synthesis path. **A recovery can only be initiated for a vault that already has local rows** — i.e., a vault the device has previously been a steward of, or has previously seen via a discovery scan that populated `vaults`. The "lost device, no local state, restore from scratch" flow is **out of scope for v1** and tracked as a follow‑up; today it requires a discovery step that lands a `vaults` placeholder before recovery can start.

### Cross-cutting tables

- `outbox` + `outbox_relays` — transactional outbox split across two tables: the parent row holds the event JSON and metadata (kind, vault_id for cascade and targeting, deterministic event_id for dedup, correlation_id), and the per‑relay child rows hold per‑relay status and retry state. State changes and the events they produce are written in one transaction; a worker drains pending `outbox_relays` rows and publishes. Replaces `publish_queue_items_v2`.
- `kv` — **genuine singletons only**: `first_open_utc_ms`, `notifier_base_url`, `fcm_device_token`, `fcm_device_token_updated_at`, `push_notifications_opted_in`, `scanning_status`, `held_share_retention_n`. Anything plural moves out of `kv` to its own table:
  - `viewed_notifications(notification_id PK, viewed_at)` — replaces `viewed_recovery_notification_ids`. Set semantics, no JSON read‑mutate‑write race.
  - `synced_consents(consent_id PK, payload, synced_at)` — replaces `last_synced_consents`. Was a collection masquerading as a singleton.
  - Future plurals follow the same rule.

### Relay handling (no global table)

We do not store a global list of relays. Relays are per‑vault, normalized into `vault_relays(vault_id, url, role)` so that "find vaults using relay X" is a normal indexed query (needed for the manual relay‑redirect flow). Two UI flows handle the cases that previously implied a global table:

- **First‑login broad scan** — handled by the existing first‑login work; user supplies a starter relay set or accepts defaults to scan, then any vaults found populate the per‑vault relay rows. No global storage needed.
- **Manual relay redirect** — user can ask the app to scan a specific relay (e.g., owner switched relays wholesale) and merge any discovered vaults into local state. Implemented as `SELECT vault_id FROM vault_relays WHERE url = ?` plus an ingestion pass.

`held_shares.last_seen_relay` records the relay a given share was ingested from, so the steward can publish their ack to a sensible relay set without re‑guessing.

### Time, monotonicity, clock skew

Many decisions can be tempted to use `created_at` from Nostr events. Don't. Wire `created_at` is attacker‑controlled; a malicious or buggy steward can post events dated 2099. **Convention**:

- **Local‑clock columns** (`received_at`, `started_at`, `sent_at`, `acknowledged_at`, etc.) are the source of truth for UI freshness, sweeps, and ordering decisions.
- **Wire `created_at` is captured for audit only** (e.g., `acknowledgment_created_at`) and never used to derive UI state or cleanup triggers.
- Any new column derived from event timestamps should be named `*_received_at` or `*_local_at` to make this explicit.

### Event dedup

Schema‑level dedup covers events that produce a row:

- `held_shares` UNIQUE(vault_id, distribution_version, nostr_event_id).
- `recovery_responses` UNIQUE(request_id, nostr_event_id).
- `distribution_shares` UNIQUE on `acknowledgment_event_id` (sparse — only meaningful once acked).
- `outbox` UNIQUE on `event_id` (so a crash‑and‑retry of "publish my acceptance" doesn't double‑publish).

Events that don't produce a row (steward leave‑messages, control events, stale acks for already‑pruned distributions) need a separate processed‑events table to avoid reprocessing. **Decision deferred**: today's `processed_nostr_event_store.dart` fills this role and continues to in v1; moving it into the SQLCipher DB is the right long‑term answer but is tracked as a follow‑up bead so we don't blow up Phase 3's scope.

### What we deliberately don't build

- No `BackupStatus` / `StewardStatus` enum columns. State is derived from timestamps on event‑shaped rows (using **local** timestamps — see "Time, monotonicity, clock skew").
- No `lastUpdated` / `lastRedistribution` / `lastContentChange` on `vaults`. Use `MAX(*_at)` queries on `distributions` / `stewards` / etc., always against local‑clock columns.
- No on‑disk `peer_steward_snapshot JSON` on `held_shares`. Stewards normalize the snapshot into shared `vaults` and `stewards` rows on receive.
- No on‑disk peer‑steward list on outgoing share events. Hydrated from active `stewards` at send time.
- No `totalKeys` field separate from `COUNT(stewards WHERE vault_id=? AND left_at IS NULL)`.
- No separate `steward_positions` table — position is the `share_index` column.
- No `recovery_plans` table — fields merged into `vaults`. The "future multi‑plan" indirection was speculative.
- No global `relays` table. (Per‑vault relays live in `vault_relays`.)
- No `share_payload` column on `distribution_shares` — owner never persists share material destined for other stewards.
- No `UNIQUE(vault_id)` on `held_shares` — multi‑version retention is intentional (see "Held‑share retention policy").
- No JSON columns for plural data in `kv` — plurals get their own tables.

## Wire-format compatibility (deliberate)

- Nostr event JSON keys (`shard_index`, `total_shares`, etc. in [lib/models/shard_data.dart](../lib/models/shard_data.dart) ~line 264) **stay as `shard_*`** to keep the protocol stable. The rename is internal (Dart class names, file names, method names, UI copy). Document at each `toJson`/`fromJson` boundary.
- The outgoing share event continues to carry the full peer steward snapshot needed by stewards. We just compute it freshly from active `stewards` rather than reading it from a stored copy.

## Phased implementation (each phase is one PR unless noted)

### Phase 0 — Scaffolding (no behavior change)
- Add deps to [pubspec.yaml](../pubspec.yaml): `drift`, `drift_dev` (dev), `sqlite3_flutter_libs`, `sqlcipher_flutter_libs`.
- New folder `lib/database/` with `app_database.dart`, `tables/`, `daos/`.
- DB key derivation helper (HKDF from `LoginService` private key, salt in `FlutterSecureStorage`).
- `appDatabaseProvider` Riverpod provider with `NativeDatabase.memory()` test factory.
- **Test fixture infrastructure** (lands here, not in Phase 7): two in‑memory factories in `test/helpers/test_database.dart`:
  - `newTestDatabase()` — plain `NativeDatabase.memory()` for pure Dart unit tests. No SQLCipher.
  - `newWidgetTestDatabase()` — wraps `NativeDatabase.memory()` in a `DatabaseConnection` with `closeStreamsSynchronously: true` (the pattern Drift docs recommend) so query‑stream teardown completes synchronously and does not leave pending timers after a widget test disposes its tree. Use this in all widget / golden tests via `appDatabaseProvider.overrideWithValue(newWidgetTestDatabase())`.
  - Typed fixture builders: `VaultFixture.owned(...)`, `VaultFixture.stewarded(...)`, `RecoverySessionFixture.inProgress(...)` (the last one throws `UnimplementedError` until Phase 3 when the recovery tables land). Every Phase 1+ PR uses these instead of bespoke setup.
  - `FixedClock` helper (deterministic millisecond clock with an `advance(Duration)` method) so fixture ordering assertions don't depend on `DateTime.now()`.
- **Golden test override helper** in `test/helpers/golden_test_helpers.dart`: `goldenOverrides(List<Override>)` prepends the in‑memory DB override and the empty‑recovery‑request‑stream override before any test‑specific overrides. This prevents golden tests from touching platform channels (storage or secure‑key access). Note: golden tests also still import `SharedPreferencesMock` during Phases 1–6 for the services not yet migrated to drift; `shared_preferences_mock.dart` and all its call sites are deleted in Phase 7.
- **Schema‑evolution CI**: commit `drift_schemas/v1.json` from `drift_dev schema dump`; CI assertion that any schema change without a corresponding version bump + migration test fails the build. Cheap to add now, expensive to retrofit at v3.
- No consumers wired yet; existing code still uses prefs.

### Phase 1 — Shared schema and `VaultRepository` swap
- Tables: `vaults`, `vault_relays`, `owned_vaults`, `stewards`, `distributions`, `distribution_shares`.
- DAOs for each.
- `VaultRepository` rewritten on top of these DAOs; `vaultsStream` becomes `_vaultDao.watchAll()`.
- Promote `BackupConfig` from record typedef to a `@freezed` domain class hydrated from `vaults` + `owned_vaults` + active `stewards` (filtered `WHERE left_at IS NULL`). Dropped fields (`specVersion`, `totalKeys`, `lastUpdated`, `lastContentChange`, `lastRedistribution`, `contentHash`, `status`) are either derivable or decoration; `totalKeys` becomes a derived getter (`stewards.length`), `hasBeenDistributed` replaces `lastRedistribution != null` checks.
- **`Vault.isArchived` becomes a derived getter** (`archivedAt != null`), not a stored field. Consistent with the "derive from timestamps, not redundant booleans" rule; removes the previous `@Default(false) bool isArchived` Freezed field.
- **`Vault.toJson` / `Vault.fromJson` removed**: the vault is now persisted via DAOs, not JSON blobs. Any code that called these methods (primarily `VaultRepository`) is rewritten to use DAOs directly.
- Update [lib/services/invitation_service.dart](../lib/services/invitation_service.dart), [lib/widgets/steward_list.dart](../lib/widgets/steward_list.dart), [lib/screens/backup_config_screen.dart](../lib/screens/backup_config_screen.dart) to read active stewards.
- **No data migration**: legacy prefs keys are removed from code, not migrated.

### Phase 1.5 — Shard → Share rename (internal)

Moved earlier than originally planned so Phases 2 and 3 don't have to review behavior changes against a backdrop of name churn.

- Rename `ShardData`→`Share`, `ShardEvent`→`ShareEvent`, [lib/services/shard_distribution_service.dart](../lib/services/shard_distribution_service.dart) → `share_distribution_service.dart`, methods like `addShardToVault`→`addShareToVault`, etc.
- **Keep Nostr JSON keys as `shard_*`** at the wire boundary; comment the decision at each toJson/fromJson site.
- Regenerate goldens for any UI strings that surface "Shard" → "Share".
- Pure rename PR; no schema or behavior changes.

### Phase 2 — Steward-side data layer (split into 4 PRs)

Phase 2 was originally a single PR mixing schema, ingestion rewrite, model surgery, and UI restructure. That's three or four PRs in a trench coat. Split into independently revertable steps:

#### Phase 2a — `held_shares` table + ingestion writes
- Add `held_shares` table and DAO.
- Rewrite [lib/services/vault_share_service.dart](../lib/services/vault_share_service.dart) ingestion: a received share event upserts `vaults` and reconciles `stewards` (subject to the precedence rules — owner‑self vaults skip, version‑gated otherwise), and writes a `held_shares` row for the share material itself.
- Implement held‑share retention pruning (keep most‑recent N versions per vault).
- **Back‑compat shim**: `Vault.shards` is still populated for UI by reading `held_shares` at hydration time. Synthetic `Vault` for steward view continues to exist.

#### Phase 2b — Sealed `VaultDetail` read model
- Introduce sealed `VaultDetail { OwnedVaultDetail, StewardedVaultDetail }` exposing a shared core (name, owner identity, threshold, fellow stewards) plus role‑typed extras.
- `OwnedVaultDetail` carries an optional `selfHeldShare` (composes the held_shares row when the owner is also their own steward — the carve‑out from "Stack").
- New `VaultDetailRepository` exposes `vaultDetailStream(id)` and `vaultListStream()`. UI reads through these; legacy `Vault` still works.

#### Phase 2c — Drop `Vault.shards` and nullable `Vault.content`
- Owner‑side share creation/distribution moves to writing `distribution_shares` rows (tracking only — see Phase 3 for the full owner distribution flow).
- Remove `Vault.shards` field; remove nullable `Vault.content`.
- Delete back‑compat shims from 2a/2b.

#### Phase 2d — Contact‑info UI gating
- Render `stewards.contact_info` only when an active `recovery_requests` row exists for the vault. Pure UI PR.

### Phase 3 — Event-shaped flows
- `invitations`, `recovery_requests`, `recovery_responses`, `outbox`, `outbox_relays` tables.
- Rewrite [lib/services/invitation_service.dart](../lib/services/invitation_service.dart) acceptance flow as a single transaction: update the `stewards` row (set `pubkey`, `joined_at`), update `invitations.accepted_at`, append outbox event for the accept publish, all atomically.
- Rewrite [lib/services/recovery_service.dart](../lib/services/recovery_service.dart) for the asymmetric lifecycle: each incoming response gift‑wrap is unwrapped once and stored as a `recovery_responses` row with `share_payload` set; viewing the recovered content combines fragments in memory on demand and never writes plaintext to disk; session‑end (cancel / explicit end / expiration / vault deletion) deletes the `recovery_responses` rows for that request in a transaction, followed by `wal_checkpoint(TRUNCATE)`. Add **both** a startup sweep and a periodic in‑app sweep (every 5 min) that close recoveries past `expires_at`.
- Implement the **owner‑side distribution flow**: in‑memory share generation, in‑memory gift‑wrap construction, single‑transaction insert of `distributions` + `distribution_shares` (tracking metadata, including the `gift_wrap_event_id` captured at construction time) + `outbox` + `outbox_relays` rows containing the encrypted gift‑wrap event JSON. On successful publish per relay, the outbox worker updates the matching `outbox_relays.status` and, when all relays are in a terminal state, sets `distribution_shares.sent_at`. No share material ever lands on disk on the owner side except in the owner's own `held_shares` row (carve‑out).
- Replace [lib/services/publish_service.dart](../lib/services/publish_service.dart) prefs queue with the `outbox` + `outbox_relays` tables; existing retry/backoff logic stays, now scoped per‑relay so retries only target failing relays.
- Vault deletion cascades per the table at the top of "Target schema."
- Removes the `RecoveryRequest.stewardResponses` map and the `ShardData.stewards` denormalization in the same PR (they have no on‑disk home anymore).
- **Rewrite `needsRedistribution`**: the current `BackupConfigExtension.needsRedistribution` checks `Steward.giftWrapEventId == null`, which is only valid for the lifetime of the in‑memory `_backupConfigOverlay` in `VaultRepository` — after an app restart the overlay is empty, `_stewardFromRow` defaults all keyed stewards to `awaitingKey` with `giftWrapEventId == null`, and the getter always returns `true`, showing stale "Keys not distributed" UI for previously‑distributed vaults. Replace it with a DAO query against `distribution_shares WHERE sent_at IS NULL` for the current `distributions.version` (rows exist from the distribution flow above). Remove `Steward.giftWrapEventId` from the `Steward` model — it was a Phase 1 placeholder; `distribution_shares.gift_wrap_event_id` is the canonical, durable store. Update `_stewardFromRow` accordingly (the field no longer exists to default).

### Phase 4 — (was Shard → Share rename; now in Phase 1.5)

Intentionally empty placeholder so existing references to "Phase 5/6/7" downstream don't shift. Future renumber if desired.

### Phase 5 — Remaining services on drift + logout/wipe acceptance
- `RelayScanService` writes to `kv`(`scanning_status`); per‑vault relays already live in `vault_relays` from Phase 1. Manual one‑time relay scan is a UI flow that operates on `vault_relays`, not on a global table.
- Notification + push state → `kv` rows; viewed notifications → `viewed_notifications` table; consents → `synced_consents` table.
- **Logout / wipe is now part of acceptance, not a follow‑up.** [lib/services/logout_service.dart](../lib/services/logout_service.dart)'s `prefs.clear()` becomes "close DB → delete DB file → delete `-wal` and `-shm` siblings → clear `FlutterSecureStorage` (including `db_key_salt`)." Same path for `wipeLocalDataForCorruptedSecureStorage`.
- **Acceptance test for wipe**: write known share material into `held_shares` and `recovery_responses`; trigger logout; assert (a) the DB file does not exist, (b) `-wal` and `-shm` siblings do not exist, (c) `FlutterSecureStorage` returns null for the Nostr private key and the DB key salt. Run on macOS and Linux in CI.

### Phase 6 — Sealed `VaultDetail` polish
- Phase 2b introduces the sealed `VaultDetail { OwnedVaultDetail, StewardedVaultDetail }` read model. Phase 6 finishes the migration: drop `VaultState` enum entirely, ensure all UI sites pattern‑match on the sealed type, audit shared widgets to consume the common interface (name, owner identity, threshold, total_shares, fellow stewards) and route role‑specific behavior (redistribute / respond‑to‑recovery / etc.) through the typed branches.

### Phase 7 — Tests and cleanup
- Add transaction‑coverage tests for: concurrent share arrival on different vaults, invitation acceptance under crash, recovery response collection, outbox drain after force‑quit.
- **Schema‑introspecting test for the "no owner plaintext shares" invariant**: walk every table; for any column matching `*share*payload*`, assert that owner‑side test fixtures (where the device is owner but not also self‑steward) have zero rows for the test vault. Stays correct as the schema evolves.
- **Wipe regression test** (added in Phase 5; consolidated here alongside transaction tests).
- `NativeDatabase.memory()` already in widget/golden tests via fixtures from Phase 0.
- Delete `test/helpers/shared_preferences_mock.dart` and call sites.
- Delete the unused services / cache code from [lib/providers/vault_provider.dart](../lib/providers/vault_provider.dart) (`_cachedVaults`, hand‑rolled `StreamController`).

### Docs phase (parallel — should land in Phase 0 or alongside Phase 1)

Pull the durable architectural sections of this plan out into `docs/data_layer.md` (the long‑lived reference, not this plan) so reviewers and future maintainers don't have to read a refactor proposal to understand the system. Cover:

- The cache‑of‑events framing: Nostr is the log, on‑device tables are projections.
- The schema and the rationale for the design choices, including the indexes and ON DELETE matrix.
- Owner‑side vs. steward‑side tables and why they're separate.
- The on‑disk vs. on‑wire boundary and where denormalization is intentional.
- The transactional outbox pattern (parent + per‑relay child) and how it's used.
- The threat model: SQLCipher whole‑DB + NIP‑44 for `vaults.content` only, application‑layer plaintext for `share_payload`, why each.
- The DB key derivation contract (HKDF parameters, salt location, key lifetime, rotation limitation).
- The share‑material‑lifecycle asymmetry between distribution (in‑memory only) and recovery (persist for active session).
- The held‑share retention policy and its interaction with cross‑version recovery.
- The "wire `created_at` is for audit only; freshness uses local clocks" convention.
- The recovery‑scope limitation: v1 requires local rows to start a recovery.

Linked from [README.md](../README.md) and [AGENTS.md](../AGENTS.md). Pulling these out early lets this plan focus on *what changes and when* and keeps reviewers' attention on the deltas.

## Risks explicitly NOT addressed by this plan (capture as new beads)

1. **Multi‑device divergence policy** — what happens when two devices edit the same vault concurrently; today it's last‑write‑wins on Nostr `created_at`. Likely needs vector versions or merge logic. Independent epic.
2. **Steward state propagation review** — the `distribution_version` / `acknowledged_at` model is decent but partial; review once stewards‑as‑rows lands.
3. **Cross‑version recovery reconciliation UX** — *Title*: "Recovery: serve and warn on distribution‑version mismatch" / *Type*: feature. Manage‑recovery screen shows a warning when the user is recovering against an old distribution version. Stewards attempt to serve the share for the requested distribution version when possible (using the multi‑version held_shares retention). If a recovery response arrives with a mismatched distribution version, show a toast and mark that steward as "error" on the manage recovery screen. Schema lays the groundwork (`recovery_requests.distribution_version_at_start`, `recovery_responses.share_distribution_version`); UX/logic deferred to a follow‑up.
4. **Move `processed_nostr_event_store` into the SQLCipher DB** — *Title*: "Migrate processed‑events store into drift" / *Type*: task. v1 keeps today's standalone implementation. The right long‑term answer is a `processed_events(event_id PK, kind, processed_at)` table inside the same DB so dedup is transactional with the rows it gates. Decision deferred to keep Phase 3 scoped.
5. **Stalled‑outbox cleanup policy** — *Title*: "Outbox: define stalled‑publish drop / restart policy" / *Type*: task. "All relays fail forever → drop and restart distribution at a fresh version" needs an actor (manual button vs. auto after T time), a retry budget, and version‑rollback semantics. Schema accommodates whichever policy we land on.
6. **Initiator → owner promotion** — taking ownership of a recovered vault is a separate epic. Schema intentionally allows it (the precedence rules cover the flip from `held_shares`‑only to having an `owned_vaults` row), but the user‑facing flow and atomic transition aren't built here.
7. **Nostr private‑key rotation** — v1 cannot re‑key the SQLCipher DB if the underlying Nostr key changes. Documented limitation; tracked for a future "key rotation" epic.
8. **Recovery for vaults with no local rows** — the "lost device, restore from scratch with only an npub" flow is not supported in v1. Tracked as a follow‑up that needs a discovery step landing a `vaults` placeholder before recovery can start.

(Bead IDs left blank; created via `bd create` after plan approval. The bd CLI in the current worktree environment was unavailable when this plan was last updated; titles and types above are ready to paste into `bd create` calls.)

## Acceptance criteria for the epic

- All on‑device state outside `FlutterSecureStorage` lives in the SQLCipher‑encrypted SQLite DB. SharedPreferences is removed from the app's runtime code paths.
- DB key derivation is HKDF‑SHA‑256 with the `info` string `"horcrux/db-key/v1"` and a 32‑byte salt persisted in `FlutterSecureStorage` under `db_key_salt`. SQLCipher pragmas are pinned per the Stack section, including `PRAGMA secure_delete=ON`.
- Steward identity is normalized into shared `vaults` and `stewards` tables; both roles render the fellow‑stewards list from the same query. No `peer_steward_snapshot` column.
- The owner's device never durably retains Shamir share material destined for *other* stewards: there is no `share_payload` column on `distribution_shares`. The outbox carries gift‑wrap events that are already encrypted to recipients. A schema‑introspecting test asserts that after a full distribution and after an in‑flight crash, no `*share*payload*` column contains rows for the test vault on owner‑only fixtures.
- During an active recovery on the initiator's device, share fragments persist in `recovery_responses.share_payload` only until session end (cancel, explicit end, expiration, or vault deletion); a test asserts that after session end (a) no `recovery_responses` rows remain for that request, (b) `wal_checkpoint(TRUNCATE)` was called, and (c) no plaintext share material is recoverable from the DB file.
- Multi‑version `held_shares` retention works: keeping the most‑recent N versions per vault (default 3) is enforced in the same transaction that ingests new shares.
- Invitation acceptance, distribution + acknowledgment, and recovery response handling are wrapped in transactions; the outbox + per‑relay child rows guarantee state‑and‑publish atomicity per relay.
- Schema is at version 1 with `MigrationStrategy` in place; `drift_schemas/v1.json` is committed; CI fails any schema change without a corresponding version bump and migration test.
- Logout / wipe deterministically removes the DB file, its `-wal` and `-shm` siblings, and clears `FlutterSecureStorage` (Nostr key and `db_key_salt`); a regression test asserts this on macOS and Linux.
- All existing tests pass; new transaction‑coverage tests added; goldens regenerated where copy changed.
- `Shard` is gone from Dart symbols and file names; Nostr wire JSON keys unchanged.
- `docs/data_layer.md` exists and is linked from the top‑level docs.
- Out‑of‑scope risks tracked as follow‑up beads under `horcrux_app-hvc` (or as separate epics).
