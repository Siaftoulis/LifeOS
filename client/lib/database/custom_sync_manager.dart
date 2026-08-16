import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../core/websocket_service.dart';
import '../core/telemetry_service.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  retrying,
  error,
}

class CustomSyncManager {
  final ApiClient api;
  final dynamic db;
  final WebSocketService webSocketService;
  final TelemetryService? telemetryService;
  
  final int maxRetries;
  final int initialDelayMs;
  final double backoffMultiplier;
  final int maxDelayMs;

  bool _isSyncing = false;
  int _retryCount = 0;
  Timer? _pollingScheduler;
  Timer? _retryTimer;

  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(SyncStatus.idle);

  SyncStatus get status => statusNotifier.value;

  CustomSyncManager(
    this.api,
    this.db, {
    required this.webSocketService,
    this.telemetryService,
    this.maxRetries = 5,
    this.initialDelayMs = 1000,
    this.backoffMultiplier = 2.0,
    this.maxDelayMs = 30000,
  }) {
    webSocketService.connect();
  }

  void startPollingScheduler(Duration interval) {
    _pollingScheduler?.cancel();
    _pollingScheduler = Timer.periodic(interval, (_) => runSyncCycle());
  }

  void stopPollingScheduler() {
    _pollingScheduler?.cancel();
    _pollingScheduler = null;
    _retryTimer?.cancel();
  }

  Future<void> runSyncCycle() async {
    if (_isSyncing) return;
    _isSyncing = true;
    statusNotifier.value = SyncStatus.syncing;

    final stopwatch = Stopwatch()..start();

    try {
      final deltas = await _extractDeltas();
      if (deltas.isNotEmpty) {
        final payload = {
          'type': 'sync_push',
          'client_ts': DateTime.now().millisecondsSinceEpoch,
          'deltas': deltas,
        };
        
        webSocketService.send(payload);
      }

      stopwatch.stop();
      _retryCount = 0;
      statusNotifier.value = SyncStatus.synced;
      telemetryService?.logSyncSuccess(
        durationMs: stopwatch.elapsedMilliseconds,
        itemsCount: deltas.length,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint("Sync cycle failed: $e");
      _retryCount++;

      if (_retryCount <= maxRetries) {
        statusNotifier.value = SyncStatus.retrying;
        final delayMs = min(
          (initialDelayMs * pow(backoffMultiplier, _retryCount - 1)).round(),
          maxDelayMs,
        );

        telemetryService?.logSyncRetry(
          attempt: _retryCount,
          nextDelayMs: delayMs,
        );

        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(milliseconds: delayMs), () {
          _isSyncing = false;
          runSyncCycle();
        });
      } else {
        statusNotifier.value = SyncStatus.error;
        telemetryService?.logSyncFailed(
          error: e.toString(),
          attempt: _retryCount,
        );
      }
    } finally {
      if (statusNotifier.value != SyncStatus.retrying) {
        _isSyncing = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _extractDeltas() async {
    final raw = await db.customSelect('SELECT * FROM user_habits WHERE is_dirty = 1').get();
    return (raw as List).map((row) => Map<String, dynamic>.from((row as dynamic).data as Map)).toList();
  }

  Future<void> processInboundPayload(Map<String, dynamic> payload) async {
    await db.transaction(() async {
      for (final r in payload['deltas']) {
        await db.customStatement('''
          INSERT OR REPLACE INTO user_habits (id, name, type, goal_value, updated_at, is_dirty) 
          SELECT ?, ?, ?, ?, ?, 0 WHERE NOT EXISTS (SELECT 1 FROM user_habits WHERE id = ? AND updated_at >= ?)
        ''', [r['id'], r['name'], r['type'], r['goal_value'], r['updated_at'], r['id'], r['updated_at']]);
      }
    });
  }

  void dispose() {
    stopPollingScheduler();
    statusNotifier.dispose();
  }
}


