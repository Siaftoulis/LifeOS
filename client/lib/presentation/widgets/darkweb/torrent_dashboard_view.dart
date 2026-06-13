import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'active_torrents_list.dart';
import 'quarantine_warnings_panel.dart';

class TorrentDashboardView extends StatefulWidget {
  const TorrentDashboardView({super.key});

  @override
  State<TorrentDashboardView> createState() => _TorrentDashboardViewState();
}

class _TorrentDashboardViewState extends State<TorrentDashboardView> {
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
            child: _currentIndex == 0 ? const ActiveTorrentsList() : const QuarantineWarningsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Dark Web Management',
            style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_link, color: EverforestColors.green),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add Magnet Link dialog...')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(child: _buildTab(0, 'Active Torrents', Icons.download)),
        const SizedBox(width: 8),
        Expanded(child: _buildTab(1, 'Security Logs', Icons.security)),
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
          color: isActive ? EverforestColors.green.withOpacity(0.2) : EverforestColors.bg1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? EverforestColors.green : EverforestColors.bg2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? EverforestColors.green : EverforestColors.grey),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: isActive ? EverforestColors.fg : EverforestColors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
