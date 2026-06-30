import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

class QuestDailyList extends StatelessWidget {
  final ChtmDao dao;
  final Stream<List<UserHabit>> habitsStream;
  final Stream<List<UserTask>> tasksStream;

  const QuestDailyList({super.key, required this.dao, required this.habitsStream, required this.tasksStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserHabit>>(
      stream: habitsStream,
      builder: (context, habitSnapshot) {
        return StreamBuilder<List<UserTask>>(
          stream: tasksStream,
          builder: (context, taskSnapshot) {
            final habits = habitSnapshot.data ?? [];
            final tasks = taskSnapshot.data ?? [];
            
            // Generate Quests:
            // 1. Unchecked habits today
            // 2. Overdue tasks
            
            final List<Widget> questWidgets = [];
            
            for (var habit in habits) {
               questWidgets.add(_buildQuestItem(habit.name, '+${habit.baseXp} XP', false, () async {
                   await dao.insertHabitLog(HabitLogsCompanion.insert(
                     id: const Uuid().v4(),
                     habitId: habit.id,
                     checkinDate: DateTime.now().millisecondsSinceEpoch,
                     pointsAwarded: habit.baseXp,
                   ));
               }));
            }
            
            for (var task in tasks) {
              if (task.status != 'DONE') {
                questWidgets.add(_buildQuestItem(task.title, '+${task.baseXp} XP', false, () async {
                   await dao.updateTask(
                     UserTasksCompanion(
                       id: drift.Value(task.id),
                       status: const drift.Value('DONE'),
                       completedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
                       updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
                     )
                   );
                }));
              }
            }
            
            if (questWidgets.isEmpty) {
               return const Center(child: Text("All quests completed for today!", style: TextStyle(color: EverforestColors.grey)));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('DAILY QUESTS', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),
                ...questWidgets,
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildQuestItem(String title, String reward, bool isCompleted, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isCompleted ? EverforestColors.fg : EverforestColors.grey, width: 1.5),
              ),
              child: isCompleted ? const Icon(Icons.check, size: 16, color: EverforestColors.fg) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isCompleted ? EverforestColors.grey : EverforestColors.fg,
                  fontSize: 15,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              reward,
              style: TextStyle(
                color: isCompleted ? EverforestColors.grey : EverforestColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
