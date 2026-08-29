import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';
import 'tables.dart';

part 'chtm_dao.g.dart';

@DriftAccessor(tables: [CalendarEvents, UserTasks, UserHabits, HabitLogs, Quests, QuestLogs])
class ChtmDao extends DatabaseAccessor<AppDatabase> with _$ChtmDaoMixin {
  ChtmDao(AppDatabase db) : super(db);

  Stream<List<CalendarEvent>> watchAllEvents() => select(calendarEvents).watch();
  Stream<List<UserTask>> watchAllTasks() => select(userTasks).watch();
  Stream<List<UserHabit>> watchAllHabits() => select(userHabits).watch();
  Stream<List<HabitLog>> watchAllHabitLogs() => select(habitLogs).watch();
  Stream<List<HabitLog>> watchHabitLogs(String habitId) =>
      (select(habitLogs)..where((t) => t.habitId.equals(habitId))).watch();

  Future<int> insertHabit(UserHabitsCompanion entry) => into(userHabits).insert(entry);
  Future<int> insertHabitLog(HabitLogsCompanion entry) => into(habitLogs).insert(entry);
  Future<bool> updateHabit(UserHabitsCompanion entry) => update(userHabits).replace(entry);
  Future<int> deleteHabit(String id) => (delete(userHabits)..where((t) => t.id.equals(id))).go();

  // Quests
  Stream<List<Quest>> watchAllQuests() => select(quests).watch();
  Stream<List<Quest>> watchQuestsByStatus(String status) =>
      (select(quests)..where((t) => t.status.equals(status))).watch();
  Stream<List<Quest>> watchQuestsByAssignee(String assignee) =>
      (select(quests)..where((t) => t.assignedTo.equals(assignee))).watch();

  Future<int> insertQuest(QuestsCompanion entry) => into(quests).insert(entry);
  Future<bool> updateQuest(QuestsCompanion entry) => update(quests).replace(entry);
  Future<int> deleteQuest(String id) => (delete(quests)..where((t) => t.id.equals(id))).go();

  Future<int> insertQuestLog(QuestLogsCompanion entry) => into(questLogs).insert(entry);

  Future<int> acceptQuest(String questId, String userId) async {
    return await transaction(() async {
      await (update(quests)..where((t) => t.id.equals(questId)))
          .write(QuestsCompanion(status: Value('ACCEPTED'), updatedAt: Value(DateTime.now().millisecondsSinceEpoch), isDirty: const Value(1)));
      await into(questLogs).insert(QuestLogsCompanion.insert(
        id: const Uuid().v4(),
        questId: questId,
        action: 'ACCEPTED',
        userId: userId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isDirty: const Value(1),
      ));
      return 1;
    });
  }

  Future<int> denyQuest(String questId, String userId) async {
    return await transaction(() async {
      await (update(quests)..where((t) => t.id.equals(questId)))
          .write(QuestsCompanion(status: Value('REJECTED'), updatedAt: Value(DateTime.now().millisecondsSinceEpoch), isDirty: const Value(1)));
      await into(questLogs).insert(QuestLogsCompanion.insert(
        id: const Uuid().v4(),
        questId: questId,
        action: 'DENIED',
        userId: userId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isDirty: const Value(1),
      ));
      return 1;
    });
  }

  Future<int> claimQuest(String questId, String userId) async {
    return await transaction(() async {
      await (update(quests)..where((t) => t.id.equals(questId)))
          .write(QuestsCompanion(assignedTo: Value(userId), status: Value('ACCEPTED'), updatedAt: Value(DateTime.now().millisecondsSinceEpoch), isDirty: const Value(1)));
      await into(questLogs).insert(QuestLogsCompanion.insert(
        id: const Uuid().v4(),
        questId: questId,
        action: 'CLAIMED',
        userId: userId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isDirty: const Value(1),
      ));
      return 1;
    });
  }

  Future<int> completeQuest(String questId, String userId) async {
    return await transaction(() async {
      await (update(quests)..where((t) => t.id.equals(questId)))
          .write(QuestsCompanion(status: Value('COMPLETED'), updatedAt: Value(DateTime.now().millisecondsSinceEpoch), isDirty: const Value(1)));
      await into(questLogs).insert(QuestLogsCompanion.insert(
        id: const Uuid().v4(),
        questId: questId,
        action: 'COMPLETED',
        userId: userId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isDirty: const Value(1),
      ));
      return 1;
    });
  }

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

  /// Get today's completed value for a habit (for STEPS/DISTANCE progress)
  Future<double> getTodayProgress(String habitId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayEnd = todayStart + 86400000;

    final log = await (select(habitLogs)
      ..where((t) => t.habitId.equals(habitId) & 
                       t.checkinDate.isBiggerOrEqualValue(todayStart) & 
                       t.checkinDate.isSmallerThanValue(todayEnd))
      ..orderBy([(t) => OrderingTerm.desc(t.checkinDate)]))
      .getSingleOrNull();

    return log?.completedValue ?? 0.0;
  }
}