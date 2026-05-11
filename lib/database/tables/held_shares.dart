import 'package:drift/drift.dart';

import 'vaults.dart';

/// Steward-side table for share material received from the owner.
///
/// Multi-version retention is intentional: there is NO `UNIQUE(vault_id)`
/// constraint. Policy is to keep the N most-recent versions per vault (default
/// 3) so a recovery request asking for an older `distribution_version` can
/// still be served. Dedup within the same version is enforced by the
/// `held_shares_vault_version_event` unique index on
/// `(vault_id, distribution_version, nostr_event_id)`.
///
/// The owner device's self-share (the owner-as-steward carve-out) also lives
/// here. For that row, [sharePayload] may be intentionally empty: the shard
/// material is only on Nostr; [RecoveryService] re-fetches it by
/// [HeldShareRow.nostrEventId] when needed.
///
/// `share_index` uses the same 0-based convention as [Share.shareIndex] in the
/// Dart model and the wire format (`shard_index` JSON key). This differs from
/// the `stewards.share_index` column, which is 1-based.
@DataClassName('HeldShareRow')
class HeldShares extends Table {
  TextColumn get id => text()();
  TextColumn get vaultId => text().references(Vaults, #id, onDelete: KeyAction.cascade)();

  /// 0-based Shamir share position (matches [Share.shareIndex] and wire
  /// `shard_index`).
  IntColumn get shareIndex => integer()();

  /// Raw Shamir share bytes. Application-layer plaintext protected by
  /// SQLCipher whole-DB encryption. See "Share material lifecycle" in the
  /// data layer refactor plan.
  TextColumn get sharePayload => text()();

  /// Distribution version at which this share was generated. Used for
  /// retention pruning and for serving a specific version during recovery.
  IntColumn get distributionVersion => integer()();

  /// Local clock timestamp (ms since epoch) when this row was first written.
  /// Never sourced from the Nostr event `created_at` — see "Time,
  /// monotonicity, clock skew" in the refactor plan.
  IntColumn get receivedAt => integer()();

  /// Nostr event ID of the gift-wrap that delivered this share. Used for
  /// dedup (see unique index `held_shares_vault_version_event`).
  TextColumn get nostrEventId => text().nullable()();

  /// Relay URL this share was first ingested from. Lets the steward publish
  /// an ack to a sensible relay without re-guessing.
  TextColumn get lastSeenRelay => text().nullable()();

  /// Mirrors the owner's push preference at distribution time. Combined with
  /// `vaults.push_enabled` to determine whether to fire local push
  /// notifications for this vault.
  BoolColumn get pushEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
