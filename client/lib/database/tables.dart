import 'package:drift/drift.dart';

class LifeEntities extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  
  // Mandatory tracking fields
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get syncedAt => integer().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  TextColumn get fieldName => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  
  // Synchronization markers
  IntColumn get clientUpdatedAt => integer()();
  IntColumn get syncedState => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {id};
}
