import 'package:uuid/uuid.dart';
import '../../../core/general_engine/engine_repository.dart';
import '../../../core/general_engine/general_engine_client.dart';

class CHTMAutoScheduler {
  /// Scans unscheduled tasks for [selectedDate] and places them into open calendar slots
  static Future<int> autoScheduleTasks(DateTime selectedDate) async {
    final events = EngineRepository.instance.events;
    final tasks = EngineRepository.instance.tasks;

    // Filter events for the target day
    final dayEvents = events.where((e) {
      final start = DateTime.tryParse(e.payload['start_time'] ?? '');
      if (start == null) return false;
      return start.year == selectedDate.year &&
          start.month == selectedDate.month &&
          start.day == selectedDate.day;
    }).toList();

    // Determine occupied time intervals (in minutes from midnight)
    final List<Map<String, int>> occupied = [];
    for (var event in dayEvents) {
      final start = DateTime.tryParse(event.payload['start_time'] ?? '');
      final end = DateTime.tryParse(event.payload['end_time'] ?? '');
      if (start != null && end != null) {
        final startMin = start.hour * 60 + start.minute;
        final endMin = end.hour * 60 + end.minute;
        occupied.add({'start': startMin, 'end': endMin});
      }
    }

    // Sort occupied intervals
    occupied.sort((a, b) => a['start']!.compareTo(b['start']!));

    // Working hours: 09:00 (540 mins) to 20:00 (1200 mins)
    int currentMinute = 540; // 9:00 AM
    const int endOfDayMinute = 1200; // 8:00 PM

    // Unscheduled tasks for today (status != completed and no event assigned)
    final pendingTasks = tasks.where((t) {
      final status = t.payload['status'];
      final isScheduled = t.payload['is_scheduled'] == true;
      return status != 'completed' && !isScheduled;
    }).toList();

    int scheduledCount = 0;

    for (var task in pendingTasks) {
      final int durationMins = (task.payload['duration_minutes'] as int?) ?? 45;

      // Find next free slot >= durationMins
      while (currentMinute + durationMins <= endOfDayMinute) {
        bool conflict = false;
        final int slotStart = currentMinute;
        final int slotEnd = currentMinute + durationMins;

        for (var occ in occupied) {
          if (!(slotEnd <= occ['start']! || slotStart >= occ['end']!)) {
            conflict = true;
            // Move currentMinute to after this occupied slot
            currentMinute = occ['end']!;
            break;
          }
        }

        if (!conflict) {
          // Found a slot! Create a scheduled event for this task
          final startTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            slotStart ~/ 60,
            slotStart % 60,
          );
          final endTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            slotEnd ~/ 60,
            slotEnd % 60,
          );

          final eventEntity = GeneralEngineEntity(
            id: const Uuid().v4(),
            type: 'event',
            creatorId: task.creatorId,
            payload: {
              'title': '⚡ Task: ${task.payload['title'] ?? 'Untitled'}',
              'start_time': startTime.toIso8601String(),
              'end_time': endTime.toIso8601String(),
              'color_code': '#A6E3A1', // Green for auto-scheduled
              'task_id': task.id,
            },
            sharedWith: task.sharedWith,
            assignedTo: task.assignedTo,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await EngineRepository.instance.saveEntity(eventEntity);

          // Mark task as scheduled
          final updatedPayload = Map<String, dynamic>.from(task.payload);
          updatedPayload['is_scheduled'] = true;
          final updatedTask = GeneralEngineEntity(
            id: task.id,
            type: task.type,
            creatorId: task.creatorId,
            payload: updatedPayload,
            sharedWith: task.sharedWith,
            assignedTo: task.assignedTo,
            createdAt: task.createdAt,
            updatedAt: DateTime.now(),
          );
          await EngineRepository.instance.saveEntity(updatedTask);

          // Update occupied & currentMinute
          occupied.add({'start': slotStart, 'end': slotEnd});
          occupied.sort((a, b) => a['start']!.compareTo(b['start']!));
          currentMinute = slotEnd + 15; // 15-minute buffer
          scheduledCount++;
          break;
        }
      }
    }

    return scheduledCount;
  }
}
