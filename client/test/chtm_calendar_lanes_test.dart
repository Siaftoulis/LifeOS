import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/database/database.dart';
import 'package:lifeos_client/presentation/widgets/chtm/chtm_full_calendar.dart';

CalendarEvent ev(String id, DateTime start, DateTime end) => CalendarEvent(
      id: id,
      title: id,
      startTime: start.millisecondsSinceEpoch,
      endTime: end.millisecondsSinceEpoch,
      colorCode: '#89B4FA',
      isShared: 0,
      updatedAt: 0,
      isDirty: 0,
    );

void main() {
  final startOfWeek = DateTime(2026, 1, 5);
  DateTime at(int day, int hour, int minute) =>
      DateTime(2026, 1, 5 + day, hour, minute);

  test('overlapping events share a day side-by-side', () {
    final (laneOf, laneCount) = computeEventLanes([
      ev('a', at(0, 9, 0), at(0, 10, 0)),
      ev('b', at(0, 9, 30), at(0, 11, 0)),
    ], startOfWeek, 7);

    expect(laneCount[0], 2);
    expect(laneOf['a'], 0);
    expect(laneOf['b'], 1);
  });

  test('sequential events reuse the same lane', () {
    final (laneOf, laneCount) = computeEventLanes([
      ev('a', at(0, 9, 0), at(0, 10, 0)),
      ev('b', at(0, 10, 0), at(0, 11, 0)),
    ], startOfWeek, 7);

    expect(laneCount[0], 1);
    expect(laneOf['a'], 0);
    expect(laneOf['b'], 0);
  });

  test('middle event overlapping both ends packs the outer lanes', () {
    final (laneOf, laneCount) = computeEventLanes([
      ev('a', at(0, 9, 0), at(0, 10, 0)),
      ev('b', at(0, 9, 30), at(0, 10, 30)),
      ev('c', at(0, 10, 15), at(0, 11, 0)),
    ], startOfWeek, 7);

    expect(laneCount[0], 2);
    expect(laneOf['a'], 0);
    expect(laneOf['b'], 1);
    expect(laneOf['c'], 0);
  });

  test('events on different days are independent', () {
    final (laneOf, laneCount) = computeEventLanes([
      ev('a', at(0, 9, 0), at(0, 10, 0)),
      ev('b', at(1, 9, 0), at(1, 10, 0)),
    ], startOfWeek, 7);

    expect(laneCount[0], 1);
    expect(laneCount[1], 1);
    expect(laneOf['a'], 0);
    expect(laneOf['b'], 0);
  });

  test('events outside the period are ignored', () {
    final (laneOf, laneCount) = computeEventLanes([
      ev('a', at(7, 9, 0), at(7, 10, 0)),
    ], startOfWeek, 7);

    expect(laneOf, isEmpty);
    expect(laneCount, isEmpty);
  });
}
