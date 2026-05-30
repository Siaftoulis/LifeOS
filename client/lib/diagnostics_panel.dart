import 'package:flutter/material.dart';
import 'api_client.dart';
import 'diag_row.dart';
import 'theme.dart';
import 'diagnostics_controller.dart';
import 'database/preferences_service.dart';

class DiagnosticsPanel extends StatefulWidget {
  final dynamic db;
  final ApiClient api;
  const DiagnosticsPanel({super.key, required this.db, required this.api});
  @override State<DiagnosticsPanel> createState() => _DiagState();
}

class _DiagState extends State<DiagnosticsPanel> {
  var _dbStatus = DiagStatus.connecting, _netStatus = DiagStatus.connecting, _verStatus = DiagStatus.connecting;
  String _dbDetail = 'Querying...', _netDetail = 'Pinging...', _verDetail = 'Checking...';
  late final DiagnosticsController _ctrl;

  @override void initState() { 
    super.initState(); 
    _ctrl = DiagnosticsController(widget.db, widget.api);
    _runAll(); 
  }

  Future<void> _runAll() async {
    final res = await Future.wait([_ctrl.checkDb(), _ctrl.checkNet(), _ctrl.checkVer()]);
    if (mounted) setState(() { _dbStatus = res[0].$1; _dbDetail = res[0].$2; _netStatus = res[1].$1; _netDetail = res[1].$2; _verStatus = res[2].$1; _verDetail = res[2].$2; });
  }

  @override Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(top: 24), children: [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Text('SYSTEM DIAGNOSTICS', style: TextStyle(color: OLEDTheme.accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2))),
      DiagRow(label: 'Local Storage', detail: _dbDetail, status: _dbStatus),
      DiagRow(label: 'Mesh Network', detail: _netDetail, status: _netStatus),
      DiagRow(label: 'Binary Version', detail: _verDetail, status: _verStatus),
      const SizedBox(height: 16),
      ListenableBuilder(listenable: PreferencesService.navProfile, builder: (_, __) => Row(mainAxisAlignment: MainAxisAlignment.center, children: ['Swipe', 'Dial', 'Classic'].map((m) => TextButton(onPressed: () => PreferencesService.setNavProfile(m), child: Text(m, style: TextStyle(color: PreferencesService.navProfile.value == m ? OLEDTheme.accent : Colors.grey, fontSize: 11)))).toList())),
      Center(child: TextButton.icon(onPressed: _runAll, icon: const Icon(Icons.refresh, color: OLEDTheme.accent, size: 16), label: const Text('Re-scan', style: TextStyle(color: OLEDTheme.accent, fontSize: 12)))),
    ]);
  }
}
