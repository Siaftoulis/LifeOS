import 'dart:async';
import 'package:flutter/material.dart';

class CameraViewport extends StatefulWidget {
  const CameraViewport({super.key});
  @override State<CameraViewport> createState() => _CameraViewportState();
}

class _CameraViewportState extends State<CameraViewport> {
  Timer? _uiTimer; int _fps = 0; double _kbps = 0.0;

  @override void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() { _fps = 58 + (DateTime.now().millisecond % 3); _kbps = 1200.0 + (DateTime.now().millisecond * 0.5); });
    });
  }
  @override void dispose() { _uiTimer?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(children: [
        const Center(child: Icon(Icons.filter_center_focus_rounded, color: Colors.white10, size: 120)),
        Positioned(top: 16, left: 16, child: Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('REC // STREAM_01 // $_fps FPS // ${_kbps.toStringAsFixed(1)} KB/S',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'JetBrainsMono')),
        ])),
        const Positioned(bottom: 16, left: 16,
          child: Text('P2P MESH STABLE // SOURCE: MOTOROLA', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontFamily: 'JetBrainsMono'))),
      ]),
    );
  }
}
