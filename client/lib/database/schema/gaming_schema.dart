import 'package:drift/drift.dart';

@DataClassName('Quest')
class Quests extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get rewardPoints => integer().withDefault(const Constant(0))();
  TextColumn get assignedTo => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, ACCEPTED, REJECTED, COMPLETED
  TextColumn get createdBy => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('QuestLog')
class QuestLogs extends Table {
  TextColumn get id => text()();
  TextColumn get questId => text().customConstraint('NOT NULL REFERENCES quests(id) ON DELETE CASCADE')();
  TextColumn get action => text()(); // 'ACCEPTED', 'DENIED', 'COMPLETED'
  TextColumn get userId => text()();
  IntColumn get timestamp => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

