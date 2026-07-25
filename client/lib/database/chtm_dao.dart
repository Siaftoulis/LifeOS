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
  Stream<List<HabitLog>> watchAllHabitLogs() => select(habitLogs).watch();
  Stream<List<HabitLog>> watchHabitLogs(String habitId) =>
      (select(habitLogs)..where((t) => t.habitId.equals(habitId))).watch();

  Future<int> insertTask(UserTasksCompanion entry) => into(userTasks).insert(entry);
  Future<bool> updateTask(UserTasksCompanion entry) => update(userTasks).replace(entry);
  Future<int> deleteTask(String id) => (delete(userTasks)..where((t) => t.id.equals(id))).go();

  Future<int> insertHabit(UserHabitsCompanion entry) => into(userHabits).insert(entry);
  Future<int> insertHabitLog(HabitLogsCompanion entry) => into(habitLogs).insert(entry);

  Future<int> calculateStreak(String habitId) async {
    final logs = await (select(habitLogs)
      ..where((t) => t.habitId.equals(habitId))
      ..orderBy([(t) => OrderingTerm.desc(t.checkinDate)]))
        .get();

    if (logs.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    Set<String> checkinDays = {};
    for (var log in logs) {
      final dt = DateTime.fromMillisecondsSinceEpoch(log.checkinDate);
      final dayStr = '${dt.year}-${dt.month}-${dt.day}';
      checkinDays.add(dayStr);
    }

    while (true) {
      final dayStr = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (checkinDays.contains(dayStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // If today hasn't been checked in yet, check yesterday to continue streak
        if (streak == 0) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          final yesterdayStr = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
          if (checkinDays.contains(yesterdayStr)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
            continue;
          }
        }
        break;
      }
    }
    return streak;
  }
}
