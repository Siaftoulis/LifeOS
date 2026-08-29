import 'package:flutter/material.dart';
import '../../../../database/database.dart';
import '../../../../theme/everforest_colors.dart';

Color parseCalendarColor(String? hexCode) {
  if (hexCode == null || hexCode.isEmpty) return EverforestColors.green;
  try {
    String hex = hexCode.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse('0x$hex'));
  } catch (_) {
    return EverforestColors.green;
  }
}

int getDaysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

String getDayRelationLabel(DateTime date) {
  final today = DateTime.now();
  final diff = DateTime(date.year, date.month, date.day)
      .difference(DateTime(today.year, today.month, today.day))
      .inDays;
  if (diff == 0) return 'Today';
  if (diff == -1) return 'Yesterday';
  if (diff == 1) return 'Tomorrow';
  return '${date.day}/${date.month}';
}

/// Greedy interval-partitioning: assigns each event a lane index (0-based)
/// so overlapping events sit side-by-side, and returns the lane count per day.
/// Events outside [startOfWeek, startOfWeek + columnsCount) are ignored.
(Map<String, int> laneOf, Map<int, int> laneCountPerDay) computeEventLanes(
  List<CalendarEvent> events,
  DateTime startOfWeek,
  int columnsCount,
) {
  final laneOf = <String, int>{};
  final laneCountPerDay = <int, int>{};
  final byDay = <int, List<CalendarEvent>>{};

  for (final e in events) {
    final dayIndex = DateTime.fromMillisecondsSinceEpoch(e.startTime)
        .difference(startOfWeek)
        .inDays;
    if (dayIndex < 0 || dayIndex >= columnsCount) continue;
    byDay.putIfAbsent(dayIndex, () => []).add(e);
  }

  byDay.forEach((dayIndex, dayEvents) {
    dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    final laneEnds = <int>[];
    for (final e in dayEvents) {
      int lane = laneEnds.indexWhere((end) => end <= e.startTime);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(e.endTime);
      } else {
        laneEnds[lane] = e.endTime;
      }
      laneOf[e.id] = lane;
    }
    laneCountPerDay[dayIndex] = laneEnds.length;
  });

  return (laneOf, laneCountPerDay);
}
