# Shard Cleanup Implementation Prompt

## Problem
Vaults are accumulating old shards when content or recovery plans change, causing the encrypted vault JSON to grow very large (69KB+). This leads to "Invalid plaintext length" errors when trying to encrypt with NIP-44, which has size limits.

## Root Cause
When a vault's content changes or recovery plan is updated:
1. `handleContentChange()` increments `distributionVersion`
2. New shards are generated and distributed
3. **Old shards are never deleted** - they accumulate in `vault.shards` array
4. Each shard contains large fields (`shard`, `primeMod`, `peers` list) making JSON huge

## Solution: Version-Based Shard Cleanup

Implement a cleanup function that deletes old shards **only when safe** - i.e., when all stewards have acknowledged the new distribution version.

### Safety Requirements
- **Never delete shards from the current distribution version**
- **Only delete old version shards when `allStewardsHoldingCurrentKey == true`**
- This ensures vaults remain recoverable - if stewards haven't received new keys, old keys are still available

### Implementation Steps

1. **Add cleanup function to `BackupService`** (`lib/services/backup_service.dart`):
   ```dart
   /// Clean up old shards for a vault when safe to do so
   /// 
   /// Deletes shards from versions older than the current distribution version,
   /// but only if all stewards have acknowledged the current version.
   /// This prevents vaults from becoming unrecoverable.
   Future<void> cleanupOldShards(String vaultId) async {
     // 1. Load vault and backup config
     // 2. Get current distributionVersion from config
     // 3. Check if allStewardsHoldingCurrentKey == true
     // 4. If safe, filter vault.shards to keep only:
     //    - Shards with distributionVersion == currentVersion
     //    - Shards with distributionVersion == null (backward compatibility)
     // 5. Save updated vault
   }
   ```

2. **Call cleanup after successful distribution** in `createAndDistributeBackup()`:
   - After Step 7 (updating backup config), call `cleanupOldShards(vaultId)`
   - This cleans up old shards after new ones are distributed

3. **Call cleanup after content change** (optional but recommended):
   - In `handleContentChange()`, after incrementing version, check if previous version was fully acknowledged
   - If yes, cleanup old shards before incrementing (or schedule cleanup)

### Key Files to Modify

- `lib/services/backup_service.dart`:
  - Add `cleanupOldShards()` method
  - Call it from `createAndDistributeBackup()` after successful distribution
  - Optionally call from `handleContentChange()` if previous version was fully acknowledged

- `lib/providers/vault_provider.dart`:
  - May need helper method to filter shards by version
  - Or implement filtering logic directly in cleanup function

### Data Model Notes

- Shards already have `distributionVersion` field (nullable for backward compatibility)
- `BackupConfig` has `allStewardsHoldingCurrentKey` helper (already implemented)
- Stewards track `acknowledgedDistributionVersion`

### Testing Considerations

1. **Test cleanup doesn't delete current version shards**
2. **Test cleanup only happens when all stewards acknowledged**
3. **Test cleanup preserves backward-compatible shards** (distributionVersion == null)
4. **Test cleanup reduces JSON size** (verify before/after sizes)
5. **Test vault remains recoverable** after cleanup (can still recover with remaining shards)

### Edge Cases

- **No backup config**: Skip cleanup (no version tracking)
- **Single version**: Don't delete anything (no old versions)
- **Partial acknowledgments**: Keep old shards until all acknowledge new version
- **Owner-steward**: Owner's shard follows same rules
- **Recovery in progress**: Consider keeping recovery shards even if old version

### Reference Files

- `lib/services/backup_service.dart` - Main service file
- `lib/models/backup_config.dart` - Has `allStewardsHoldingCurrentKey` helper
- `lib/models/shard_data.dart` - ShardData model with `distributionVersion` field
- `lib/providers/vault_provider.dart` - Vault repository with shard management
- `lib/services/shard_cleanup_strategy.md` - Strategy document (if exists)

### Success Criteria

- Old shards are deleted when safe (all stewards acknowledged new version)
- Vaults remain recoverable (never delete shards needed for recovery)
- JSON size is reduced (verify vault JSON is smaller after cleanup)
- No "Invalid plaintext length" errors when saving vaults with many shards

