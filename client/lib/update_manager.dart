import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_client.dart';

class UpdateManager extends StatelessWidget {
  final ApiClient api;
  const UpdateManager({super.key, required this.api});

  Future<void> downloadAndInstallAPK() async {
    try {
      final req = await HttpClient().getUrl(Uri.parse('${api.baseUrl}/api/update/download'));
      final res = await req.close();
      
      final file = File('/data/user/0/com.lifeos.app/cache/update.apk');
      final sink = file.openWrite();
      // Low-Memory Chunked Download to prevent heap exhaustion
      await res.forEach((chunk) => sink.add(chunk)); 
      await sink.close();

      const chan = MethodChannel('com.lifeos.app/installer');
      await chan.invokeMethod('installApk', {'path': file.path});
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: downloadAndInstallAPK,
        icon: const Icon(Icons.system_update, color: Colors.white),
        label: const Text("Check & Install OTA Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withOpacity(0.8), padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}
