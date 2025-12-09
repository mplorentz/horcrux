# Data Model: Lost Device Recovery

**Feature**: 007-lost-device-recovery  
**Date**: 2025-01-09

---

## New Models

### RecoveryInitiationLink

**File**: `lib/models/recovery_initiation_link.dart`

```dart
/// Represents a recovery initiation link created by an owner on a fresh device
typedef RecoveryInitiationLink = ({
  String code,              // Unique identifier for this recovery request
  String ownerTempPubkey,   // Owner's temporary pubkey (hex, 64 chars)
  String vaultName,         // Claimed vault name (hint for steward)
  String ownerName,         // Claimed owner name (for identification)
  List<String> relayUrls,   // Where owner is listening for responses
  DateTime createdAt,       // When link was created
});

/// Create a new recovery initiation link
RecoveryInitiationLink createRecoveryInitiationLink({
  required String ownerTempPubkey,
  required String vaultName,
  required String ownerName,
  required List<String> relayUrls,
}) {
  return (
    code: generateSecureID(),  // Reuse from invite_code_utils.dart
    ownerTempPubkey: ownerTempPubkey,
    vaultName: vaultName,
    ownerName: ownerName,
    relayUrls: relayUrls,
    createdAt: DateTime.now(),
  );
}

/// Convert to shareable URL
String recoveryInitiationLinkToUrl(RecoveryInitiationLink link) {
  final encodedVaultName = Uri.encodeComponent(link.vaultName);
  final encodedOwnerName = Uri.encodeComponent(link.ownerName);
  final encodedRelays = link.relayUrls
      .map((r) => Uri.encodeComponent(r))
      .join(',');
  
  return 'horcrux://horcrux.app/recover/${link.code}'
      '?owner=${link.ownerTempPubkey}'
      '&vault=$encodedVaultName'
      '&name=$encodedOwnerName'
      '&relays=$encodedRelays';
}

/// JSON serialization for local storage
Map<String, dynamic> recoveryInitiationLinkToJson(RecoveryInitiationLink link) {
  return {
    'code': link.code,
    'ownerTempPubkey': link.ownerTempPubkey,
    'vaultName': link.vaultName,
    'ownerName': link.ownerName,
    'relayUrls': link.relayUrls,
    'createdAt': link.createdAt.toIso8601String(),
  };
}

RecoveryInitiationLink recoveryInitiationLinkFromJson(Map<String, dynamic> json) {
  return (
    code: json['code'] as String,
    ownerTempPubkey: json['ownerTempPubkey'] as String,
    vaultName: json['vaultName'] as String,
    ownerName: json['ownerName'] as String,
    relayUrls: (json['relayUrls'] as List).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
```

### RecoveryInitiationLinkData (Parsed from URL)

**For DeepLinkService parsing:**

```dart
/// Data extracted from a recovery initiation deep link
typedef RecoveryInitiationLinkData = ({
  String code,
  String ownerTempPubkey,
  String vaultName,
  String ownerName,
  List<String> relayUrls,
});
```

---

## Modified Models

### RecoveryRequest

**File**: `lib/models/recovery_request.dart`

**New Fields:**
```dart
final String? ownerRecoveryPubkey;    // Owner's temp key for lost-device flow
final List<String>? responseRelayUrls; // Relays for sending responses
```

**Updated Constructor:**
```dart
const RecoveryRequest({
  required this.id,
  required this.vaultId,
  required this.initiatorPubkey,
  required this.requestedAt,
  required this.status,
  required this.threshold,
  this.isPractice = false,
  this.ownerRecoveryPubkey,      // NEW
  this.responseRelayUrls,         // NEW
  this.nostrEventId,
  this.expiresAt,
  this.stewardResponses = const {},
  this.errorMessage,
});
```

**Updated copyWith:**
```dart
RecoveryRequest copyWith({
  // ... existing params ...
  String? ownerRecoveryPubkey,
  List<String>? responseRelayUrls,
}) {
  return RecoveryRequest(
    // ... existing fields ...
    ownerRecoveryPubkey: ownerRecoveryPubkey ?? this.ownerRecoveryPubkey,
    responseRelayUrls: responseRelayUrls ?? this.responseRelayUrls,
  );
}
```

**Updated toJson:**
```dart
Map<String, dynamic> toJson() {
  return {
    // ... existing fields ...
    'ownerRecoveryPubkey': ownerRecoveryPubkey,
    'responseRelayUrls': responseRelayUrls,
  };
}
```

**Updated fromJson:**
```dart
factory RecoveryRequest.fromJson(Map<String, dynamic> json) {
  return RecoveryRequest(
    // ... existing fields ...
    ownerRecoveryPubkey: json['ownerRecoveryPubkey'] as String?,
    responseRelayUrls: json['responseRelayUrls'] != null
        ? (json['responseRelayUrls'] as List).cast<String>()
        : null,
  );
}
```

### Vault

**File**: `lib/models/vault.dart`

**New Field:**
```dart
final String? recoveryPubkey;  // Set when steward approves recovery for owner's temp key
```

**Usage:**
- Set when a steward approves a recovery request that has `ownerRecoveryPubkey`
- Used later for key rotation validation (feature 008)

---

## Nostr Event Changes

### Recovery Request Event (Kind 1350)

