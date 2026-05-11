import 'package:drift/drift.dart';

/// Generic singleton-style key/value storage for app-scoped state.
@DataClassName('KvRow')
class Kv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
