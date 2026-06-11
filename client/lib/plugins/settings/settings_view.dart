import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../update_manager.dart';
import '../../diagnostics_panel.dart';
import '../../database/preferences_service.dart';

class SettingsView extends StatelessWidget {
  final dynamic db; final ApiClient api;
  const SettingsView({super.key, required this.db, required this.api});

  @override Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PreferencesService.activeProfileRole,
      builder: (context, _) {
        final isChild = PreferencesService.activeProfileRole.value == 'CHILD';
        
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
                color: isChild ? const Color(0xFF121214).withOpacity(0.5) : const Color(0xFF121214),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(isChild ? Icons.lock : Icons.system_update, color: isChild ? Colors.grey : const Color(0xFF00E5FF)),
                  title: Text(
                    isChild ? 'Check & Install OTA Update (LOCKED)' : 'Check & Install OTA Update',
                    style: TextStyle(color: isChild ? Colors.grey : Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isChild ? 'Locked for child profile access' : 'Fetch latest build from local host or GitHub',
                    style: TextStyle(color: isChild ? Colors.grey.withOpacity(0.5) : Colors.white30, fontSize: 11),
                  ),
                  onTap: isChild ? null : () => UpdateManager(api: api).downloadAndInstallAPK(),
                ),
              ),
              const SizedBox(height: 12),
              if (!isChild) ...[
                Container(
                  height: 250,
                  decoration: BoxDecoration(color: const Color(0xFF121214), borderRadius: BorderRadius.circular(12)),
                  child: DiagnosticsPanel(db: db, api: api),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Diagnostics panel restricted under child permissions.',
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
