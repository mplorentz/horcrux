import 'package:drift/drift.dart';

import 'vaults.dart';

/// In-flight or historical recovery session for a vault.
@DataClassName('RecoveryRequestRow')
class RecoveryRequests extends Table {
  TextColumn get id => text()();
  TextColumn get vaultId => text().references(
        Vaults,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Nostr id of the inner recovery request rumor (nullable until sent).
  TextColumn get requestEventId => text().nullable()();
  TextColumn get initiatorPubkey => text()();

  /// Local clock (ms since epoch) when the session started.
  IntColumn get startedAt => integer()();
  IntColumn get expiresAt => integer().nullable()();
  IntColumn get cancelledAt => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();

  IntColumn get distributionVersionAtStart => integer()();
  IntColumn get thresholdAtStart => integer()();

  /// [RecoveryRequestStatus.name]
  TextColumn get status => text()();
  BoolColumn get isPractice => boolean().withDefault(const Constant(false))();
  TextColumn get errorMessage => text().nullable()();

  /// Wire `created_at` of inner event (ms UTC) for notification policy only.
  IntColumn get eventCreationTimeMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
