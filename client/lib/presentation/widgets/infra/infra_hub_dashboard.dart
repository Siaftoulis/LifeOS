import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'terminal/terminal_logs.dart';
import 'virtual_machine/vm_management_dashboard.dart';
import 'cloud/cloud_backup_dashboard.dart';
import 'darkweb/torrent_dashboard_view.dart';
import '../maps_live_tracking/maps_dashboard_widget.dart';
import '../home_management/smart_home_dashboard.dart';

class InfraHubDashboard extends StatelessWidget {
  const InfraHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: EverforestColors.bg0,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg1,
          title: const Text('Infrastructure Hub', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'System Monitor'),
              Tab(text: 'Virtual Machines'),
              Tab(text: 'Cloud Backup'),
              Tab(text: 'Torrents & Darkweb'),
              Tab(text: 'Maps & Tracking'),
              Tab(text: 'Smart Home'),
            ],
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            indicatorColor: EverforestColors.green,
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            TerminalLogs(),
            VMManagementDashboard(),
            CloudBackupDashboard(),
            TorrentDashboardView(),
            MapsDashboardWidget(),
            SmartHomeDashboard(),
          ],
        ),
      ),
    );
  }
}
