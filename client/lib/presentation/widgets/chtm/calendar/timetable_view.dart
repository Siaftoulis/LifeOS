import 'package:flutter/material.dart';
import '../../../../database/database.dart';
import '../../../../theme/everforest_colors.dart';
import 'calendar_utils.dart';

class WeeklyTimetable extends StatelessWidget {
  const WeeklyTimetable({
    super.key,
    required this.events,
    required this.columnsCount,
    required this.selectedDate,
    required this.threeDayAnchor,
    required this.onSelectDate,
  });

  final List<CalendarEvent> events;
  final int columnsCount;
  final DateTime selectedDate;
  final DateTime threeDayAnchor;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    DateTime startOfWeek;
    if (columnsCount == 7) {
      final int weekday = selectedDate.weekday;
      startOfWeek = selectedDate.subtract(Duration(days: weekday - 1));
    } else if (columnsCount == 3) {
      startOfWeek = threeDayAnchor.subtract(const Duration(days: 1));
    } else {
      startOfWeek = selectedDate;
    }

    final endOfWeek = startOfWeek.add(Duration(days: columnsCount));

    final periodEvents = events.where((e) {
      final start = DateTime.fromMillisecondsSinceEpoch(e.startTime);
      return start.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          start.isBefore(endOfWeek);
    }).toList();

    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double hourColWidth = 50;
        final double dayColWidth = (width - hourColWidth) / columnsCount;
        const double rowHeight = 60;
        const int startHour = 0;
        const int endHour = 24;
        const int totalHours = endHour - startHour;

        final (laneOf, laneCountPerDay) =
            computeEventLanes(events, startOfWeek, columnsCount);

        return Column(
          children: [
            Row(
              children: [
                const SizedBox(width: hourColWidth),
                ...List.generate(columnsCount, (index) {
                  final date = startOfWeek.add(Duration(days: index));
                  final isToday = date.day == DateTime.now().day &&
                      date.month == DateTime.now().month;
                  final String dayLabel = columnsCount == 7
                      ? days[date.weekday - 1]
                      : (columnsCount == 3
                          ? getDayRelationLabel(date)
                          : '${date.day}/${date.month}');
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelectDate(date),
                      child: Column(
                        children: [
                          Text(
                            dayLabel,
                            style: const TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? EverforestColors.green
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isToday
                                    ? EverforestColors.bg0
                                    : EverforestColors.fg,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 380,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Stack(
                  children: [
                    Column(
                      children: List.generate(totalHours, (index) {
                        final hour = startHour + index;
                        final period =
                            (hour >= 12 && hour < 24) ? 'PM' : 'AM';
                        int displayHour = hour % 12;
                        if (displayHour == 0) displayHour = 12;

                        return SizedBox(
                          height: rowHeight,
                          child: Row(
                            children: [
                              SizedBox(
                                width: hourColWidth,
                                child: Text(
                                  '$displayHour $period',
                                  style: const TextStyle(
                                      color: EverforestColors.grey,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: EverforestColors.bg2,
                                          width: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    ...periodEvents.map((e) {
                      final start =
                          DateTime.fromMillisecondsSinceEpoch(e.startTime);
                      final end =
                          DateTime.fromMillisecondsSinceEpoch(e.endTime);

                      if (start.hour < startHour || start.hour >= endHour) {
                        return const SizedBox.shrink();
                      }

                      final int dayIndex =
                          start.difference(startOfWeek).inDays;
                      if (dayIndex < 0 || dayIndex >= columnsCount) {
                        return const SizedBox.shrink();
                      }

                      final int lane = laneOf[e.id] ?? 0;
                      final double laneWidth =
                          dayColWidth / (laneCountPerDay[dayIndex] ?? 1);

                      final double left = hourColWidth +
                          (dayIndex * dayColWidth) +
                          lane * laneWidth;
                      final double top = (start.hour - startHour) * rowHeight +
                          (start.minute / 60) * rowHeight;
                      final double durationHours =
                          end.difference(start).inMinutes / 60;
                      final double height = durationHours * rowHeight;
                      final color = parseCalendarColor(e.colorCode);

                      return Positioned(
                        left: left + 2,
                        top: top + 2,
                        width: laneWidth - 4,
                        height: height - 4,
                        child: GestureDetector(
                          onTap: () => onSelectDate(start),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              border: Border(
                                  left:
                                      BorderSide(color: color, width: 4)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Text(
                              e.title,
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
