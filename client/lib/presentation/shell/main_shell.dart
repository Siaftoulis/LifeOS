import 'package:flutter/material.dart';
import '../../api_client.dart'; import '../../database/database.dart';
import '../../core/feature_registry.dart'; import '../engine/spatial_engine.dart'; import '../../database/tasks_extension.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _show = false;
  final TextEditingController _ctr = TextEditingController();

  @override void dispose() { _ctr.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) { if (d.delta.dy > 12) setState(() => _show = true); if (d.delta.dy < -12) setState(() => _show = false); },
      child: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Stack(children: [
          ValueListenableBuilder<List<List<String>>>(
            valueListenable: FeatureRegistry.layoutNotifier,
            builder: (c, layout, _) => SpatialEngine(layout: layout, builder: FeatureRegistry.buildModule),
          ),
          AnimatedPositioned(
            top: _show ? 0 : -120, left: 0, right: 0, height: 100,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFF09090B), border: Border(bottom: BorderSide(color: Color(0xFF00E5FF), width: 1))),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Center(child: TextField(
                controller: _ctr,
                decoration: const InputDecoration(hintText: 'Capture thought...', hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                onSubmitted: (t) {
                  AppDatabase.instance.insertTask(DateTime.now().millisecondsSinceEpoch.toString(), t);
                  ApiClient.instance.post('/api/capture', {'content': t});
                  setState(() { _show = false; _ctr.clear(); });
                },
              )),
            ),
          ),
        ]),
      ),
    );
  }
}
