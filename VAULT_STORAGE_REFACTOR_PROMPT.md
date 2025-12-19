# Vault Storage Refactor: Individual Files Per Vault

## Problem
Currently, all vaults are stored as a single encrypted JSON blob in SharedPreferences. This creates several issues:

1. **Artificial limit on vault count**: All vaults must fit in one NIP-44 encrypted blob (~65KB limit)
2. **Performance**: Every vault modification requires encrypting/decrypting ALL vaults
3. **Risk of size limits**: Accumulating shards in one vault can cause the entire blob to exceed NIP-44 limits
4. **Inefficient**: Loading one vault requires decrypting all vaults

## Current Implementation

### Storage Location
- **Single key**: `encrypted_vaults` in SharedPreferences
- **Format**: One encrypted JSON string containing array of all vaults
- **Encryption**: NIP-44 self-encryption of entire JSON array

### Code Location
- `lib/providers/vault_provider.dart`:
  - `_saveVaults()` - Encrypts all vaults as one JSON array
  - `_loadVaults()` - Decrypts entire blob and parses all vaults
  - Uses `_vaultsKey = 'encrypted_vaults'` constant

## Solution: Individual Files Per Vault

Store each vault in its own encrypted file, using a naming scheme like:
- `vault_<vaultId>.encrypted` or
- `vaults/<vaultId>.json.encrypted`

### Benefits
1. **No artificial limit**: Each vault encrypted separately, no combined size limit
2. **Better performance**: Only encrypt/decrypt the vault being modified
3. **Isolated failures**: One corrupted vault doesn't affect others
4. **Easier migration**: Can migrate vaults individually
5. **Better for large vaults**: Vaults with many shards won't affect others

### Storage Strategy Options

#### Option A: SharedPreferences with Multiple Keys
- **Format**: `vault_<vaultId>` keys in SharedPreferences
- **Pros**: Simple, uses existing SharedPreferences infrastructure
- **Cons**: SharedPreferences has key count limits on some platforms
- **Implementation**: Change `_vaultsKey` to `vault_${vaultId}` pattern

#### Option B: File System Storage (Recommended)
- **Format**: Individual files in app's document directory
- **Path**: `<app_documents>/vaults/vault_<vaultId>.encrypted`
- **Pros**: No key count limits, better for large files, more flexible
- **Cons**: Requires file system access, need to handle directory creation
- **Implementation**: Use `path_provider` package (likely already available)

### Recommended Approach: File System Storage

Use `path_provider` to store vaults in app's document directory:
```
<app_documents>/vaults/
  ├── vault_<id1>.encrypted
  ├── vault_<id2>.encrypted
  └── vault_<id3>.encrypted
```

## Implementation Steps

### 1. Update Storage Layer (`lib/providers/vault_provider.dart`)

#### Add file system utilities:
```dart
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VaultRepository {
  // ... existing code ...
  
  Future<Directory> _getVaultsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultsDir = Directory('${appDir.path}/vaults');
    if (!await vaultsDir.exists()) {
      await vaultsDir.create(recursive: true);
    }
    return vaultsDir;
  }
  
  String _getVaultFilePath(String vaultId) {
    return 'vaults/vault_$vaultId.encrypted';
  }
}
```

#### Refactor `_loadVaults()`:
- List all vault files in vaults directory
- Load and decrypt each vault file individually
- Build `_cachedVaults` list from individual files
- Handle missing/corrupted files gracefully (log error, skip vault)

#### Refactor `_saveVaults()`:
- **Option 1**: Save only modified vaults (track which vaults changed)
- **Option 2**: Save all vaults individually (simpler, but less efficient)
- **Recommended**: Track modified vaults, save individually

#### Add individual vault save method:
```dart
Future<void> _saveVault(String vaultId, Vault vault) async {
  final vaultsDir = await _getVaultsDirectory();
  final file = File('${vaultsDir.path}/vault_$vaultId.encrypted');
  
  // Convert vault to JSON
  final vaultJson = vault.toJson();
  final jsonString = json.encode(vaultJson);
  
  // Encrypt with NIP-44
  final encryptedData = await _loginService.encryptText(jsonString);
  
  // Write to file
  await file.writeAsString(encryptedData);
}
```

#### Add individual vault load method:
```dart
Future<Vault?> _loadVault(String vaultId) async {
  try {
    final vaultsDir = await _getVaultsDirectory();
    final file = File('${vaultsDir.path}/vault_$vaultId.encrypted');
    
    if (!await file.exists()) {
      return null;
    }
    
    // Read encrypted file
    final encryptedData = await file.readAsString();
    
    // Decrypt with NIP-44
    final decryptedJson = await _loginService.decryptText(encryptedData);
    
    // Parse JSON
    final vaultJson = json.decode(decryptedJson) as Map<String, dynamic>;
    
    return Vault.fromJson(vaultJson);
  } catch (e) {
    Log.error('Error loading vault $vaultId', e);
    return null;
  }
}
```

### 2. Update Method Signatures

#### Change `_saveVaults()` to `_saveVault(String vaultId)`:
- Save only the specified vault
- Update all call sites to pass vaultId

