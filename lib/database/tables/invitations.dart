import 'package:drift/drift.dart';

import 'stewards.dart';
import 'vaults.dart';

/// Invitation for a vault. [stewardId] is set for owner-generated invites
/// (bound to a steward slot); null for invitee-side received invites.
@DataClassName('InvitationRow')
class Invitations extends Table {
  /// Invite code (primary key).
  TextColumn get code => text()();

  TextColumn get vaultId => text().references(
        Vaults,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get stewardId => text().nullable().references(
        Stewards,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// JSON blob ([invitationLinkToJson]).
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get expiresAt => integer().nullable()();
  IntColumn get acceptedAt => integer().nullable()();
  TextColumn get acceptedByPubkey => text().nullable()();
  IntColumn get revokedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}
