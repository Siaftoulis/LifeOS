import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../core/general_engine/engine_repository.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';

class CHTMStatsView extends StatelessWidget {
  const CHTMStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: EngineRepository.instance.allEntities,
      builder: (context, entities, child) {
        final tasks = EngineRepository.instance.tasks;
        final habits = EngineRepository.instance.habits;
        final events = EngineRepository.instance.events;

        final completedTasks = tasks.where((t) => t.payload['status'] == 'completed').length;
        final totalTasks = tasks.length;
        final taskCompletionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

        final activeHabits = habits.length;
        final completedHabitsToday = habits.where((h) => h.payload['status'] == 'completed').length;
        final habitCompletionRate = activeHabits > 0 ? (completedHabitsToday / activeHabits) : 0.0;

        int totalXpEarned = 0;
        for (var t in tasks) {
          if (t.payload['status'] == 'completed') {
            totalXpEarned += (t.payload['base_xp'] as int? ?? 10);
          }
        }
        for (var h in habits) {
          if (h.payload['status'] == 'completed') {
            totalXpEarned += (h.payload['base_xp'] as int? ?? 10);
          }
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EverforestColors.bg1,
                      EverforestColors.bg2.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: EverforestColors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Productivity XP',
                          style: TextStyle(
                            color: EverforestColors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.bolt, color: EverforestColors.yellow, size: 28),
                            const SizedBox(width: 4),
                            Text(
                              '$totalXpEarned XP',
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: EverforestColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: EverforestColors.green),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Active Habits',
                            style: TextStyle(color: EverforestColors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$completedHabitsToday / $activeHabits Today',
                            style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Progress Rings / Cards
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Task Rate',
                      value: '${(taskCompletionRate * 100).toInt()}%',
                      subtitle: '$completedTasks of $totalTasks done',
                      progress: taskCompletionRate,
                      color: EverforestColors.blue,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Habit Sync',
                      value: '${(habitCompletionRate * 100).toInt()}%',
                      subtitle: '$completedHabitsToday of $activeHabits checked',
                      progress: habitCompletionRate,
                      color: EverforestColors.orange,
                      icon: Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detailed Breakdowns
              _buildSectionTitle('CHTM Breakdown'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EverforestColors.bg1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EverforestColors.bg2),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Calendar Events Scheduled', '${events.length}', EverforestColors.purple, Icons.calendar_month),
                    const Divider(color: EverforestColors.bg2, height: 24),
                    _buildStatRow('Pending Tasks', '${totalTasks - completedTasks}', EverforestColors.yellow, Icons.pending_actions),
                    const Divider(color: EverforestColors.bg2, height: 24),
                    _buildStatRow('Total Habits Tracked', '$activeHabits', EverforestColors.aqua, Icons.track_changes),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Weekly streaks + missed habits (from Drift logs)
              const _HabitStreaksSection(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: EverforestColors.fg,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: EverforestColors.grey,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: EverforestColors.bg2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String count, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: EverforestColors.fg,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Weekly streaks + missed-today tracking for tracked habits (Drift logs).
class _HabitStreaksSection extends StatelessWidget {
  const _HabitStreaksSection();

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
                _buildMissedToday(habits, logs),
                const SizedBox(height: 16),
                _buildStreakCard(habits, logs),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMissedToday(List<UserHabit> habits, List<HabitLog> logs) {
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
                              color: EverforestColors.red.withValues(alpha: 0.15),
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

  Widget _buildStreakCard(List<UserHabit> habits, List<HabitLog> logs) {
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
              final dayLogs = days
                  .map((day) => _logOn(habitLogs, day))
                  .toList();
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

  HabitLog? _logOn(List<HabitLog> logs, DateTime day) {
    for (final l in logs) {
      final d = DateTime.fromMillisecondsSinceEpoch(l.checkinDate);
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        return l;
      }
    }
    return null;
  }

  /// Mirrors ChtmDao.calculateStreak, computed synchronously from all logs.
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
}