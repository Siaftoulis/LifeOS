import 'package:flutter/material.dart';
import '../../../../database/database.dart';
import '../../../../theme/everforest_colors.dart';
import 'calendar_utils.dart';

class DaysOfWeekHeader extends StatelessWidget {
  const DaysOfWeekHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class MonthGridView extends StatelessWidget {
  const MonthGridView({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.events,
    required this.tasks,
    required this.logs,
    required this.onSelectDate,
  });

  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final List<UserTask> tasks;
  final List<HabitLog> logs;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final int daysInMonth =
        getDaysInMonth(currentMonth.year, currentMonth.month);
    final int firstWeekday = currentMonth.weekday; // 1 = Monday, 7 = Sunday

    final List<Widget> cells = [];
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    final today = DateTime.now();

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(currentMonth.year, currentMonth.month, i);
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      final completedTasksCount = tasks.where((t) {
        if (t.status != 'DONE' || t.completedAt == null) return false;
        final compDate = DateTime.fromMillisecondsSinceEpoch(t.completedAt!);
        return compDate.year == date.year &&
            compDate.month == date.month &&
            compDate.day == date.day;
      }).length;

      final completedHabitsCount = logs.where((l) {
        final checkin = DateTime.fromMillisecondsSinceEpoch(l.checkinDate);
        return checkin.year == date.year &&
            checkin.month == date.month &&
            checkin.day == date.day;
      }).length;

      final totalCompleted = completedTasksCount + completedHabitsCount;

      Color contributionColor = Colors.transparent;
      if (totalCompleted == 1) {
        contributionColor = EverforestColors.green.withValues(alpha: 0.15);
      } else if (totalCompleted == 2) {
        contributionColor = EverforestColors.green.withValues(alpha: 0.35);
      } else if (totalCompleted == 3) {
        contributionColor = EverforestColors.green.withValues(alpha: 0.6);
      } else if (totalCompleted >= 4) {
        contributionColor = EverforestColors.green;
      }

      final cellEvents = events.where((e) {
        final start = DateTime.fromMillisecondsSinceEpoch(e.startTime);
        return start.year == date.year &&
            start.month == date.month &&
            start.day == date.day;
      }).toList();

      cells.add(
        GestureDetector(
          onTap: () => onSelectDate(date),
          child: Container(
            decoration: BoxDecoration(
              color: contributionColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: EverforestColors.bg2.withValues(alpha: 0.2),
                  width: 0.5),
            ),
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? EverforestColors.green
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(
                              color: EverforestColors.green
                                  .withValues(alpha: 0.6),
                              width: 1.5)
                          : null,
                    ),
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color: isSelected
                            ? EverforestColors.bg0
                            : (totalCompleted >= 3
                                ? EverforestColors.bg0
                                : EverforestColors.fg),
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: cellEvents.take(3).map((e) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: totalCompleted >= 3
                              ? EverforestColors.bg0
                              : parseCalendarColor(e.colorCode),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        const DaysOfWeekHeader(),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          children: cells,
        ),
      ],
    );
  }
}
