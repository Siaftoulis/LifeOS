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
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                final isOnline = index % 2 == 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOnline ? EverforestColors.green : EverforestColors.red,
                    radius: 8,
                  ),
                  title: Text('Node $index', style: const TextStyle(color: EverforestColors.fg)),
                  subtitle: Text('100.76.247.1$index', style: const TextStyle(color: EverforestColors.grey)),
                  trailing: const Icon(Icons.settings_ethernet, color: EverforestColors.blue),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
