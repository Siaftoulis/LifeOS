import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

class CHTMHabitList extends StatelessWidget {
  final ChtmDao dao;
  final Stream<List<UserHabit>> habitsStream;

  const CHTMHabitList({super.key, required this.dao, required this.habitsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserHabit>>(
      stream: habitsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final habits = snapshot.data!;
        
        return ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            
            return StreamBuilder<List<HabitLog>>(
              stream: dao.watchHabitLogs(habit.id),
              builder: (context, logSnapshot) {
                final logs = logSnapshot.data ?? [];
                
                final now = DateTime.now();
                // Simple check for if done today
                final isDone = logs.any((l) {
                  final checkin = DateTime.fromMillisecondsSinceEpoch(l.checkinDate);
                  return checkin.year == now.year && checkin.month == now.month && checkin.day == now.day;
                });
                
                final color = isDone ? EverforestColors.green : EverforestColors.orange; // simplified

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDone ? color.withOpacity(0.5) : EverforestColors.bg2),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (!isDone) {
                            await dao.insertHabitLog(HabitLogsCompanion.insert(
                              id: const Uuid().v4(),
                              habitId: habit.id,
                              checkinDate: DateTime.now().millisecondsSinceEpoch,
                              pointsAwarded: habit.baseXp,
                            ));
                            // the dao insertHabitLog will handle backend sync (Workstream G)
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone ? color : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDone ? color : EverforestColors.grey, width: 2),
                          ),
                          child: isDone ? const Icon(Icons.check, color: EverforestColors.bg0, size: 18) : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: TextStyle(
                                color: isDone ? EverforestColors.fg : EverforestColors.fg.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                decorationColor: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.local_fire_department, color: color, size: 14),
                                const SizedBox(width: 4),
                                Text('${habit.targetStreak} target', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        );
      },
    );
  }
}
