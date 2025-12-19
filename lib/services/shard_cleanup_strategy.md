# Shard Cleanup Strategy

## Overview
Delete old shards after generating new ones, while ensuring vaults remain recoverable.

## Retention Rules

### Safe to Delete When:
1. **All stewards have acknowledged the new version** (`allStewardsHoldingCurrentKey == true`)
   - All stewards with pubkeys have `acknowledgedDistributionVersion == currentDistributionVersion`
   - Safe to delete shards from previous versions

2. **Grace period expired** (fallback safety)
   - If old shards are > 7 days old AND new version exists
   - Provides safety net even if acknowledgments are delayed

### Never Delete:
- Shards from the current distribution version
- Shards if no newer version exists (single version)
- Shards if any steward is still on an old version AND grace period hasn't expired

## Implementation

### Helper Function: `cleanupOldShards`
- Groups shards by `distributionVersion`
- Identifies current version from `BackupConfig.distributionVersion`
- Checks `allStewardsHoldingCurrentKey` status
- Calculates age of old shards
- Deletes only when safe

### Integration Points:
1. **After successful distribution**: Call cleanup after `createAndDistributeBackup` completes
2. **After content change**: Call cleanup after `handleContentChange` (but only if old version was fully acknowledged)
3. **Periodic cleanup**: Optional background task to catch edge cases

## Data Model Support

### Current State:
- ✅ Shards have `distributionVersion` field
- ✅ `BackupConfig` tracks current `distributionVersion`
- ✅ Stewards track `acknowledgedDistributionVersion`
- ✅ Helper `allStewardsHoldingCurrentKey` exists

### Future UI Support:
- Data model preserves old version shards until safe to delete
- Future UI could show "Recover previous version" option
- Recovery logic can filter shards by version

## Edge Cases

1. **Steward offline**: Grace period ensures cleanup happens eventually
2. **Multiple rapid changes**: Each version retained until safe
3. **Partial acknowledgments**: Old version kept until all acknowledge new version
4. **Owner-steward**: Owner's shard follows same rules