**Updated Payload:**
```json
{
  "type": "recovery_request",
  "recovery_request_id": "...",
  "vault_id": "...",
  "initiator_pubkey": "...",
  "owner_recovery_pubkey": "abc123...",  // NEW: owner's temp key
  "response_relay_urls": ["wss://..."],  // NEW: where to send responses
  "requested_at": "...",
  "expires_at": "...",
  "threshold": 2,
  "is_practice": false
}
```

### Recovery Response Event (Kind 1351)

**Response Routing:**
- If `owner_recovery_pubkey` is set: send response to that pubkey
- Else: send response to `initiator_pubkey`

**Response Relay Selection:**
- If `response_relay_urls` is set: use those relays
- Else: use relays from shard data

---

## Deep Link Parsing

### URL Format
```
horcrux://horcrux.app/recover/{code}?owner={pubkey}&vault={name}&name={ownerName}&relays={urls}
```

### Parsing Logic

**In DeepLinkService:**
```dart
RecoveryInitiationLinkData? parseRecoveryInitiationLink(Uri uri) {
  // Validate scheme: https or horcrux
  if (uri.scheme != 'https' && uri.scheme != 'horcrux') {
    throw InvalidRecoveryLinkException(...);
  }
  
  // Validate path: /recover/{code}
  if (uri.pathSegments.length != 2 || uri.pathSegments[0] != 'recover') {
    throw InvalidRecoveryLinkException(...);
  }
  
  final code = uri.pathSegments[1];
  final ownerPubkey = uri.queryParameters['owner'];
  final vaultName = uri.queryParameters['vault'];
  final ownerName = uri.queryParameters['name'];
  final relaysParam = uri.queryParameters['relays'];
  
  // Validate required params
  if (ownerPubkey == null || !isValidHexPubkey(ownerPubkey)) {
    throw InvalidRecoveryLinkException(...);
  }
  // ... more validation ...
  
  final relayUrls = relaysParam?.split(',')
      .map((r) => Uri.decodeComponent(r))
      .where((r) => isValidRelayUrl(r))
      .toList() ?? [];
  
  return (
    code: code,
    ownerTempPubkey: ownerPubkey,
    vaultName: Uri.decodeComponent(vaultName ?? ''),
    ownerName: Uri.decodeComponent(ownerName ?? ''),
    relayUrls: relayUrls,
  );
}
```

---

## State Flows

### Owner on Fresh Device

```
[Fresh Install]
      │
      ▼
[WhatBringsYouScreen] ──("I need to recover")──▶ [OwnerRecoveryScreen]
      │                                                    │
      │                                          (generate temp key)
      │                                          (enter vault/name)
      │                                          (generate link)
      │                                                    │
      │                                                    ▼
      │                                          [Link Generated]
      │                                                    │
      │                                           (share with steward)
      │                                                    │
      │                                                    ▼
      │                                          [Waiting for Recovery]
      │                                                    │
      │                                          (steward initiates)
      │                                          (responses received)
      │                                                    │
      │                                                    ▼
      │                                          [Recovery Complete]
      │                                                    │
      │                                                    ▼
      │                                            [Vault Restored]
```

### Steward Processing Link

```
[Tap Recovery Link]
      │
      ▼
[DeepLinkService parses link]
      │
      ▼
[StewardRecoveryAcceptScreen]
      │
      ├── Shows owner's claimed info
      ├── Lists vaults steward holds
      │
      ▼
[Select vault, confirm]
      │
      ▼
[RecoveryService.initiateRecovery]
      │
      ├── ownerRecoveryPubkey = link.ownerTempPubkey
      ├── responseRelayUrls = link.relayUrls
      │
      ▼
[Recovery requests sent to stewards]
      │
      ▼
[Responses routed to owner's temp key]
```

---

## Vault Stub Creation (Fresh Device)

When owner on a fresh device receives their first recovery response, a vault stub is automatically created:

```dart
/// Create vault stub from incoming shard data
Future<Vault> createVaultStubFromShard(ShardData shard) async {
  // Extract metadata from shard
  final vault = Vault(
    id: shard.vaultId,
    name: shard.vaultName ?? 'Recovered Vault',
    content: null,  // Will be populated after reconstruction
    createdAt: DateTime.now(),
    ownerPubkey: shard.ownerPubkey,
    shards: [shard],  // First shard
    recoveryRequests: [],
    backupConfig: null,
  );
  
  await repository.addVault(vault);
  return vault;
}

/// Add subsequent shard to existing vault stub
Future<void> addShardToVaultStub(String vaultId, ShardData shard) async {
  final vault = await repository.getVault(vaultId);
  if (vault == null) {
    // First shard - create stub
    await createVaultStubFromShard(shard);
    return;
  }
  
  // Add shard to existing stub
  final updatedShards = [...vault.shards, shard];
  await repository.saveVault(vault.copyWith(shards: updatedShards));
  
  // Check if we can reconstruct
  // (threshold check happens elsewhere based on recovery request)
}
```

**ShardData must include:**
- `vaultId` - To identify which vault this shard belongs to
- `vaultName` - For display (may be null, use fallback)
- `ownerPubkey` - The original owner's pubkey

These fields should already be present in `ShardData` from the original distribution.

## Backwards Compatibility

- `ownerRecoveryPubkey` and `responseRelayUrls` default to null
- Existing recovery requests continue to work (responses go to initiator)
- `recoveryPubkey` on Vault defaults to null
- No migration needed
