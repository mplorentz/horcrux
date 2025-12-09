# Data Model: Owner Self-Shard & Content Deletion

**Feature**: 006-owner-shard  
**Date**: 2025-01-09

---

## Model Changes

### Steward (Modified)

**File**: `lib/models/steward.dart`

**New Field**:
```dart
final bool isOwner;  // True when this steward is the vault owner, default false
```

**Updated typedef** (if using typedef pattern):
```dart
typedef Steward = ({
  String? pubkey,
  String? name,
  StewardStatus status,
  String? inviteCode,
  bool isOwner,  // NEW
});
```

**Updated Factory Functions**:
```dart
Steward createSteward({
  String? pubkey,
  String? name,
  StewardStatus status = StewardStatus.invited,
  String? inviteCode,
  bool isOwner = false,  // NEW
}) {
  return (
    pubkey: pubkey,
    name: name,
    status: status,
    inviteCode: inviteCode,
    isOwner: isOwner,
  );
}

/// Convenience factory for creating owner steward
Steward createOwnerSteward({
  required String pubkey,
  String? name,
  StewardStatus status = StewardStatus.awaitingKey,
}) {
  return createSteward(
    pubkey: pubkey,
    name: name ?? 'You',
    status: status,
    isOwner: true,
  );
}
```

**Updated copySteward**:
```dart
Steward copySteward(
  Steward steward, {
  String? pubkey,
  String? name,
  StewardStatus? status,
  String? inviteCode,
  bool? isOwner,
}) {
  return (
    pubkey: pubkey ?? steward.pubkey,
    name: name ?? steward.name,
    status: status ?? steward.status,
    inviteCode: inviteCode ?? steward.inviteCode,
    isOwner: isOwner ?? steward.isOwner,
  );
}
```

**Updated JSON Serialization**:
```dart
Map<String, dynamic> stewardToJson(Steward steward) {
  return {
    'pubkey': steward.pubkey,
    'name': steward.name,
    'status': steward.status.name,
    'inviteCode': steward.inviteCode,
    'isOwner': steward.isOwner,  // NEW
  };
}

Steward stewardFromJson(Map<String, dynamic> json) {
  return (
    pubkey: json['pubkey'] as String?,
    name: json['name'] as String?,
    status: StewardStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => StewardStatus.invited,
    ),
    inviteCode: json['inviteCode'] as String?,
    isOwner: json['isOwner'] as bool? ?? false,  // NEW, default false
  );
}
```

---

## ShardData Considerations

The existing `ShardData` model already stores shards per vault. When owner is a steward:
- Owner's shard is stored in the vault's `shards` list
- No special handling needed - same storage mechanism

To identify owner's shard when needed:
```dart
// Option 1: Check against current user pubkey
final currentPubkey = await loginService.getCurrentPublicKey();
final isOwnerShard = shard.stewardPubkey == currentPubkey && vault.ownerPubkey == currentPubkey;

// Option 2: Store isOwner on ShardData (if needed)
// This would require ShardData model changes - evaluate if necessary
```

---

## State Transitions

### Vault States with Owner Shard

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  [Created] ──(add content)──▶ [Owned]                      │
│                                  │                         │
│                    ┌─────────────┴─────────────┐           │
│                    │                           │           │
│                    ▼                           ▼           │
│          (distribute with            (distribute without   │
│           owner shard)                owner shard)         │
│                    │                           │           │
│                    ▼                           ▼           │
│           [Owned + Has Shard]          [Owned, No Shard]   │
│                    │                           │           │
│          (delete content)            (delete content)      │
│                    │                           │           │
│                    ▼                           ▼           │
│           [Steward + isOwner]        [??? - No shard,      │
│                    │                   No content]         │
│                    │                           │           │
│         (initiate recovery)           (Must rely on        │
│                    │                   stewards)           │
│                    ▼                                       │
│             [Recovery Mode]                                │
│                    │                                       │
│             (reconstruct)                                  │
│                    │                                       │
│                    ▼                                       │
│                [Owned]                                     │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### State Determination Logic

Current `vault.state` getter in `lib/models/vault.dart`:

```dart
VaultState get state {
  if (hasActiveRecovery) return VaultState.recovery;
  if (content != null) return VaultState.owned;
  if (shards.isNotEmpty) return VaultState.steward;
  return VaultState.awaitingKey;
}
```

This logic already handles the owner-shard case correctly:
- Owner with content + shard → `owned` (content takes precedence)
- Owner with no content + shard → `steward`
- Owner with no content + no shard → `awaitingKey`

---

## Backup Config Helpers

**New Helper - Check if Owner in Steward List**:
```dart
bool hasOwnerSteward(BackupConfig config) {
  return config.stewards.any((s) => s.isOwner);
}

Steward? getOwnerSteward(BackupConfig config) {
  return config.stewards.firstWhereOrNull((s) => s.isOwner);
}
```

**Updated Total Keys Calculation**:
```dart
// totalKeys should include owner if present
int get effectiveTotalKeys => stewards.length;  // Already correct - owner is in stewards list
```

---

## Content Deletion

### Operation
```dart
Future<void> deleteVaultContent(String vaultId) async {
  final vault = await repository.getVault(vaultId);
  if (vault == null) throw ArgumentError('Vault not found');
  
  // Delete content but preserve everything else (including shards)
  await repository.saveVault(vault.copyWith(content: null));
  
  Log.info('Deleted content for vault $vaultId, shards preserved');
}
```

### Important: Content vs Shards Storage
- `vault.content` - The actual vault data (deleted)
- `vault.shards` - Shard data for recovery (preserved)

These are separate fields, so deleting content doesn't affect shards.

---

## Backwards Compatibility

- `isOwner` defaults to `false` for existing stewards
- Existing vaults without owner steward continue to work
- No migration needed - new field is additive with safe default
