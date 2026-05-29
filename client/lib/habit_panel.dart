import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HabitMatrixGrid extends StatefulWidget {
  final Stream<List<Map<String, dynamic>>> habitStream;
  final Function(String, bool) onUpdate;
  const HabitMatrixGrid({super.key, required this.habitStream, required this.onUpdate});
  @override State<HabitMatrixGrid> createState() => _HMState();
}

class _HMState extends State<HabitMatrixGrid> {
  List<Map<String, dynamic>> _cache = [];

  void _toggle(int i) {
    setState(() => _cache[i]['done'] = !_cache[i]['done']);
    if (_cache[i]['done']) HapticFeedback.mediumImpact();
    widget.onUpdate(_cache[i]['id'], _cache[i]['done']);
  }

  @override Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.habitStream.distinct(), // Enforce distinct data filter mapping
      builder: (context, snap) {
        if (snap.hasData && !snap.hasError) _cache = snap.data!; // Graceful cache degradation on SQLITE_BUSY
        if (_cache.isEmpty) return const Center(child: Text("No habits defined.", style: TextStyle(color: Colors.grey)));
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 250, mainAxisExtent: 90, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: _cache.length,
          itemBuilder: (_, i) {
            final item = _cache[i];
            final done = item['done'] as bool;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                GestureDetector(onTap: () => _toggle(i), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: done ? Colors.greenAccent : Colors.white10), child: done ? const Icon(Icons.check, color: Colors.black, size: 20) : null)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(item['name'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: done ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: item['streak'] / 30, backgroundColor: Colors.white10, color: Colors.greenAccent, minHeight: 4))
                ]))
              ]),
            );
          },
        );
      },
    );
  }
}
