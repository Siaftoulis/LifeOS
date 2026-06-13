import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class BackupStatusList extends StatelessWidget {
  const BackupStatusList({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = [
      {'name': 'Desktop-Main', 'status': 'ACTIVE', 'progress': 0.7, 'last': 'Just now'},
      {'name': 'MacBook-Pro', 'status': 'COMPLETED', 'progress': 1.0, 'last': '2 hrs ago'},
      {'name': 'Pixel-8', 'status': 'FAILED', 'progress': 0.2, 'last': '1 day ago'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        itemCount: devices.length,
        separatorBuilder: (_, __) => const Divider(color: EverforestColors.bg2),
        itemBuilder: (context, index) {
          final device = devices[index];
          final status = device['status'] as String;
          Color statusColor;
          if (status == 'ACTIVE') statusColor = EverforestColors.blue;
          else if (status == 'FAILED') statusColor = EverforestColors.red;
          else statusColor = EverforestColors.green;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.computer, color: statusColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device['name'] as String, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: device['progress'] as double,
                        backgroundColor: EverforestColors.bg2,
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(device['last'] as String, style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
