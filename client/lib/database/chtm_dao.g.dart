// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chtm_dao.dart';

// ignore_for_file: type=lint
mixin _$ChtmDaoMixin on DatabaseAccessor<AppDatabase> {
  $CalendarEventsTable get calendarEvents => attachedDatabase.calendarEvents;
  $UserTasksTable get userTasks => attachedDatabase.userTasks;
  $UserHabitsTable get userHabits => attachedDatabase.userHabits;
  $HabitLogsTable get habitLogs => attachedDatabase.habitLogs;
  $QuestsTable get quests => attachedDatabase.quests;
  $QuestLogsTable get questLogs => attachedDatabase.questLogs;
  ChtmDaoManager get managers => ChtmDaoManager(this);
}

class ChtmDaoManager {
  final _$ChtmDaoMixin _db;
  ChtmDaoManager(this._db);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(
          _db.attachedDatabase, _db.calendarEvents);
  $$UserTasksTableTableManager get userTasks =>
      $$UserTasksTableTableManager(_db.attachedDatabase, _db.userTasks);
  $$UserHabitsTableTableManager get userHabits =>
      $$UserHabitsTableTableManager(_db.attachedDatabase, _db.userHabits);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db.attachedDatabase, _db.habitLogs);
  $$QuestsTableTableManager get quests =>
      $$QuestsTableTableManager(_db.attachedDatabase, _db.quests);
  $$QuestLogsTableTableManager get questLogs =>
      $$QuestLogsTableTableManager(_db.attachedDatabase, _db.questLogs);
}
