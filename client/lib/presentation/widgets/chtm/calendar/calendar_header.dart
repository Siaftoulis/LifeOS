import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';

class CalendarHeaderView extends StatelessWidget {
  const CalendarHeaderView({
    super.key,
    required this.headerTitle,
    required this.calendarView,
    required this.onZoomOut,
    required this.onPrevious,
    required this.onNext,
    required this.onViewChanged,
  });

  final String headerTitle;
  final String calendarView;
  final VoidCallback onZoomOut;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<String> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (calendarView != 'YEAR')
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward,
                      color: EverforestColors.green, size: 20),
                  onPressed: onZoomOut,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Zoom Out',
                ),
              ),
            Text(
              headerTitle,
              style: const TextStyle(
                color: EverforestColors.fg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: EverforestColors.fg, size: 20),
              onPressed: onPrevious,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.chevron_right,
                  color: EverforestColors.fg, size: 20),
              onPressed: onNext,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        CalendarViewSelector(
          calendarView: calendarView,
          onViewChanged: onViewChanged,
        ),
      ],
    );
  }
}

class CalendarViewSelector extends StatelessWidget {
  const CalendarViewSelector({
    super.key,
    required this.calendarView,
    required this.onViewChanged,
  });

  final String calendarView;
  final ValueChanged<String> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: EverforestColors.bg2,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: EverforestColors.green.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.calendar_view_week,
            color: EverforestColors.green, size: 18),
      ),
      color: EverforestColors.bg1,
      elevation: 8,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: EverforestColors.bg2),
      ),
      onSelected: onViewChanged,
      itemBuilder: (context) {
        PopupMenuItem<String> buildItem(
            String value, String label, IconData icon) {
          final isSelected = calendarView == value;
          return PopupMenuItem(
            value: value,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? EverforestColors.green
                      : EverforestColors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? EverforestColors.green
                        : EverforestColors.fg,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(Icons.check,
                      color: EverforestColors.green, size: 18),
                ],
              ],
            ),
          );
        }

        return [
          buildItem('YEAR', 'Yearly View', Icons.calendar_view_month),
          buildItem('MONTH', 'Monthly View', Icons.calendar_month),
          buildItem('WEEK', 'Weekly View', Icons.view_week),
          buildItem('THREE_DAY', '3-Day View', Icons.view_day),
          buildItem('DAY', 'Daily View', Icons.calendar_today),
        ];
      },
    );
  }
}
