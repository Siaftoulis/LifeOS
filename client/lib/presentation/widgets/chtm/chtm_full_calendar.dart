import 'package:flutter/material.dart';
import '../../../core/general_engine/engine_repository.dart';
import '../../../database/database.dart';
import '../../../theme/everforest_colors.dart';
import 'calendar/calendar_header.dart';
import 'calendar/month_grid_view.dart';
import 'calendar/timetable_view.dart';
import 'calendar/year_grid_view.dart';

export 'calendar/calendar_header.dart';
export 'calendar/calendar_utils.dart';
export 'calendar/month_grid_view.dart';
export 'calendar/timetable_view.dart';
export 'calendar/year_grid_view.dart';

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
  late DateTime _threeDayAnchor;
  String _calendarView = 'MONTH'; // 'YEAR', 'MONTH', 'WEEK', 'THREE_DAY', 'DAY'

  @override
  void initState() {
    super.initState();
    _currentMonth =
        DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedDate = widget.initialDate;
    _currentYear = widget.initialDate.year;
    _threeDayAnchor = DateTime.now();
  }

  void _previousPeriod() {
    setState(() {
      if (_calendarView == 'YEAR') {
        _currentYear--;
      } else if (_calendarView == 'THREE_DAY') {
        _threeDayAnchor = _threeDayAnchor.subtract(const Duration(days: 3));
      } else {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_calendarView == 'YEAR') {
        _currentYear++;
      } else if (_calendarView == 'THREE_DAY') {
        _threeDayAnchor = _threeDayAnchor.add(const Duration(days: 3));
      } else {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
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

  Widget _buildCurrentView(List<CalendarEvent> events, List<UserTask> tasks,
      List<HabitLog> logs) {
    switch (_calendarView) {
      case 'YEAR':
        return YearGridView(
          currentYear: _currentYear,
          onSelectMonth: (month) {
            setState(() {
              _currentMonth = DateTime(_currentYear, month, 1);
              _calendarView = 'MONTH';
            });
          },
        );
      case 'MONTH':
        return MonthGridView(
          currentMonth: _currentMonth,
          selectedDate: _selectedDate,
          events: events,
          tasks: tasks,
          logs: logs,
          onSelectDate: _selectDate,
        );
      case 'WEEK':
        return WeeklyTimetable(
          events: events,
          columnsCount: 7,
          selectedDate: _selectedDate,
          threeDayAnchor: _threeDayAnchor,
          onSelectDate: _selectDate,
        );
      case 'THREE_DAY':
        return WeeklyTimetable(
          events: events,
          columnsCount: 3,
          selectedDate: _selectedDate,
          threeDayAnchor: _threeDayAnchor,
          onSelectDate: _selectDate,
        );
      case 'DAY':
        return WeeklyTimetable(
          events: events,
          columnsCount: 1,
          selectedDate: _selectedDate,
          threeDayAnchor: _threeDayAnchor,
          onSelectDate: _selectDate,
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final headerMonth =
        _calendarView == 'THREE_DAY' ? _threeDayAnchor : _currentMonth;
    final monthStr = '${months[headerMonth.month - 1]} ${headerMonth.year}';
    final headerStr = _calendarView == 'YEAR' ? '$_currentYear' : monthStr;

    return ValueListenableBuilder(
      valueListenable: EngineRepository.instance.allEntities,
      builder: (context, entities, child) {
        return StreamBuilder<List<CalendarEvent>>(
          stream: widget.eventsStream,
          builder: (context, eventSnapshot) {
            return StreamBuilder<List<UserTask>>(
              stream: widget.tasksStream,
              builder: (context, taskSnapshot) {
                return StreamBuilder<List<HabitLog>>(
                  stream: widget.habitLogsStream,
                  builder: (context, logSnapshot) {
                    final events = List<CalendarEvent>.from(
                        eventSnapshot.data ?? []);
                    final tasks = taskSnapshot.data ?? [];
                    final logs = logSnapshot.data ?? [];

                    final engineEvents = EngineRepository.instance.events;
                    for (var ee in engineEvents) {
                      final start =
                          DateTime.tryParse(ee.payload['start_time'] ?? '');
                      final end =
                          DateTime.tryParse(ee.payload['end_time'] ?? '');
                      if (start != null && end != null) {
                        events.add(CalendarEvent(
                          id: ee.id,
                          title: ee.payload['title'] ?? 'No Title',
                          startTime: start.millisecondsSinceEpoch,
                          endTime: end.millisecondsSinceEpoch,
                          colorCode: ee.payload['color_code'] ?? '#89B4FA',
                          isShared: ee.sharedWith.isNotEmpty ? 1 : 0,
                          updatedAt: ee.updatedAt.millisecondsSinceEpoch,
                          isDirty: 0,
                        ));
                      }
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: EverforestColors.bg1.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: EverforestColors.bg2),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CalendarHeaderView(
                            headerTitle: headerStr,
                            calendarView: _calendarView,
                            onZoomOut: _zoomOut,
                            onPrevious: _previousPeriod,
                            onNext: _nextPeriod,
                            onViewChanged: (view) =>
                                setState(() => _calendarView = view),
                          ),
                          const SizedBox(height: 16),
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
      },
    );
  }
}
