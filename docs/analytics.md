# Analytics & PII Policy

This document describes the Horcrux product analytics setup, the event schema,
what may and may not be sent, and a checklist for adding new events.

All product analytics flows through `AnalyticsService` (`lib/services/analytics_service.dart`)
— the single chokepoint that wraps the PostHog SDK.

---

## Privacy Posture

- **Consent-gated**: PostHog is initialized **only** when the user has opted in
  via the ConsentScreen. When opted out, zero PostHog code runs.
- **Debug builds opt out**: `kDebugMode` disables all analytics. No PostHog init,
  no network calls, zero footprint.
- **No PII in events**: Event properties must never contain raw vault ids, npubs,
  names, email addresses, or vault contents. The only exception is `identify()`,
  which sends the npub as the PostHog distinct user id (the npub is public key
  material published on Nostr relays).

---

## The Vault Hash Rule

Every vault identifier sent to PostHog **must** be hashed:

```dart
AnalyticsService.vaultHash(vaultId)
```

This returns `sha256(vaultId)` truncated to the first 16 hex characters. It is
deterministic (same input → same hash) and one-way (cannot be reversed to the
raw vault id).

---

## Event Schema

### Navigation events (automatic via `RouteAnalyticsObserver`)

| Event | Properties | Triggered |
|---|---|---|
| `screen_viewed` | `screen: string` (+ optional `analytics_opted_in: bool`) | Every Navigator.push/replace |

`RouteAnalyticsObserver` is a `NavigatorObserver` wired into `MaterialApp`.
It reads `RouteSettings.name` (set via `settings: RouteSettings(name: 'WidgetClassName')`
at each push site) and fires `screen_viewed`. The `ConsentScreen` passes
`analytics_opted_in` as an extra property.

### Action events (manual — via `RowButton.analyticsEvent` or explicit capture)

| Event | Properties | Context |
|---|---|---|
| `app_opened` | `source: 'cold' \| 'background'` | App lifecycle start/resume |
| `vault_opened` | `vault_id_hash: string` | Vault detail opened |
| `vault_created` | `vault_id_hash, threshold, total_shares` | New vault created |
| `backup_config_action` | `vault_id_hash, result: 'save' \| 'discard'` | Backup config saved or discarded |
| `steward_invited` | `vault_id_hash, method: 'link' \| 'npub'` | Steward invitation sent |
| `keys_distributed` | `vault_id_hash, distribution_version` | Shards distributed to stewards |
| `recovery_initiated` | `vault_id_hash, is_practice: bool` | Recovery started |
| `recovery_response_sent` | `vault_id_hash` | Steward sent a shard |
| `recovery_response_approved` | `vault_id_hash` | Owner approved a shard |
| `recovery_response_denied` | `vault_id_hash` | Owner denied a shard |
| `invitation_accepted` | `vault_id_hash` | Invitation accepted |
| `invitation_denied` | `vault_id_hash` | Invitation denied |
| `vault_sealed` | `vault_id_hash` | Travel mode enabled |
| `vault_deleted` | `vault_id_hash` | Vault deleted |
| `feedback_sent` | *(none)* | User submitted feedback |
| `relay_added` | `count_only: int` | Relay added (never URL) |
| `relay_removed` | `count_only: int` | Relay removed (never URL) |

### Property conventions

- `vault_id_hash`: always derived via `AnalyticsService.vaultHash(vaultId)`.
- `count_only`: integer count only — never the actual URL or relay address.
- `result`: use `'save'` or `'discard'` (one event + result property per PostHog
  funnel best practice), not two separate events.
- `is_practice`: boolean distinguishing practice recovery from real recovery.
- `method`: `'link'` or `'npub'` for steward invitation method.

### Prohibited property values

| ❌ Never send | Reason |
|---|---|
| Raw vault id (UUID) | Identifies the vault across Nostr events |
| npub hex or bech32 | Links events to a Nostr identity |
| Email address | PII |
| Vault name / owner name | Could identify the user |
| Vault content / shard data | Contains the actual secret |
| Relay URLs | Could identify the user's relay setup |
| Nostr event IDs | Links analytics to Nostr protocol events |

---

## Adding a New Event

1. Add the event name and properties to the table above.
2. Add the capture call via `AnalyticsService.capture(event, properties)` —
   never call `Posthog().capture()` directly.
3. If the event includes a vault id, wrap it with `AnalyticsService.vaultHash()`.
4. Verify no PII leaks in the properties (check the prohibited list).
5. Add a unit test verifying the event is captured correctly.
6. Update this document.