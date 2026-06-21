import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class CloudBackupDashboard extends StatelessWidget {
  const CloudBackupDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cloud Backup',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cloud_upload, color: EverforestColors.bg0),
                label: const Text(
                  'Backup Now',
                  style: TextStyle(color: EverforestColors.bg0, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EverforestColors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildStorageOverview(),
          const SizedBox(height: 32),
          const Text(
            'Recent Backups',
            style: TextStyle(
              color: EverforestColors.fg,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: mockBackups.length,
              separatorBuilder: (context, index) => const Divider(color: EverforestColors.bg2),
              itemBuilder: (context, index) {
                final backup = mockBackups[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: EverforestColors.bg2,
                    child: Icon(
                      backup.status == 'Completed' ? Icons.check_circle : Icons.sync,
                      color: backup.status == 'Completed' ? EverforestColors.green : EverforestColors.yellow,
                    ),
                  ),
                  title: Text(backup.name, style: const TextStyle(color: EverforestColors.fg)),
                  subtitle: Text(backup.date, style: const TextStyle(color: EverforestColors.grey)),
                  trailing: Text(backup.size, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w500)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.65,
                  backgroundColor: EverforestColors.bg2,
                  color: EverforestColors.blue,
                  strokeWidth: 8,
                ),
              ),
              const Text(
                '65%',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Storage Usage',
                  style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '650 GB used out of 1 TB',
                  style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLegendItem('Documents', EverforestColors.blue),
                    const SizedBox(width: 16),
                    _buildLegendItem('Media', EverforestColors.purple),
                    const SizedBox(width: 16),
                    _buildLegendItem('Other', EverforestColors.bg2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
      ],
    );
  }
}

class MockBackup {
  final String name;
  final String date;
  final String size;
  final String status;

  MockBackup(this.name, this.date, this.size, this.status);
}

final mockBackups = [
  MockBackup('System Image Backup', 'Today, 10:00 AM', '45.2 GB', 'Completed'),
  MockBackup('Documents Sync', 'Yesterday, 08:30 PM', '2.1 GB', 'Completed'),
  MockBackup('Media Library', 'Jun 16, 2026', '120.5 GB', 'In Progress'),
  MockBackup('App Configurations', 'Jun 15, 2026', '450 MB', 'Completed'),
];
