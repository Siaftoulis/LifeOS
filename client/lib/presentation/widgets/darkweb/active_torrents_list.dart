import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class ActiveTorrentsList extends StatelessWidget {
  const ActiveTorrentsList({super.key});

  @override
  Widget build(BuildContext context) {
    final torrents = [
      {'name': 'Ubuntu 24.04 ISO', 'status': 'SEEDING', 'progress': 1.0, 'up': '1.2 MB/s', 'down': '0 B/s'},
      {'name': 'Cyberpunk_Assets.zip', 'status': 'DOWNLOADING', 'progress': 0.45, 'up': '12 KB/s', 'down': '4.5 MB/s'},
      {'name': 'Arch Linux', 'status': 'PAUSED', 'progress': 0.1, 'up': '0 B/s', 'down': '0 B/s'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        itemCount: torrents.length,
        separatorBuilder: (_, __) => const Divider(color: EverforestColors.bg2),
        itemBuilder: (context, index) {
          final t = torrents[index];
          final status = t['status'] as String;
          Color statusColor;
          if (status == 'SEEDING') statusColor = EverforestColors.green;
          else if (status == 'DOWNLOADING') statusColor = EverforestColors.blue;
          else statusColor = EverforestColors.grey;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.folder_zip, color: statusColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name'] as String, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: t['progress'] as double,
                        backgroundColor: EverforestColors.bg2,
                        color: statusColor,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('↓ ${t['down']}', style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                          Text('↑ ${t['up']}', style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.stop_circle, color: EverforestColors.red, size: 20),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
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
