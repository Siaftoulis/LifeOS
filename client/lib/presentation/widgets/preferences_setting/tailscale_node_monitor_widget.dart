import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class TailscaleNodeMonitorWidget extends StatelessWidget {
  const TailscaleNodeMonitorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Tailscale Network Mesh', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ListTile(
                leading: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: EverforestColors.green,
                  ),
                ),
                title: const Text('Tunnel Connected', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: const Text('Active Relay Server Mesh', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                trailing: const Icon(Icons.settings_ethernet, color: EverforestColors.green),
              ),
            ),
          )
        ],
      ),
    );
  }
}
