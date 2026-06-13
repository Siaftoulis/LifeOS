import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'backup_status_list.dart';
import 'quarantine_view.dart';

class CloudBackupDashboard extends StatefulWidget {
  const CloudBackupDashboard({super.key});

  @override
  State<CloudBackupDashboard> createState() => _CloudBackupDashboardState();
}

class _CloudBackupDashboardState extends State<CloudBackupDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: _currentIndex == 0 ? const BackupStatusList() : const QuarantineView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Cloud VM & Backups',
            style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.cloud_sync, color: EverforestColors.blue),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Triggering immediate backup cycle...')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(child: _buildTab(0, 'Device Backups', Icons.devices)),
        const SizedBox(width: 8),
        Expanded(child: _buildTab(1, 'Upload Quarantine', Icons.security)),
      ],
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? EverforestColors.blue.withOpacity(0.2) : EverforestColors.bg1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? EverforestColors.blue : EverforestColors.bg2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? EverforestColors.blue : EverforestColors.grey),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: isActive ? EverforestColors.fg : EverforestColors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
