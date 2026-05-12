import 'package:drift/drift.dart';

/// Last consent snapshot synced to horcrux-notifier.
@DataClassName('SyncedConsentRow')
class SyncedConsents extends Table {
  TextColumn get consentId => text()();
  TextColumn get payload => text()();
  IntColumn get syncedAt => integer()();

  @override
  Set<Column> get primaryKey => {consentId};
}
