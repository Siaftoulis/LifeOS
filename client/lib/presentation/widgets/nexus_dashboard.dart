import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../database/database.dart';
import '../../database/tasks_extension.dart';

class NexusDashboard extends StatefulWidget {
  const NexusDashboard({super.key});
  @override State<NexusDashboard> createState() => _NexusDashboardState();
}

class _NexusDashboardState extends State<NexusDashboard> {
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        ValueListenableBuilder<int>(
          valueListenable: ApiClient.instance.queueLengthNotifier,
          builder: (_, v, __) => Card(color: const Color(0xFF121214), child: ListTile(
            leading: Icon(v > 0 ? Icons.sync : Icons.cloud_done_rounded, color: const Color(0xFF00E5FF), size: 20),
            title: const Text('SYNC ENGINE DESK', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            trailing: Text('$v PENDING', style: TextStyle(color: v > 0 ? Colors.amberAccent : const Color(0xFF00E5FF), fontSize: 11, fontFamily: 'JetBrainsMono')),
          )),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<TaskData>>(
          stream: AppDatabase.instance.watchAllTasks(),
          builder: (_, s) {
            final count = s.data?.length ?? 0;
            return Card(color: const Color(0xFF121214), child: ListTile(
              leading: const Icon(Icons.storage_rounded, color: Color(0xFF00E5FF), size: 20),
              title: const Text('DATABASE INTEGRITY', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              trailing: Text('$count TASKS ACTIVE', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontFamily: 'JetBrainsMono')),
            ));
          },
        ),
      ])),
    );
  }
}
