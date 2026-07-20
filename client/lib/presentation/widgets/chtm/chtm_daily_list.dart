import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../core/general_engine/engine_repository.dart';
import '../../../core/general_engine/general_engine_client.dart';
// import 'chtm_create_dialog.dart';

class CHTMDailyList extends StatelessWidget {
  final DateTime selectedDate;

  const CHTMDailyList({
    super.key,
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
    return ValueListenableBuilder<List<GeneralEngineEntity>>(
      valueListenable: EngineRepository.instance.allEntities,
      builder: (context, entities, child) {
        if (entities.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
        }

        final events = EngineRepository.instance.events;
        final tasks = EngineRepository.instance.tasks;
        final habits = EngineRepository.instance.habits;

        // 1. Filter Calendar Events for the selected date
        final List<GeneralEngineEntity> dailyEvents = events.where((e) {
          final start = DateTime.tryParse(e.payload['start_time'] ?? '') ?? DateTime.now();
          return start.year == selectedDate.year &&
              start.month == selectedDate.month &&
              start.day == selectedDate.day;
        }).toList();
        
        // 2. Filter Tasks for the selected date
        final List<GeneralEngineEntity> dailyTasks = tasks.where((t) {
          if (t.payload['due_date'] == null) return true;
          final dt = DateTime.tryParse(t.payload['due_date']) ?? DateTime.now();
          return dt.year == selectedDate.year &&
              dt.month == selectedDate.month &&
              dt.day == selectedDate.day;
        }).toList();

        // 3. Prepare Checklist Items (Habits & Tasks)
        final List<DailyItem> checklistItems = [];

        // Add Habits
        for (final habit in habits) {
          final isCompleted = habit.payload['status'] == 'completed';
          final sharedInfo = habit.sharedWith.isNotEmpty ? ' • Shared (${habit.sharedWith.join(', ')})' : '';
          final assignedInfo = habit.assignedTo != null ? ' • Assigned to: ${habit.assignedTo}' : '';
          
          checklistItems.add(DailyItem(
            id: habit.id,
            title: habit.payload['name'] ?? 'Unknown Habit',
            subtitle: 'Streak: ${habit.payload['target_streak'] ?? 0} target$sharedInfo$assignedInfo',
            isCompleted: isCompleted,
            color: EverforestColors.orange,
            icon: Icons.local_fire_department,
            onToggle: () async {
              final updatedPayload = Map<String, dynamic>.from(habit.payload);
              updatedPayload['status'] = isCompleted ? 'todo' : 'completed';
              
              final updatedEntity = GeneralEngineEntity(
                id: habit.id,
                type: habit.type,
                creatorId: habit.creatorId,
                payload: updatedPayload,
                sharedWith: habit.sharedWith,
                assignedTo: habit.assignedTo,
                createdAt: habit.createdAt,
                updatedAt: DateTime.now(),
              );
              await EngineRepository.instance.saveEntity(updatedEntity);
            },
          ));
        }

        // Add Tasks
        for (final task in dailyTasks) {
          final isDone = task.payload['status'] == 'completed';
          final sharedInfo = task.sharedWith.isNotEmpty ? ' • Shared (${task.sharedWith.join(', ')})' : '';
          final assignedInfo = task.assignedTo != null ? ' • Assigned to: ${task.assignedTo}' : '';

          checklistItems.add(DailyItem(
            id: task.id,
            title: task.payload['title'] ?? 'Unknown Task',
            subtitle: 'Engine Task$sharedInfo$assignedInfo',
            isCompleted: isDone,
            color: EverforestColors.blue,
            icon: Icons.assignment_turned_in,
            onToggle: () async {
              final updatedPayload = Map<String, dynamic>.from(task.payload);
              updatedPayload['status'] = isDone ? 'todo' : 'completed';
              
              final updatedEntity = GeneralEngineEntity(
                id: task.id,
                type: task.type,
                creatorId: task.creatorId,
                payload: updatedPayload,
                sharedWith: task.sharedWith,
                assignedTo: task.assignedTo,
                createdAt: task.createdAt,
                updatedAt: DateTime.now(),
              );
              await EngineRepository.instance.saveEntity(updatedEntity);
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
                final startTime = DateTime.tryParse(event.payload['start_time'] ?? '') ?? DateTime.now();
                final endTime = DateTime.tryParse(event.payload['end_time'] ?? '') ?? DateTime.now();
                final timeStr = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
                final color = _parseColor(event.payload['color_code']);

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
                                    event.payload['title'] ?? 'No Title',
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
                                      if (event.sharedWith.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        const Icon(Icons.group, color: EverforestColors.green, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Shared: ${event.sharedWith.join(', ')}',
                                          style: const TextStyle(color: EverforestColors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
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
                'CHECKLIST (GENERAL ENGINE)',
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
          ],
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
