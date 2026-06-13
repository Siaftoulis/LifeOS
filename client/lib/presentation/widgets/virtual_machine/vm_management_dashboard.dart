import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'vm_condensed_card.dart';
import 'remote_file_explorer_view.dart';

class VMManagementDashboard extends StatelessWidget {
  const VMManagementDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Virtual Machine Management', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _VMList()),
                SizedBox(width: 16),
                Expanded(flex: 3, child: RemoteFileExplorerView()),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _VMList extends StatelessWidget {
  const _VMList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Active VMs & Containers', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: const [
                VMCondensedCard(name: 'Dev-Sandbox', type: 'MICROVM', state: 'RUNNING', ram: 2048),
                VMCondensedCard(name: 'Database-Local', type: 'CONTAINER', state: 'RUNNING', ram: 1024),
                VMCondensedCard(name: 'Windows-Game', type: 'DESKTOP', state: 'STOPPED', ram: 8192),
              ],
            ),
          )
        ],
      ),
    );
  }
}
