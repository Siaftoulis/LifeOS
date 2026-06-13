import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class TopicCardWidget extends StatelessWidget {
  final String title;
  final String category;
  final String status;

  const TopicCardWidget({super.key, required this.title, required this.category, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open, color: statusColor, size: 20),
              const Spacer(),
              _StatusBadge(status: status, color: statusColor),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(category, style: const TextStyle(color: EverforestColors.grey, fontSize: 12, letterSpacing: 1)),
        ],
      ),
    );
  }

  Color _getStatusColor(String s) {
    switch (s) {
      case 'LEARNING': return EverforestColors.green;
      case 'COMPLETED': return EverforestColors.blue;
      default: return EverforestColors.orange;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
