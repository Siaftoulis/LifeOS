import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';

class CHTMCalendarStrip extends StatelessWidget {
  final Stream<List<CalendarEvent>> eventsStream;

  const CHTMCalendarStrip({super.key, required this.eventsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CalendarEvent>>(
      stream: eventsStream,
      builder: (context, snapshot) {
        // Just keeping the UI mostly the same but replacing the static builder with stream aware one
        final now = DateTime.now();
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14, // show 2 weeks
            itemBuilder: (context, index) {
              final date = now.subtract(const Duration(days: 3)).add(Duration(days: index));
              final isToday = date.day == now.day && date.month == now.month;

              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isToday ? EverforestColors.green : EverforestColors.bg1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isToday ? EverforestColors.green : EverforestColors.bg2),
                  boxShadow: isToday
                      ? [BoxShadow(color: EverforestColors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      days[date.weekday - 1],
                      style: TextStyle(
                        color: isToday ? EverforestColors.bg0 : EverforestColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isToday ? EverforestColors.bg0 : EverforestColors.fg,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
