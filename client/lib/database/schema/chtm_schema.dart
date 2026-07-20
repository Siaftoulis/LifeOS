import 'package:drift/drift.dart';

@DataClassName('CalendarEvent')
class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer()();
  TextColumn get colorCode => text().withDefault(const Constant('#89B4FA'))();
  IntColumn get isShared => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserTask')
class UserTasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('TODO'))();
  TextColumn get attribute => text().nullable()();
  IntColumn get baseXp => integer().withDefault(const Constant(10))();
  IntColumn get dueDate => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserHabit')
class UserHabits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get frequencyCron => text()();
  IntColumn get targetStreak => integer().withDefault(const Constant(0))();
  TextColumn get attribute => text().nullable()();
  IntColumn get baseXp => integer().withDefault(const Constant(10))();
  TextColumn get type => text().withDefault(const Constant('CHECK'))(); // CHECK, DISTANCE, STEPS, TIMER, ZEN
  RealColumn get goalValue => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()(); // 'km', 'steps', 'mins'
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HabitLog')
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().customConstraint('NOT NULL REFERENCES user_habits(id) ON DELETE CASCADE')();
  IntColumn get checkinDate => integer()();
  IntColumn get pointsAwarded => integer()();
  RealColumn get completedValue => real().withDefault(const Constant(1.0))();
  TextColumn get status => text().withDefault(const Constant('DONE'))(); // DONE, PARTIAL, FAILED
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PointRule')
class PointRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get module => text()();
  IntColumn get pointsValue => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

