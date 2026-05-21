/// Reasons for a key holder removal event (kind 721/NIP-...).
///
/// Sent as a `reason` tag on the event so the steward's device can
/// distinguish between an owner removing them from the backup config
/// and the entire vault being deleted.
enum KeyHolderRemovalReason {
  /// Owner removed this steward from the backup config.
  /// Maps to archivedReason: 'Removed by owner'
  stewardRemoved('steward_removed'),

  /// Owner deleted the entire vault.
  /// Maps to archivedReason: 'Vault deleted'
  vaultDeleted('vault_deleted');

  /// The wire value sent in the `reason` tag.
  final String wireValue;

  const KeyHolderRemovalReason(this.wireValue);

  /// Parse from the wire (tag value), defaulting to [stewardRemoved] for
  /// legacy events that predate the reason tag.
  static KeyHolderRemovalReason fromWire(String? value) {
    switch (value) {
      case 'vault_deleted':
        return vaultDeleted;
      case 'steward_removed':
        return stewardRemoved;
      default:
        return stewardRemoved;
    }
  }
}
