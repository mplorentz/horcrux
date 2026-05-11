import 'package:drift/drift.dart';

import 'recovery_requests.dart';
import 'stewards.dart';

/// One steward response / fragment for an active recovery session.
@DataClassName('RecoveryResponseRow')
class RecoveryResponses extends Table {
  TextColumn get id => text()();
  TextColumn get requestId => text().references(
        RecoveryRequests,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get stewardId => text().nullable().references(
        Stewards,
        #id,
        onDelete: KeyAction.setNull,
      )();

  TextColumn get responderPubkey => text()();

  /// Shamir fragment plaintext (SQLCipher-protected). Empty when denied.
  TextColumn get sharePayload => text()();

  IntColumn get shareDistributionVersion => integer()();
  IntColumn get receivedAt => integer()();
  TextColumn get nostrEventId => text().nullable()();
  TextColumn get replyingToEventId => text().nullable()();

  BoolColumn get approved => boolean()();
  IntColumn get respondedAtMs => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
