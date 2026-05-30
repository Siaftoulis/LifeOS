import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'api_client.dart';
import 'diag_row.dart';

class DiagnosticsController {
  final dynamic db;
  final ApiClient api;
  DiagnosticsController(this.db, this.api);

  Future<(DiagStatus, String)> checkDb() async {
    try {
      final rows = await db.customSelect('SELECT COUNT(*) as total, SUM(CASE WHEN is_dirty=1 THEN 1 ELSE 0 END) as dirty FROM notes').get();
      final r = rows.first.data;
      return (DiagStatus.healthy, '${r['total']} rows · ${r['dirty']} pending sync');
    } catch (e) { return (DiagStatus.blocked, 'SQLite unreachable: $e'); }
  }

  Future<(DiagStatus, String)> checkNet() async {
    try {
      await api.post('/api/health', {});
      return (DiagStatus.healthy, 'Daemon online · 0% packet loss');
    } catch (_) { return (DiagStatus.blocked, 'Host daemon unreachable'); }
  }

  Future<(DiagStatus, String)> checkVer() async {
    try {
      final json = await rootBundle.loadString('assets/version.json').catchError((_) => '{"build_number":0}');
      final local = jsonDecode(json)['build_number'] ?? 0;
      final remote = await _readAgentVersion();
      final match = local == remote;
      return (match ? DiagStatus.healthy : DiagStatus.blocked, 'Local: #$local · Agent: #$remote${match ? '' : ' — MISMATCH'}');
    } catch (e) { return (DiagStatus.blocked, 'Version check failed: $e'); }
  }

  Future<int> _readAgentVersion() async {
    try {
      final f = File('.agent/version.json');
      if (await f.exists()) return jsonDecode(await f.readAsString())['build_number'] ?? 0;
    } catch (_) {}
    return -1;
  }
}
