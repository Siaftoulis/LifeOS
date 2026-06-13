import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class SlideableTaskCard extends StatelessWidget {
  final String title;
  final int priority;
  final String status;

  const SlideableTaskCard({
    super.key,
    required this.title,
    required this.priority,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    switch (priority) {
      case 4: indicatorColor = EverforestColors.red; break;
      case 3: indicatorColor = EverforestColors.yellow; break;
      case 2: indicatorColor = EverforestColors.blue; break;
      default: indicatorColor = EverforestColors.green;
    }

    return Dismissible(
      key: Key(title),
      background: Container(
        color: EverforestColors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: EverforestColors.bg0),
      ),
      secondaryBackground: Container(
        color: EverforestColors.yellow,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.schedule, color: EverforestColors.bg0),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Completed
        } else {
          // Rescheduled
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EverforestColors.bg0,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EverforestColors.bg2),
        ),
        child: Row(
          children: [
            Container(width: 4, height: 24, color: indicatorColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 14)),
            ),
            Text(status, style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
