import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../database/tasks_extension.dart';
import '../../api_client.dart';

class TasksGrid extends StatefulWidget {
  const TasksGrid({super.key});
  @override State<TasksGrid> createState() => _TasksGridState();
}

class _TasksGridState extends State<TasksGrid> {
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: StreamBuilder<List<TaskData>>(
        stream: AppDatabase.instance.watchAllTasks(),
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)));
          final tasks = s.data ?? [];
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (c, i) {
              final t = tasks[i];
              return Dismissible(
                key: Key(t.id),
                direction: DismissDirection.endToStart,
                background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (dir) {
                  AppDatabase.instance.deleteTask(t.id);
                  ApiClient.instance.post('/api/tasks/delete', {'id': t.id});
                },
                child: CheckboxListTile(
                  title: Text(t.title, style: const TextStyle(color: Colors.white)),
                  value: t.isCompleted,
                  activeColor: const Color(0xFF00E5FF),
                  checkColor: const Color(0xFF09090B),
                  onChanged: (val) => AppDatabase.instance.toggleTaskComplete(t.id, val),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
