import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'grid_configurator_widget.dart';
import 'tailscale_node_monitor_widget.dart';

class PreferencesDashboardView extends StatelessWidget {
  const PreferencesDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Preferences & System Settings', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: GridConfiguratorWidget()),
                SizedBox(width: 16),
                Expanded(flex: 3, child: TailscaleNodeMonitorWidget()),
              ],
            ),
          )
        ],
      ),
    );
  }
}
