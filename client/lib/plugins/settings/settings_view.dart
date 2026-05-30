import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../update_manager.dart';
import '../../diagnostics_panel.dart';

class SettingsView extends StatelessWidget {
  final dynamic db; final ApiClient api;
  const SettingsView({super.key, required this.db, required this.api});

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Card(
            color: const Color(0xFF121214),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.system_update, color: Color(0xFF00E5FF)),
              title: const Text('Check & Install OTA Update', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Fetch latest build from local host or GitHub', style: TextStyle(color: Colors.white30, fontSize: 11)),
              onTap: () => UpdateManager(api: api).downloadAndInstallAPK(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            decoration: BoxDecoration(color: const Color(0xFF121214), borderRadius: BorderRadius.circular(12)),
            child: DiagnosticsPanel(db: db, api: api),
          ),
        ],
      ),
    );
  }
}
