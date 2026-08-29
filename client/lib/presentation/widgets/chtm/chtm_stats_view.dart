import 'package:flutter/material.dart';
import '../../../core/general_engine/engine_repository.dart';
import '../../../theme/everforest_colors.dart';
import 'stats/habit_streaks_section.dart';
import 'stats/stats_kpi_card.dart';

export 'stats/habit_streaks_section.dart';
export 'stats/stats_kpi_card.dart';

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

        final completedTasks =
            tasks.where((t) => t.payload['status'] == 'completed').length;
        final totalTasks = tasks.length;
        final taskCompletionRate =
            totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

        final activeHabits = habits.length;
        final completedHabitsToday =
            habits.where((h) => h.payload['status'] == 'completed').length;
        final habitCompletionRate =
            activeHabits > 0 ? (completedHabitsToday / activeHabits) : 0.0;

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
                  border: Border.all(
                      color: EverforestColors.green.withValues(alpha: 0.3)),
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
                            const Icon(Icons.bolt,
                                color: EverforestColors.yellow, size: 28),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: EverforestColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: EverforestColors.green),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Active Habits',
                            style: TextStyle(
                                color: EverforestColors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$completedHabitsToday / $activeHabits Today',
                            style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Progress Cards
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
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
                    child: KpiCard(
                      title: 'Habit Sync',
                      value: '${(habitCompletionRate * 100).toInt()}%',
                      subtitle:
                          '$completedHabitsToday of $activeHabits checked',
                      progress: habitCompletionRate,
                      color: EverforestColors.orange,
                      icon: Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detailed Breakdowns
              const Text(
                'CHTM Breakdown',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    StatRow(
                      label: 'Calendar Events Scheduled',
                      count: '${events.length}',
                      color: EverforestColors.purple,
                      icon: Icons.calendar_month,
                    ),
                    const Divider(color: EverforestColors.bg2, height: 24),
                    StatRow(
                      label: 'Pending Tasks',
                      count: '${totalTasks - completedTasks}',
                      color: EverforestColors.yellow,
                      icon: Icons.pending_actions,
                    ),
                    const Divider(color: EverforestColors.bg2, height: 24),
                    StatRow(
                      label: 'Total Habits Tracked',
                      count: '$activeHabits',
                      color: EverforestColors.aqua,
                      icon: Icons.track_changes,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Weekly streaks + missed habits (from Drift logs)
              const HabitStreaksSection(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}