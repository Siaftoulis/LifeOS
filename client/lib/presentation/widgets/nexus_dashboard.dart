import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../database/database.dart';
import '../../database/tasks_extension.dart';
import '../../theme/everforest_colors.dart';

class NexusDashboard extends StatefulWidget {
  const NexusDashboard({super.key});
  @override State<NexusDashboard> createState() => _NexusDashboardState();
}

class _NexusDashboardState extends State<NexusDashboard> {
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: ApiClient.instance.queueLengthNotifier,
              builder: (_, v, __) => Card(
                color: EverforestColors.bg1,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: EverforestColors.bg2, width: 1.0),
                ),
                child: ListTile(
                  leading: Icon(
                    v > 0 ? Icons.sync : Icons.cloud_done_rounded,
                    color: v > 0 ? EverforestColors.yellow : EverforestColors.green,
                    size: 20,
                  ),
                  title: const Text(
                    'SYNC ENGINE DESK',
                    style: TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  trailing: Text(
                    '$v PENDING',
                    style: TextStyle(
                      color: v > 0 ? EverforestColors.yellow : EverforestColors.green,
                      fontSize: 11,
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<TaskData>>(
              stream: AppDatabase.instance.watchAllTasks(),
              builder: (_, s) {
                final count = s.data?.length ?? 0;
                return Card(
                  color: EverforestColors.bg1,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: EverforestColors.bg2, width: 1.0),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.storage_rounded,
                      color: EverforestColors.blue,
                      size: 20,
                    ),
                    title: const Text(
                      'DATABASE INTEGRITY',
                      style: TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    trailing: Text(
                      '$count TASKS ACTIVE',
                      style: const TextStyle(
                        color: EverforestColors.blue,
                        fontSize: 11,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
