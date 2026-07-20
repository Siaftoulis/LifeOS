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

class SystemSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}

class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get role => text()(); // 'ADMIN', 'NORMAL', 'CHILD'
  TextColumn get familyId => text().nullable()(); // NEW: Link to family group
  IntColumn get dailyLimit => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SystemUser')
class SystemUsers extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get passwordHash => text().nullable()();
  IntColumn get isLocked => integer().withDefault(const Constant(1))();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  IntColumn get currentPoints => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalNotification')
class LocalNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get category => text()(); // 'SYSTEM', 'HABIT', 'SECURITY', 'FINANCIAL'
  IntColumn get readAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

