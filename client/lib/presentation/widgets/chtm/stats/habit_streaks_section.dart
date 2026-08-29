import 'package:flutter/material.dart';
import '../../../../database/chtm_dao.dart';
import '../../../../database/database.dart';
import '../../../../theme/everforest_colors.dart';

class HabitStreaksSection extends StatelessWidget {
  const HabitStreaksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    final dao = ChtmDao(db);
    return StreamBuilder<List<UserHabit>>(
      stream: dao.watchAllHabits(),
      builder: (context, habitSnap) {
        final habits = habitSnap.data ?? [];
        return StreamBuilder<List<HabitLog>>(
          stream: dao.watchAllHabitLogs(),
          builder: (context, logSnap) {
            final logs = logSnap.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MissedTodayCard(habits: habits, logs: logs),
                const SizedBox(height: 16),
                StreakCard(habits: habits, logs: logs),
              ],
            );
          },
        );
      },
    );
  }
}

class MissedTodayCard extends StatelessWidget {
  const MissedTodayCard({
    super.key,
    required this.habits,
    required this.logs,
  });

  final List<UserHabit> habits;
  final List<HabitLog> logs;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final doneToday = logs
        .where((l) => l.checkinDate >= startOfToday && l.status == 'DONE')
        .map((l) => l.habitId)
        .toSet();
    final missed = habits.where((h) => !doneToday.contains(h.id)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: missed.isEmpty
                ? EverforestColors.green.withValues(alpha: 0.4)
                : EverforestColors.red.withValues(alpha: 0.4)),
      ),
      child: missed.isEmpty
          ? const Row(
              children: [
                Icon(Icons.check_circle,
                    color: EverforestColors.green, size: 18),
                SizedBox(width: 10),
                Text('All habits done today',
                    style: TextStyle(
                        color: EverforestColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSED TODAY (${missed.length})',
                  style: const TextStyle(
                      color: EverforestColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: missed
                      .map((h) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  EverforestColors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              h.name,
                              style: const TextStyle(
                                  color: EverforestColors.red, fontSize: 12),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
    );
  }
}

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.habits,
    required this.logs,
  });

  final List<UserHabit> habits;
  final List<HabitLog> logs;

  HabitLog? _logOn(List<HabitLog> logs, DateTime day) {
    for (final l in logs) {
      final d = DateTime.fromMillisecondsSinceEpoch(l.checkinDate);
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        return l;
      }
    }
    return null;
  }

  int _streakOf(List<HabitLog> logs) {
    if (logs.isEmpty) return 0;
    final days = logs
        .map((l) {
          final d = DateTime.fromMillisecondsSinceEpoch(l.checkinDate);
          return '${d.year}-${d.month}-${d.day}';
        })
        .toSet();
    int streak = 0;
    final now = DateTime.now();
    var check = DateTime(now.year, now.month, now.day);
    while (true) {
      final ds = '${check.year}-${check.month}-${check.day}';
      if (days.contains(ds)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        if (streak == 0) {
          check = check.subtract(const Duration(days: 1));
          final ys = '${check.year}-${check.month}-${check.day}';
          if (days.contains(ys)) {
            streak++;
            check = check.subtract(const Duration(days: 1));
            continue;
          }
        }
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKLY STREAKS',
              style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            const Text('No habits tracked yet',
                style: TextStyle(color: EverforestColors.grey))
          else
            ...habits.map((h) {
              final habitLogs =
                  logs.where((l) => l.habitId == h.id).toList();
              final streak = _streakOf(habitLogs);
              final dayLogs =
                  days.map((day) => _logOn(habitLogs, day)).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        h.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: EverforestColors.fg, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: days.asMap().entries.map((entry) {
                          final log = dayLogs[entry.key];
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: log == null
                                  ? EverforestColors.bg2
                                  : (log.status == 'DONE'
                                      ? EverforestColors.green
                                      : EverforestColors.orange),
                            ),
                            child: Center(
                              child: Icon(
                                log == null ? Icons.close : Icons.check,
                                size: 11,
                                color: log == null
                                    ? EverforestColors.grey
                                    : EverforestColors.bg0,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 14,
                            color: streak > 0
                                ? EverforestColors.orange
                                : EverforestColors.grey),
                        const SizedBox(width: 2),
                        Text('$streak',
                            style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
