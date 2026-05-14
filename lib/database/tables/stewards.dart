import 'package:drift/drift.dart';

import 'vaults.dart';

/// Single history-bearing table for stewards. Replacement = append: set
/// `leftAt` on the current row, insert a new row with the same
/// `(vaultId, shareIndex)` and the new pubkey/name. The partial unique index
/// `stewards_vault_position_active` (created in [AppDatabase] migrations)
/// enforces "exactly one active steward per share index".
@DataClassName('StewardRow')
class Stewards extends Table {
  TextColumn get id => text()();
  TextColumn get vaultId => text().references(Vaults, #id, onDelete: KeyAction.cascade)();

  /// Shamir share position 1..N. Persists across replacement events.
  IntColumn get shareIndex => integer()();

  /// Nullable until the invitee accepts and we learn their pubkey.
  TextColumn get pubkey => text().nullable()();

  /// Owner-generated invite code bound to this steward slot. Duplicated from
  /// [Invitations] so another owner device can match [NostrKind.invitationAcceptance]
  /// payloads when its invitations row is missing (e.g. plan created elsewhere).
  TextColumn get inviteCode => text().nullable()();

  TextColumn get name => text().nullable()();

  /// Shared on the wire as part of the share event; UI hides it outside
  /// active recovery flows.
  TextColumn get contactInfo => text().nullable()();

  BoolColumn get isOwner => boolean().withDefault(const Constant(false))();
  IntColumn get joinedAt => integer()();

  /// Null = active. Set when the steward leaves or is replaced.
  IntColumn get leftAt => integer().nullable()();
  TextColumn get removalReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
