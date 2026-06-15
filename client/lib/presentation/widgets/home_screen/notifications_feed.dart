import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';

class NotificationsFeed extends StatelessWidget {
  const NotificationsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<LocalNotification>>(
        stream: AppDatabase.instance.homeScreenDao.watchUnreadNotifications(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No new notifications',
                style: TextStyle(color: EverforestColors.grey, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              IconData icon;
              Color color;
              switch (item.category.toUpperCase()) {
                case 'SYSTEM':
                  icon = Icons.system_update;
                  color = EverforestColors.blue;
                  break;
                case 'HABIT':
                  icon = Icons.water_drop;
                  color = EverforestColors.aqua;
                  break;
                case 'SECURITY':
                  icon = Icons.security;
                  color = EverforestColors.red;
                  break;
                case 'FINANCIAL':
                  icon = Icons.attach_money;
                  color = EverforestColors.green;
                  break;
                default:
                  icon = Icons.notifications;
                  color = EverforestColors.orange;
              }
              return _NotificationItem(
                title: item.title,
                message: item.message,
                icon: icon,
                color: color,
              );
            },
          );
        },
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
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
