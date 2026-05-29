import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../api_client.dart';

class CustomSyncManager {
  final ApiClient api;
  final dynamic db;
  bool _isSyncing = false;
  CustomSyncManager(this.api, this.db);

  Future<void> runSyncCycle() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final deltas = await _extractDeltas();
      if (deltas.isEmpty) return;
      
      final packet = jsonEncode({'client_ts': DateTime.now().millisecondsSinceEpoch, 'deltas': deltas});
      final compressed = base64Encode(gzip.encode(utf8.encode(packet)));
      
      final res = await api.post('/api/sync/push', {'data': compressed});
      if (res['status'] == 'ok' && res['inbound_b64'] != null) {
        await processInboundPayload(res['inbound_b64']);
      }
    } catch (e) {
      // Absorb transient network failures
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<Map<String, dynamic>>> _extractDeltas() async {
    final raw = await db.customSelect('SELECT * FROM habits WHERE is_dirty = 1').get();
    return raw.map((row) => row.data).toList();
  }

  Future<void> processInboundPayload(String base64Data) async {
    final dec = jsonDecode(utf8.decode(gzip.decode(base64Decode(base64Data))));
    await db.transaction(() async {
      for (final r in dec['deltas']) {
        await db.customStatement('''
          INSERT OR REPLACE INTO habits (id, name, done, streak, updated_at, is_dirty) 
          SELECT ?, ?, ?, ?, ?, 0 WHERE NOT EXISTS (SELECT 1 FROM habits WHERE id = ? AND updated_at >= ?)
        ''', [r['id'], r['name'], r['done'], r['streak'], r['updated_at'], r['id'], r['updated_at']]);
      }
    });
  }
}
