import 'package:flutter/material.dart';
import '../../core/feature_registry.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: const Color(0xFF121214), child: ListTile(
          title: const Text('ROTATE SPATIAL GRID', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('Shift 3x3 layout matrix axis', style: TextStyle(color: Colors.white38, fontSize: 11)),
          trailing: IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded, color: Color(0xFF00E5FF)),
            onPressed: () => FeatureRegistry.rotateLayout(),
          ),
        )),
        const SizedBox(height: 12),
        const Card(color: Color(0xFF121214), child: ListTile(
          title: Text('MOTOROLA EDGE 50 FUSION', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('P2P Client Node Core • Android 14 OS', style: TextStyle(color: Colors.white38, fontSize: 11)),
          trailing: Icon(Icons.phone_android_rounded, color: Color(0xFF00E5FF)),
        )),
      ]),
    );
  }
}
