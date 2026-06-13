import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'chtm_dao.g.dart';

@DriftAccessor(tables: [CalendarEvents, UserTasks, UserHabits, HabitLogs])
class ChtmDao extends DatabaseAccessor<AppDatabase> with _$ChtmDaoMixin {
  ChtmDao(AppDatabase db) : super(db);

  Stream<List<CalendarEvent>> watchAllEvents() => select(calendarEvents).watch();
  Stream<List<UserTask>> watchAllTasks() => select(userTasks).watch();
  Stream<List<UserHabit>> watchAllHabits() => select(userHabits).watch();
  Stream<List<HabitLog>> watchHabitLogs(String habitId) =>
      (select(habitLogs)..where((t) => t.habitId.equals(habitId))).watch();

  Future<int> insertTask(UserTasksCompanion entry) => into(userTasks).insert(entry);
  Future<bool> updateTask(UserTasksCompanion entry) => update(userTasks).replace(entry);
  Future<int> deleteTask(String id) => (delete(userTasks)..where((t) => t.id.equals(id))).go();

  Future<int> insertHabit(UserHabitsCompanion entry) => into(userHabits).insert(entry);
  Future<int> insertHabitLog(HabitLogsCompanion entry) => into(habitLogs).insert(entry);
}
