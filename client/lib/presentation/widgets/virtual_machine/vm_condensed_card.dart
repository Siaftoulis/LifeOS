import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class VMCondensedCard extends StatelessWidget {
  final String name;
  final String type;
  final String state;
  final int ram;

  const VMCondensedCard({super.key, required this.name, required this.type, required this.state, required this.ram});

  @override
  Widget build(BuildContext context) {
    final isRunning = state == 'RUNNING';
    final neonColor = isRunning ? EverforestColors.green : EverforestColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: neonColor.withOpacity(0.1), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.computer, color: neonColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$type | ${ram}MB RAM', style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: isRunning,
            onChanged: (val) {},
            activeColor: EverforestColors.green,
            inactiveThumbColor: EverforestColors.red,
            inactiveTrackColor: EverforestColors.bg2,
          )
        ],
      ),
    );
  }
}
