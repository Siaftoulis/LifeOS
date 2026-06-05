import 'package:flutter/material.dart';

class SystemLogs extends StatelessWidget {
  const SystemLogs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('LOG // [00:01:22] -> SYSTEM_CORE_BOOT_SUCCESSFUL', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontFamily: 'JetBrainsMono')),
          SizedBox(height: 8),
          Text('LOG // [00:01:23] -> TAILSCALE_NET_SECURE_MESH_ALIGNED', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'JetBrainsMono')),
          SizedBox(height: 8),
          Text('LOG // [00:01:25] -> DRIFT_SQLITE_REACTIVE_STREAM_ACTIVE', style: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}
