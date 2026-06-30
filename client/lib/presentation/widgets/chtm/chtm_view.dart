import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';
import 'chtm_calendar_strip.dart';
import 'chtm_habit_list.dart';
import 'chtm_task_timeline.dart';
import 'package:provider/provider.dart';

class CHTMView extends StatelessWidget {
  const CHTMView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final dao = ChtmDao(db);

    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          CHTMCalendarStrip(eventsStream: dao.watchAllEvents()),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Habits', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(child: CHTMHabitList(dao: dao, habitsStream: dao.watchAllHabits())),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time Ledger', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(child: CHTMTaskTimeline(dao: dao, tasksStream: dao.watchAllTasks())),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]}, ${now.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendar & Habits',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                color: EverforestColors.green,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EverforestColors.bg2),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.mic, color: EverforestColors.blue),
                onPressed: () {},
                tooltip: 'Voice Note',
              ),
              Container(width: 1, height: 24, color: EverforestColors.bg2),
              IconButton(
                icon: const Icon(Icons.add_task, color: EverforestColors.green),
                onPressed: () {},
                tooltip: 'Add Task',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
