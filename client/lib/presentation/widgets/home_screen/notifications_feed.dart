import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class NotificationsFeed extends StatelessWidget {
  const NotificationsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotificationItem(title: 'System Update', message: 'LifeOS v2.4 downloaded.', icon: Icons.system_update, color: EverforestColors.blue),
          _NotificationItem(title: 'Habit Reminder', message: 'Drink water (0/8)', icon: Icons.water_drop, color: EverforestColors.aqua),
          _NotificationItem(title: 'Security', message: 'Failed login attempt at 10:45', icon: Icons.security, color: EverforestColors.red),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final Color color;

  const _NotificationItem({required this.title, required this.message, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(message, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
