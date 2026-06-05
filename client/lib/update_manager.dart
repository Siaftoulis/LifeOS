import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_client.dart';
import 'github_update_fetcher.dart';

class UpdateManager extends StatelessWidget {
  final ApiClient? api;
  const UpdateManager({super.key, this.api});

  Future<void> _triggerOTAUpdate() async {
    final baseUrl = ApiClient.instance.baseUrl;
    final otaUrl = baseUrl.replaceAll(':8080', ':8081') + '/app-release.apk';
    final uri = Uri.parse(otaUrl);
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); }
    catch (e) { debugPrint("OTA Launch error: $e"); }
  }

  Future<void> downloadAndInstallAPK() => _triggerOTAUpdate();

  static Future<void> checkForUpdates(BuildContext ctx, ApiClient api) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/version.json').catchError((_) => '{"build_number":0}');
      final local = jsonDecode(jsonStr)['build_number'] ?? 0;
      int remote = -1;
      try { remote = (await api.post('/api/health', {}))['build_number'] ?? -1; } 
      catch (_) { remote = await GitHubUpdateFetcher.fetchLatestVersionTag(); }
      if (remote > local && ctx.mounted) {
        showDialog(context: ctx, builder: (_) => AlertDialog(backgroundColor: const Color(0xFF0A0A0A), title: const Text('Update Available', style: TextStyle(color: Colors.white)), content: Text('Version #$remote is ready to install.', style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
      }
    } catch (e) { debugPrint("Startup check error: $e"); }
  }

  @override Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.all(16), child: ElevatedButton.icon(
      onPressed: _triggerOTAUpdate, icon: const Icon(Icons.system_update, color: Colors.white),
      label: const Text("Check & Install OTA Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withOpacity(0.8), padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ));
  }
}
