import 'package:flutter/material.dart';

class ServerHub extends StatelessWidget {
  const ServerHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            color: Color(0xFF121214), elevation: 0,
            child: ListTile(
              title: Text('HUAWEI HOST ENGINE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Intel i7-12700H • 45W Base TDP', style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: Text('100% Secure via Tailnet', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11)),
            ),
          ),
          SizedBox(height: 8),
          Card(
            color: Color(0xFF121214), elevation: 0,
            child: ListTile(
              title: Text('HYPER-V VIRTUAL INSTANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Status: Operational • Gesture Locked', style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: Icon(Icons.cloud_done_rounded, color: Color(0xFF00E5FF)),
            ),
          ),
        ],
      ),
    );
  }
}
