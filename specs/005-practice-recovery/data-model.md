# Data Model: Practice Recovery

**Feature**: 005-practice-recovery  
**Date**: 2025-01-09

---

## Model Changes

### RecoveryRequest (Modified)

**File**: `lib/models/recovery_request.dart`

**New Field**:
```dart
final bool isPractice;  // True for practice recovery sessions, default false
```

**Updated Constructor**:
```dart
const RecoveryRequest({
  required this.id,
  required this.vaultId,
  required this.initiatorPubkey,
  required this.requestedAt,
  required this.status,
  required this.threshold,
  this.isPractice = false,  // NEW
  this.nostrEventId,
  this.expiresAt,
  this.stewardResponses = const {},
  this.errorMessage,
});
```

**Updated copyWith**:
```dart
RecoveryRequest copyWith({
  // ... existing params ...
  bool? isPractice,
}) {
  return RecoveryRequest(
    // ... existing fields ...
    isPractice: isPractice ?? this.isPractice,
  );
}
```

**Updated toJson**:
```dart
Map<String, dynamic> toJson() {
  return {
    // ... existing fields ...
    'isPractice': isPractice,
  };
}
```

**Updated fromJson**:
```dart
factory RecoveryRequest.fromJson(Map<String, dynamic> json) {
  return RecoveryRequest(
    // ... existing fields ...
    isPractice: json['isPractice'] as bool? ?? false,
  );
}
```

---

## Nostr Event Payload Changes

### Recovery Request Event (Kind 1350)

**Updated Payload**:
```json
{
  "type": "recovery_request",
  "recovery_request_id": "...",
  "vault_id": "...",
  "initiator_pubkey": "...",
  "requested_at": "...",
  "expires_at": "...",
  "threshold": 2,
  "is_practice": true  // NEW: included when practice mode
}
```

### Recovery Response Event (Kind 1351)

**Practice Response Payload** (no shard data):
```json
{
  "type": "recovery_response",
  "recovery_request_id": "...",
  "vault_id": "...",
  "responder_pubkey": "...",
  "approved": true,
  "responded_at": "...",
  "is_practice": true  // Matches request
  // NOTE: shard_data is OMITTED for practice responses
}
```

---

## State Transitions

### Practice Recovery States

```
[No Active Recovery]
        │
        ▼ (owner taps "Practice Recovery")
   [Pending] ──────────────────────────────┐
        │                                   │
        ▼ (request sent to stewards)        │
    [Sent] ────────────────────────────────┤
        │                                   │
        ▼ (first response received)         │
 [In Progress] ────────────────────────────┤
        │                                   │
        ├──▶ (owner taps "End Practice")    │
        │           │                       │
        │           ▼                       │
        │     [Archived] ◀──────────────────┘
        │
        ▼ (all stewards responded)
  [Completed]
        │
        ▼ (owner taps "End Practice")
   [Archived]
```

### Key Differences from Real Recovery

| Aspect | Real Recovery | Practice Recovery |
|--------|---------------|-------------------|
| Shard data in response | Included | Omitted |
| Can reconstruct vault | Yes | No |
| Purpose | Restore access | Validate setup |
| UI styling | Red/urgent | Orange/informational |
| Completion action | "End Recovery" | "End Practice" |

---

## Validation Rules

1. **Cannot start practice during active recovery**: If `hasActiveRecovery` is true and it's not a practice request, block new practice requests
2. **Practice requests require distributed shards**: `backupConfig.stewards` must have at least one steward with `status == holdingKey`
3. **Practice responses must not include shard data**: Service layer enforces this regardless of what client sends

---

## Backwards Compatibility

- `isPractice` defaults to `false` for existing recovery requests
- Older clients that don't understand `isPractice` will treat practice requests as real requests (acceptable since no shard data is sent in responses)
- New clients should always check `isPractice` flag for appropriate UI rendering
