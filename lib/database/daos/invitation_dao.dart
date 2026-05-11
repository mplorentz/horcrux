import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/invitations.dart';

part 'invitation_dao.g.dart';

@DriftAccessor(tables: [Invitations])
class InvitationDao extends DatabaseAccessor<AppDatabase> with _$InvitationDaoMixin {
  InvitationDao(super.db);

  Future<InvitationRow?> getByCode(String code) =>
      (select(invitations)..where((i) => i.code.equals(code))).getSingleOrNull();

  Future<List<InvitationRow>> forVault(String vaultId) =>
      (select(invitations)..where((i) => i.vaultId.equals(vaultId))).get();

  Stream<List<InvitationRow>> watchForSteward(String stewardId) =>
      (select(invitations)..where((i) => i.stewardId.equals(stewardId))).watch();

  Future<void> upsert(InvitationsCompanion row) => into(invitations).insertOnConflictUpdate(row);

  Future<int> deleteForSteward(String stewardId) =>
      (delete(invitations)..where((i) => i.stewardId.equals(stewardId))).go();
}
