import 'package:flutter/foundation.dart';
import 'websocket_service.dart';

class TelemetryService {
  final WebSocketService webSocketService;

  TelemetryService({required this.webSocketService});

  void logAction(String actionType, Map<String, dynamic> data) {
    final payload = {
      'type': 'telemetry',
      'action': actionType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    
    // In a real scenario, this would include a cryptographic signature
    // using a device-specific key to prevent cheating.
    
    debugPrint("Logging Telemetry: $actionType");
    webSocketService.send(payload);
  }

  void logQuestCompleted(String questId, String userId) {
    logAction('quest_completed', {
      'questId': questId,
      'userId': userId,
    });
  }

  void logHabitCompleted(String habitId, double amount) {
    logAction('habit_completed', {
      'habitId': habitId,
      'amount': amount,
    });
  }

  void logSyncFailed({required String error, required int attempt}) {
    logAction('sync_failed', {
      'error': error,
      'attempt': attempt,
    });
  }

  void logSyncRetry({required int attempt, required int nextDelayMs}) {
    logAction('sync_retry', {
      'attempt': attempt,
      'nextDelayMs': nextDelayMs,
    });
  }

  void logSyncSuccess({required int durationMs, required int itemsCount}) {
    logAction('sync_success', {
      'durationMs': durationMs,
      'itemsCount': itemsCount,
    });
  }
}
