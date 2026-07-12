import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';

class CHTMFullCalendar extends StatefulWidget {
  final Stream<List<CalendarEvent>> eventsStream;
  final Stream<List<UserTask>> tasksStream;
  final Stream<List<HabitLog>> habitLogsStream;
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const CHTMFullCalendar({
    super.key,
    required this.eventsStream,
    required this.tasksStream,
    required this.habitLogsStream,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CHTMFullCalendar> createState() => _CHTMFullCalendarState();
}

class _CHTMFullCalendarState extends State<CHTMFullCalendar> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  late int _currentYear;
  String _calendarView = 'MONTH'; // 'YEAR', 'MONTH', 'WEEK', 'THREE_DAY', 'DAY'

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedDate = widget.initialDate;
    _currentYear = widget.initialDate.year;
  }

  void _previousPeriod() {
    setState(() {
      if (_calendarView == 'YEAR') {
        _currentYear--;
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_calendarView == 'YEAR') {
        _currentYear++;
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      }
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _currentMonth = DateTime(date.year, date.month, 1);
      _currentYear = date.year;

      if (_calendarView == 'MONTH') {
        _calendarView = 'WEEK';
      } else if (_calendarView == 'WEEK') {
        _calendarView = 'THREE_DAY';
      } else if (_calendarView == 'THREE_DAY') {
        _calendarView = 'DAY';
      }
    });
    widget.onDateSelected(date);
  }

