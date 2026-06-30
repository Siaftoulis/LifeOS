import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';
import 'package:drift/drift.dart' as drift;

class CHTMTaskTimeline extends StatelessWidget {
  final ChtmDao dao;
  final Stream<List<UserTask>> tasksStream;

  const CHTMTaskTimeline({super.key, required this.dao, required this.tasksStream});

  @override
  Widget build(BuildContext context) {
    Color getTypeColor(String? type) {
      switch (type) {
        case 'intelligence': return EverforestColors.blue;
        case 'stamina': return EverforestColors.red;
        case 'focus': return EverforestColors.purple;
        default: return EverforestColors.green;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: StreamBuilder<List<UserTask>>(
        stream: tasksStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final tasks = snapshot.data!;
          if (tasks.isEmpty) return const Center(child: Text("No tasks in ledger.", style: TextStyle(color: EverforestColors.grey)));

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final color = getTypeColor(task.attribute);
              final isDone = task.status == 'DONE';

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        task.dueDate != null ? "${DateTime.fromMillisecondsSinceEpoch(task.dueDate!).hour}:${DateTime.fromMillisecondsSinceEpoch(task.dueDate!).minute.toString().padLeft(2, '0')}" : 'Anytime',
                        style: const TextStyle(color: EverforestColors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        if (index < tasks.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: EverforestColors.bg2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          )
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                           if (!isDone) {
                             await dao.updateTask(
                               UserTasksCompanion(
                                 id: drift.Value(task.id),
                                 status: const drift.Value('DONE'),
                                 completedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
                                 updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
                               )
                             );
                             // updateTask in dao will handle the backend sync later
                           }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDone ? EverforestColors.bg2 : EverforestColors.bg0,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EverforestColors.bg2),
                          ),
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: isDone ? EverforestColors.grey : EverforestColors.fg, 
                              fontSize: 15, 
                              fontWeight: FontWeight.w600,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
