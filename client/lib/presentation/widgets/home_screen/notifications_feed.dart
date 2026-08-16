import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../core/event_hub.dart';

class NotificationsFeed extends StatefulWidget {
  const NotificationsFeed({super.key});

  @override
  State<NotificationsFeed> createState() => _NotificationsFeedState();
}

class _NotificationsFeedState extends State<NotificationsFeed> {
  final List<_LiveNotif> _live = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    // Live ecosystem facts (points economy, media, books) surface here the
    // moment they happen — the bus pushed them, no polling.
    _sub = EventHub.instance.events.where(_relevant).listen((e) {
      if (!mounted) return;
      setState(() {
        _live.insert(0, _LiveNotif.from(e));
        if (_live.length > 3) _live.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  static bool _relevant(Map<String, dynamic> e) {
    switch (e['topic']) {
      case 'points:balance-change':
      case 'movies:watched':
      case 'books:finished':
      case 'rpg:task-complete':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._live.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NotificationItem(
                  title: n.title,
                  message: n.message,
                  icon: n.icon,
                  color: n.color,
                ),
              )),
          Expanded(
            child: StreamBuilder<List<LocalNotification>>(
              stream: AppDatabase.instance.homeScreenDao.watchUnreadNotifications(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (items.isEmpty && _live.isEmpty) {
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
          ),
        ],
      ),
    );
  }
}

/// One live ecosystem event rendered as a notification card.
class _LiveNotif {
  final String title, message;
  final IconData icon;
  final Color color;

  _LiveNotif(this.title, this.message, this.icon, this.color);

  static _LiveNotif from(Map<String, dynamic> e) {
    final topic = e['topic'] as String? ?? '';
    final payload = (e['payload'] as Map?) ?? const {};
    if (topic == 'movies:watched') {
      return _LiveNotif('🎬 Movie watched', '${payload['Title'] ?? 'A movie'} → +10 points',
          Icons.movie, EverforestColors.orange);
    }
    if (topic == 'books:finished') {
      return _LiveNotif('📖 Book finished', '${payload['BookID'] ?? 'A book'} → +30 points',
          Icons.menu_book, EverforestColors.green);
    }
    if (topic == 'rpg:task-complete') {
      final p = payload['Points'] ?? 0;
      return _LiveNotif('⚔️ Task complete', '+$p points', Icons.flag, EverforestColors.aqua);
    }
    // points:balance-change
    final amount = payload['Amount'] ?? 0;
    final sign = amount is num && amount >= 0 ? '+' : '';
    final reason = payload['Event'] ?? 'Points';
    final balance = payload['Balance'] ?? 0;
    return _LiveNotif('⭐ $sign$amount', '$reason — balance: $balance', Icons.stars, EverforestColors.yellow);
  }
}

class _NotificationItem extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final Color color;

  const _NotificationItem({required this.title, required this.message, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}