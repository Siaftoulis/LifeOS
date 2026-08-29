import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';

class CalendarEmbedPreview extends StatelessWidget {
  const CalendarEmbedPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final dao = ChtmDao(AppDatabase.instance);
    return StreamBuilder<List<CalendarEvent>>(
      stream: dao.watchAllEvents(),
      builder: (context, snapshot) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final upcoming = (snapshot.data ?? const <CalendarEvent>[])
            .where((e) => e.startTime > nowMs)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        final events = upcoming.take(5).toList();
        if (events.isEmpty) {
          return const Center(
            child: Text(
              'No upcoming events',
              style: TextStyle(color: EverforestColors.grey),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF2E383C)),
          itemBuilder: (context, index) {
            final e = events[index];
            final start = DateTime.fromMillisecondsSinceEpoch(e.startTime);
            return Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _parseColor(e.colorCode),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.title,
                    style: const TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _fmtDate(start),
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return EverforestColors.green;
    }
  }

  static String _fmtDate(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}, $hh:$mm';
  }
}
