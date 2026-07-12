import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';
import '../../../../api_client.dart';
import 'chtm_create_dialog.dart';

class CHTMDailyList extends StatelessWidget {
  final ChtmDao dao;
  final DateTime selectedDate;

  const CHTMDailyList({
    super.key,
    required this.dao,
    required this.selectedDate,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return EverforestColors.blue;
    try {
      final code = hex.replaceAll('#', '');
      return Color(int.parse('FF$code', radix: 16));
    } catch (_) {
      return EverforestColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CalendarEvent>>(
      stream: dao.watchAllEvents(),
      builder: (context, eventSnapshot) {
        return StreamBuilder<List<UserTask>>(
          stream: dao.watchAllTasks(),
          builder: (context, taskSnapshot) {
            return StreamBuilder<List<UserHabit>>(
              stream: dao.watchAllHabits(),
              builder: (context, habitSnapshot) {
                return StreamBuilder<List<HabitLog>>(
                  stream: dao.watchAllHabitLogs(),
                  builder: (context, logSnapshot) {
                    if (!eventSnapshot.hasData ||
                        !taskSnapshot.hasData ||
                        !habitSnapshot.hasData ||
                        !logSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
                    }

                    final events = eventSnapshot.data!;
                    final tasks = taskSnapshot.data!;
                    final habits = habitSnapshot.data!;
                    final logs = logSnapshot.data!;

                    // 1. Filter Calendar Events for the selected date
                    final List<CalendarEvent> dailyEvents = events.where((e) {
                      final start = DateTime.fromMillisecondsSinceEpoch(e.startTime);
                      return start.year == selectedDate.year &&
                          start.month == selectedDate.month &&
                          start.day == selectedDate.day;
                    }).toList();
                    dailyEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

                    // 2. Filter Tasks for the selected date
                    final List<UserTask> dailyTasks = tasks.where((t) {
                      if (t.dueDate == null) return true; // Show anytime tasks
                      final dt = DateTime.fromMillisecondsSinceEpoch(t.dueDate!);
                      return dt.year == selectedDate.year &&
                          dt.month == selectedDate.month &&
                          dt.day == selectedDate.day;
                    }).toList();

                    // 3. Prepare Checklist Items (Habits & Tasks)
                    final List<DailyItem> checklistItems = [];

                    // Add Habits
                    for (final habit in habits) {
                      final hasLogToday = logs.any((l) {
                        if (l.habitId != habit.id) return false;
                        final checkin = DateTime.fromMillisecondsSinceEpoch(l.checkinDate);
                        return checkin.year == selectedDate.year &&
                            checkin.month == selectedDate.month &&
                            checkin.day == selectedDate.day;
                      });

                      checklistItems.add(DailyItem(
                        id: habit.id,
                        title: habit.name,
                        subtitle: 'Streak: ${habit.targetStreak} target',
                        isCompleted: hasLogToday,
                        color: EverforestColors.orange,
                        icon: Icons.local_fire_department,
                        onToggle: () async {
                          if (!hasLogToday) {
                            await dao.insertHabitLog(HabitLogsCompanion.insert(
                              id: const Uuid().v4(),
                              habitId: habit.id,
                              checkinDate: selectedDate.millisecondsSinceEpoch,
                              pointsAwarded: habit.baseXp,
                            ));

                            try {
                              await ApiClient.instance.postDaemon('/api/v1/player/task/complete', {
                                'task_id': 'habit_${habit.id}',
                                'attribute': habit.attribute ?? 'willpower',
                                'base_xp': habit.baseXp,
                                'base_points': 10,
                                'is_sick': false,
                              });
                            } catch (e) {
                              debugPrint('Failed to sync habit reward: $e');
                            }
                          } else {
                            // Delete check-in log
                            await (dao.delete(dao.habitLogs)
                                  ..where((t) => t.habitId.equals(habit.id))
                                  ..where((t) => t.checkinDate.equals(selectedDate.millisecondsSinceEpoch)))
                                .go();
                          }
                        },
                      ));
                    }

                    // Add Tasks
                    for (final task in dailyTasks) {
                      final isDone = task.status == 'DONE';

                      checklistItems.add(DailyItem(
                        id: task.id,
                        title: task.title,
                        subtitle: task.dueDate != null
                            ? 'Due: ${DateTime.fromMillisecondsSinceEpoch(task.dueDate!).hour}:${DateTime.fromMillisecondsSinceEpoch(task.dueDate!).minute.toString().padLeft(2, '0')}'
                            : 'Anytime',
                        isCompleted: isDone,
                        color: EverforestColors.blue,
                        icon: Icons.assignment_turned_in,
                        onToggle: () async {
                          if (!isDone) {
                            await (dao.update(dao.userTasks)..where((t) => t.id.equals(task.id))).write(
                              UserTasksCompanion(
                                status: const drift.Value('DONE'),
                                completedAt: drift.Value(selectedDate.millisecondsSinceEpoch),
                                updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
                              ),
                            );

                            try {
                              await ApiClient.instance.postDaemon('/api/v1/player/task/complete', {
                                'task_id': task.id,
                                'attribute': task.attribute ?? 'focus',
                                'base_xp': task.baseXp,
                                'base_points': 5,
                                'is_sick': false,
                              });
                            } catch (e) {
                              debugPrint('Failed to sync task reward: $e');
                            }
                          } else {
                            // Revert to TODO
                            await (dao.update(dao.userTasks)..where((t) => t.id.equals(task.id))).write(
                              UserTasksCompanion(
                                status: const drift.Value('TODO'),
                                completedAt: const drift.Value(null),
                                updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
                              ),
                            );
                          }
                        },
                      ));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- CALENDAR EVENTS (SCHEDULE) SECTION ---
                        if (dailyEvents.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Text(
                              'SCHEDULE',
                              style: TextStyle(color: EverforestColors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                          ...dailyEvents.map((event) {
                            final startTime = DateTime.fromMillisecondsSinceEpoch(event.startTime);
                            final endTime = DateTime.fromMillisecondsSinceEpoch(event.endTime);
                            final timeStr = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
                            final color = _parseColor(event.colorCode);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: EverforestColors.bg1,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: EverforestColors.bg2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(width: 6, color: color),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.title,
                                                style: const TextStyle(
                                                  color: EverforestColors.fg,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time, color: EverforestColors.grey, size: 14),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    timeStr,
                                                    style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],

                        // --- DAILY CHECKLIST (TASKS & HABITS) ---
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            'CHECKLIST',
                            style: TextStyle(color: EverforestColors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        if (checklistItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No tasks or habits for today.',
                                style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                              ),
                            ),
                          )
                        else
                          ...checklistItems.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: EverforestColors.bg1,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: item.isCompleted
                                      ? item.color.withValues(alpha: 0.4)
                                      : EverforestColors.bg2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: item.onToggle,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: item.isCompleted ? item.color : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: item.isCompleted ? item.color : EverforestColors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child: item.isCompleted
                                          ? const Icon(Icons.check, color: EverforestColors.bg0, size: 18)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: item.isCompleted
                                                ? EverforestColors.grey
                                                : EverforestColors.fg,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            decoration: item.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        if (item.subtitle != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(item.icon, color: item.color, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.subtitle!,
                                                style: const TextStyle(
                                                  color: EverforestColors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 24),
                        // --- QUICK ADD BUTTON ---
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => CHTMCreateDialog(
                                dao: dao,
                                selectedDate: selectedDate,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Agenda Item', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: EverforestColors.green,
                            side: const BorderSide(color: EverforestColors.green, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class DailyItem {
  final String id;
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final Color color;
  final IconData icon;
  final VoidCallback onToggle;

  DailyItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.isCompleted,
    required this.color,
    required this.icon,
    required this.onToggle,
  });
}
