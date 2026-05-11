import 'package:drift/drift.dart';

import 'recovery_requests.dart';

/// Stewards included in a recovery request (for progress / total counts).
@DataClassName('RecoveryRequestParticipantRow')
class RecoveryRequestParticipants extends Table {
  TextColumn get requestId => text().references(
        RecoveryRequests,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get pubkey => text()();

  @override
  Set<Column> get primaryKey => {requestId, pubkey};
}
