import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../core/websocket_service.dart';

class CustomSyncManager {
  final ApiClient api;
  final dynamic db;
  final WebSocketService webSocketService;
  bool _isSyncing = false;
  Timer? _pollingScheduler;

  CustomSyncManager(this.api, this.db, {required this.webSocketService}) {
    webSocketService.connect();
  }

  void startPollingScheduler(Duration interval) {
    _pollingScheduler?.cancel();
    _pollingScheduler = Timer.periodic(interval, (_) => runSyncCycle());
  }

  void stopPollingScheduler() {
    _pollingScheduler?.cancel();
    _pollingScheduler = null;
  }

  Future<void> runSyncCycle() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final deltas = await _extractDeltas();
      if (deltas.isEmpty) return;
      
      final payload = {
        'type': 'sync_push',
        'client_ts': DateTime.now().millisecondsSinceEpoch,
        'deltas': deltas,
      };
      
      // Push via WebSocket instead of REST polling
      webSocketService.send(payload);
      
    } catch (e) {
      debugPrint("Sync cycle failed: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<Map<String, dynamic>>> _extractDeltas() async {
    final raw = await db.customSelect('SELECT * FROM user_habits WHERE is_dirty = 1').get();
    return raw.map((row) => row.data).toList();
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
}

