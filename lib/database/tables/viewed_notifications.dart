import 'package:drift/drift.dart';

/// Recovery request notifications the user has marked as viewed.
@DataClassName('ViewedNotificationRow')
class ViewedNotifications extends Table {
  TextColumn get notificationId => text()();
  IntColumn get viewedAt => integer()();

  @override
  Set<Column> get primaryKey => {notificationId};
}
