import 'package:flutter/material.dart';
import 'terminal/terminal_logs.dart';
import 'virtual_machine/vm_management_dashboard.dart';
import 'cloud/cloud_backup_dashboard.dart';
import 'darkweb/torrent_dashboard_view.dart';
import '../maps_live_tracking/maps_dashboard_widget.dart';
import '../home_management/smart_home_dashboard.dart';

import '../../../theme/app_skin_manager.dart';

class InfraHubDashboard extends StatelessWidget {
  const InfraHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSkinManager.currentSkinNotifier,
      builder: (context, _) {
        final skin = context.skin;
        return DefaultTabController(
          length: 6,
          child: Scaffold(
            backgroundColor: skin.bg0,
            appBar: AppBar(
              backgroundColor: skin.bg1,
              title: Text('Infrastructure Hub', style: TextStyle(color: skin.fg, fontWeight: FontWeight.bold)),
              elevation: 0,
              bottom: TabBar(
                isScrollable: true,
                tabs: const [
                  Tab(text: 'System Monitor'),
                  Tab(text: 'Virtual Machines'),
                  Tab(text: 'Cloud Backup'),
                  Tab(text: 'Torrents & Darkweb'),
                  Tab(text: 'Maps & Tracking'),
                  Tab(text: 'Smart Home'),
                ],
                labelColor: skin.accent,
                unselectedLabelColor: skin.textMuted,
                indicatorColor: skin.accent,
              ),
            ),
            body: TabBarView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                KeyedSubtree(key: ValueKey('infra_terminal_${skin.id}'), child: const TerminalLogs()),
                KeyedSubtree(key: ValueKey('infra_vm_${skin.id}'), child: const VMManagementDashboard()),
                KeyedSubtree(key: ValueKey('infra_cloud_${skin.id}'), child: const CloudBackupDashboard()),
                KeyedSubtree(key: ValueKey('infra_torrent_${skin.id}'), child: const TorrentDashboardView()),
                KeyedSubtree(key: ValueKey('infra_maps_${skin.id}'), child: const MapsDashboardWidget()),
                KeyedSubtree(key: ValueKey('infra_smarthome_${skin.id}'), child: const SmartHomeDashboard()),
              ],
            ),
          ),
        );
      },
    );
  }
}