  void _zoomOut() {
    setState(() {
      if (_calendarView == 'DAY') {
        _calendarView = 'THREE_DAY';
      } else if (_calendarView == 'THREE_DAY') {
        _calendarView = 'WEEK';
      } else if (_calendarView == 'WEEK') {
        _calendarView = 'MONTH';
      } else if (_calendarView == 'MONTH') {
        _calendarView = 'YEAR';
      }
    });
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return EverforestColors.blue;
    try {
      final code = hex.replaceAll('#', '');
      return Color(int.parse('FF$code', radix: 16));
    } catch (_) {
      return EverforestColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
    final headerStr = _calendarView == 'YEAR' ? '$_currentYear' : monthStr;

    return StreamBuilder<List<CalendarEvent>>(
      stream: widget.eventsStream,
      builder: (context, eventSnapshot) {
        return StreamBuilder<List<UserTask>>(
          stream: widget.tasksStream,
          builder: (context, taskSnapshot) {
            return StreamBuilder<List<HabitLog>>(
              stream: widget.habitLogsStream,
              builder: (context, logSnapshot) {
                final events = eventSnapshot.data ?? [];
                final tasks = taskSnapshot.data ?? [];
                final logs = logSnapshot.data ?? [];

                return Container(
                  decoration: BoxDecoration(
                    color: EverforestColors.bg1.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: EverforestColors.bg2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View Selection Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (_calendarView != 'YEAR')
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_upward, color: EverforestColors.green, size: 20),
                                    onPressed: _zoomOut,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Zoom Out',
                                  ),
                                ),
                              Text(
                                headerStr,
                                style: const TextStyle(
                                  color: EverforestColors.fg,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.chevron_left, color: EverforestColors.fg, size: 20),
                                onPressed: _previousPeriod,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: EverforestColors.fg, size: 20),
                                onPressed: _nextPeriod,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          // Premium view toggles dropdown/selector
                          _buildViewSelector(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Animated switch of views
                      _buildCurrentView(events, tasks, logs),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildViewSelector() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: EverforestColors.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EverforestColors.green.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.calendar_view_week, color: EverforestColors.green, size: 18),
      ),
      color: EverforestColors.bg1,
      elevation: 8,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: EverforestColors.bg2),
      ),
      onSelected: (view) => setState(() => _calendarView = view),
      itemBuilder: (context) {
        PopupMenuItem<String> buildItem(String value, String label, IconData icon) {
          final isSelected = _calendarView == value;
          return PopupMenuItem(
            value: value,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? EverforestColors.green : EverforestColors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? EverforestColors.green : EverforestColors.fg,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: EverforestColors.green, size: 18),
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

  Widget _buildCurrentView(List<CalendarEvent> events, List<UserTask> tasks, List<HabitLog> logs) {
    switch (_calendarView) {
      case 'YEAR':
        return _buildYearGrid();
      case 'MONTH':
        return Column(
          children: [
            _buildDaysOfWeek(),
            const SizedBox(height: 8),
            _buildCalendarGrid(events, tasks, logs),
          ],
        );
      case 'WEEK':
        return _buildWeeklyTimetable(events, 7);
      case 'THREE_DAY':
        return _buildWeeklyTimetable(events, 3);
      case 'DAY':
        return _buildWeeklyTimetable(events, 1);
      default:
        return Container();
    }
  }

  Widget _buildYearGrid() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final isCurrentMonth = DateTime.now().month == (index + 1) && DateTime.now().year == _currentYear;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentMonth = DateTime(_currentYear, index + 1, 1);
              _calendarView = 'MONTH';
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentMonth ? EverforestColors.green.withValues(alpha: 0.2) : EverforestColors.bg0,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isCurrentMonth ? EverforestColors.green : EverforestColors.bg2),
            ),
            alignment: Alignment.center,
            child: Text(
              months[index],
              style: TextStyle(
                color: isCurrentMonth ? EverforestColors.green : EverforestColors.fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(List<CalendarEvent> events, List<UserTask> tasks, List<HabitLog> logs) {
    final int daysInMonth = _daysInMonth(_currentMonth.year, _currentMonth.month);
    final int firstWeekday = _currentMonth.weekday; // 1 = Monday, 7 = Sunday
    
    final List<Widget> cells = [];
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    
    final today = DateTime.now();

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      
      // Calculate daily activity count (for GitHub contribution color style)
      final completedTasksCount = tasks.where((t) {
        if (t.status != 'DONE' || t.completedAt == null) return false;
        final compDate = DateTime.fromMillisecondsSinceEpoch(t.completedAt!);
        return compDate.year == date.year && compDate.month == date.month && compDate.day == date.day;
      }).length;

      final completedHabitsCount = logs.where((l) {
        final checkin = DateTime.fromMillisecondsSinceEpoch(l.checkinDate);
        return checkin.year == date.year && checkin.month == date.month && checkin.day == date.day;
      }).length;

      final totalCompleted = completedTasksCount + completedHabitsCount;

      Color contributionColor = Colors.transparent;
      if (totalCompleted == 1) contributionColor = EverforestColors.green.withValues(alpha: 0.15);
      else if (totalCompleted == 2) contributionColor = EverforestColors.green.withValues(alpha: 0.35);
      else if (totalCompleted == 3) contributionColor = EverforestColors.green.withValues(alpha: 0.6);
      else if (totalCompleted >= 4) contributionColor = EverforestColors.green;

      // Filter events for indicators
      final cellEvents = events.where((e) {
        final start = DateTime.fromMillisecondsSinceEpoch(e.startTime);
        return start.year == date.year && start.month == date.month && start.day == date.day;
      }).toList();

      cells.add(
        GestureDetector(
          onTap: () => _selectDate(date),
          child: Container(
            decoration: BoxDecoration(
              color: contributionColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EverforestColors.bg2.withValues(alpha: 0.2), width: 0.5),
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
                      color: isSelected ? EverforestColors.green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected ? Border.all(color: EverforestColors.green.withValues(alpha: 0.6), width: 1.5) : null,
                    ),
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color: isSelected ? EverforestColors.bg0 : (totalCompleted >= 3 ? EverforestColors.bg0 : EverforestColors.fg),
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
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
                          color: totalCompleted >= 3 ? EverforestColors.bg0 : _parseColor(e.colorCode),
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

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      children: cells,
    );
  }

  Widget _buildWeeklyTimetable(List<CalendarEvent> events, int columnsCount) {
    DateTime startOfWeek;
    if (columnsCount == 7) {
      final int weekday = _selectedDate.weekday;
      startOfWeek = _selectedDate.subtract(Duration(days: weekday - 1));
    } else if (columnsCount == 3) {
      startOfWeek = _selectedDate.subtract(const Duration(days: 1));
    } else {
      startOfWeek = _selectedDate;
    }

    final endOfWeek = startOfWeek.add(Duration(days: columnsCount));

    // Get events for the selected week/period
    final periodEvents = events.where((e) {
      final start = DateTime.fromMillisecondsSinceEpoch(e.startTime);
      return start.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          start.isBefore(endOfWeek);
    }).toList();

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double hourColWidth = 50;
        final double dayColWidth = (width - hourColWidth) / columnsCount;
        const double rowHeight = 60;
        const int startHour = 0;
        const int endHour = 24;
        const int totalHours = endHour - startHour;

        return Column(
          children: [
            // Days of the week header with dates
            Row(
              children: [
                const SizedBox(width: hourColWidth),
                ...List.generate(columnsCount, (index) {
                  final date = startOfWeek.add(Duration(days: index));
                  final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(date),
                      child: Column(
                        children: [
                          Text(
                            columnsCount == 7 ? days[date.weekday - 1] : '${date.day}/${date.month}',
                            style: const TextStyle(color: EverforestColors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isToday ? EverforestColors.green : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isToday ? EverforestColors.bg0 : EverforestColors.fg,
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
            // Scrollable Timetable Grid
            SizedBox(
              height: 380,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Stack(
                  children: [
                    // Horizontal Grid Lines & Hour Labels
                    Column(
                      children: List.generate(totalHours, (index) {
                        final hour = startHour + index;
                        final period = (hour >= 12 && hour < 24) ? 'PM' : 'AM';
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
                                  style: const TextStyle(color: EverforestColors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: EverforestColors.bg2, width: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    // Positioned Calendar Events
                    ...periodEvents.map((e) {
                      final start = DateTime.fromMillisecondsSinceEpoch(e.startTime);
                      final end = DateTime.fromMillisecondsSinceEpoch(e.endTime);

                      // Skip if event is outside timetable hours
                      if (start.hour < startHour || start.hour >= endHour) return const SizedBox.shrink();

                      final int dayIndex = start.difference(startOfWeek).inDays;
                      if (dayIndex < 0 || dayIndex >= columnsCount) return const SizedBox.shrink();

                      final double left = hourColWidth + (dayIndex * dayColWidth);
                      final double top = (start.hour - startHour) * rowHeight + (start.minute / 60) * rowHeight;
                      final double durationHours = end.difference(start).inMinutes / 60;
                      final double height = durationHours * rowHeight;
                      final color = _parseColor(e.colorCode);

                      return Positioned(
                        left: left + 2,
                        top: top + 2,
                        width: dayColWidth - 4,
                        height: height - 4,
                        child: GestureDetector(
                          onTap: () => _selectDate(start),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              border: Border(left: BorderSide(color: color, width: 4)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
