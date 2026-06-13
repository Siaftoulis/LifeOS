import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class ActiveSessionTimerOverlay extends StatelessWidget {
  const ActiveSessionTimerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: EverforestColors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EverforestColors.red.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: EverforestColors.red, size: 16),
          const SizedBox(width: 8),
          const Text('14:29 remaining', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: EverforestColors.red, borderRadius: BorderRadius.circular(4)),
            child: const Text('-10 PTS', style: TextStyle(color: EverforestColors.bg0, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