#### Update `_loadVaults()`:
- List vault files in directory
- Load each vault individually
- Handle errors per-vault (don't fail entire load)

### 3. Migration Strategy

#### Handle existing SharedPreferences data:
```dart
Future<void> _migrateFromSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final oldEncryptedData = prefs.getString('encrypted_vaults');
  
  if (oldEncryptedData == null) {
    return; // No old data to migrate
  }
  
  try {
    // Decrypt old blob
    final decryptedJson = await _loginService.decryptText(oldEncryptedData);
    final List<dynamic> jsonList = json.decode(decryptedJson);
    
    // Save each vault to individual file
    for (var vaultJson in jsonList) {
      final vault = Vault.fromJson(vaultJson as Map<String, dynamic>);
      await _saveVault(vault.id, vault);
    }
    
    // Remove old key (optional - keep for rollback)
    // await prefs.remove('encrypted_vaults');
    
    Log.info('Migrated ${jsonList.length} vaults to individual files');
  } catch (e) {
    Log.error('Error migrating vaults from SharedPreferences', e);
    // Don't throw - allow app to continue with new storage
  }
}
```

#### Call migration in `initialize()`:
- Check if old SharedPreferences key exists
- If yes, migrate to individual files
- Then proceed with normal initialization

### 4. Update All Save Operations

Change all methods that call `_saveVaults()` to call `_saveVault(vaultId)`:
- `saveVault()` - Save single vault
- `addVault()` - Save new vault
- `updateVault()` - Save updated vault
- `addShardToVault()` - Save vault with new shard
- `clearShardsForVault()` - Save vault with cleared shards
- `deleteVaultContent()` - Save vault with deleted content
- `addRecoveryRequest()` - Save vault with new recovery request
- `updateRecoveryRequest()` - Save vault with updated recovery request
- `updateBackupConfig()` - Save vault with updated config

### 5. Add Vault Deletion Support

Since we're using individual files, add proper vault deletion:
```dart
Future<void> deleteVault(String vaultId) async {
  // Remove from cache
  _cachedVaults?.removeWhere((v) => v.id == vaultId);
  
  // Delete file
  final vaultsDir = await _getVaultsDirectory();
  final file = File('${vaultsDir.path}/vault_$vaultId.encrypted');
  if (await file.exists()) {
    await file.delete();
  }
  
  // Notify listeners
  final vaultsList = List<Vault>.unmodifiable(_cachedVaults ?? []);
  _vaultsController.add(vaultsList);
}
```

## Key Files to Modify

- `lib/providers/vault_provider.dart`:
  - Refactor `_loadVaults()` to load individual files
  - Refactor `_saveVaults()` to `_saveVault(String vaultId)`
  - Add migration logic
  - Update all save operations
  - Add file system utilities

- `pubspec.yaml`:
  - Ensure `path_provider` dependency exists (likely already present)

## Testing Considerations

1. **Migration**: Test migration from old SharedPreferences format
2. **Individual saves**: Verify only modified vault is encrypted/saved
3. **Individual loads**: Verify vaults load correctly from files
4. **Error handling**: Test corrupted files, missing files, permission errors
5. **Performance**: Measure improvement in save/load times
6. **Backward compatibility**: Ensure old data migrates correctly
7. **Multiple vaults**: Test with many vaults (10+, 50+)
8. **Large vaults**: Test with vaults containing many shards

## Edge Cases

- **Missing vault file**: Return null, don't crash
- **Corrupted file**: Log error, skip vault, continue loading others
- **Permission errors**: Handle file system permission issues
- **Concurrent access**: Ensure thread-safe file operations
- **Migration failures**: Don't lose data if migration fails
- **Empty directory**: Handle case where no vaults exist yet

## Performance Improvements Expected

- **Save operation**: O(1) instead of O(n) - only encrypt one vault
- **Load operation**: O(n) but can be optimized with lazy loading
- **Memory**: Only decrypt vaults as needed (can implement lazy loading later)

## Future Enhancements (Out of Scope)

- **Lazy loading**: Only load vaults when accessed
- **Vault indexing**: Maintain index file for fast vault listing
- **Compression**: Compress individual vault files before encryption
- **Backup/export**: Easier to backup individual vault files

## Success Criteria

- ✅ Each vault stored in individual encrypted file
- ✅ Migration from old format works correctly
- ✅ No data loss during migration
- ✅ Performance improved (faster saves)
- ✅ No artificial vault count limit
- ✅ Large vaults (many shards) don't affect others
- ✅ Error handling for corrupted/missing files
- ✅ All existing functionality preserved

## Reference Files

- `lib/providers/vault_provider.dart` - Main storage implementation
- `lib/services/login_service.dart` - NIP-44 encryption service
- `lib/models/vault.dart` - Vault model with toJson/fromJson

## Notes

- This is a breaking change for storage format, but migration handles it
- Consider keeping old SharedPreferences key for rollback during testing
- File system storage is more appropriate for this use case than SharedPreferences
- Can be implemented incrementally: migration first, then new saves, then cleanup

