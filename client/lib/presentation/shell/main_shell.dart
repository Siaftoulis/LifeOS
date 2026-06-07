import 'package:flutter/material.dart';
import '../../api_client.dart'; import '../../database/database.dart';
import '../../core/feature_registry.dart'; import '../engine/spatial_engine.dart'; import '../../database/tasks_extension.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _showSearch = false;
  final TextEditingController _ctr = TextEditingController();
  @override void dispose() { _ctr.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: GestureDetector(
        onLongPressMoveUpdate: (d) { if (d.offsetFromOrigin.dy > 50) setState(() => _showSearch = true); },
        child: Stack(children: [
          ValueListenableBuilder<List<List<String>>>(
            valueListenable: FeatureRegistry.layoutNotifier,
            builder: (c, layout, _) => SpatialEngine(layout: layout, builder: FeatureRegistry.buildModule),
          ),
          AnimatedPositioned(
            top: _showSearch ? 0 : -110, left: 0, right: 0, height: 90,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onVerticalDragUpdate: (d) { if (d.delta.dy < -10) setState(() => _showSearch = false); },
              child: Container(
                decoration: const BoxDecoration(color: Color(0xEE09090B), border: Border(bottom: BorderSide(color: Color(0xFF00E5FF), width: 1))),
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  const Icon(Icons.search, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(
                    controller: _ctr,
                    style: const TextStyle(color: Colors.white, fontFamily: 'JetBrainsMono'),
                    decoration: const InputDecoration(hintText: 'Fuzzy search nexus...', hintStyle: TextStyle(color: Colors.white30, fontFamily: 'JetBrainsMono'), border: InputBorder.none),
                    onChanged: (text) => debugPrint('Fuzzy indexing: $text'),
                    onSubmitted: (t) {
                      AppDatabase.instance.insertTask(DateTime.now().millisecondsSinceEpoch.toString(), t);
                      ApiClient.instance.post('/api/capture', {'content': t});
                      setState(() { _showSearch = false; _ctr.clear(); });
                    },
                  )),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
