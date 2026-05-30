import 'package:flutter/material.dart';

class HabitRing extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const HabitRing({super.key, required this.item, required this.onTap});
  @override State<HabitRing> createState() => _HRState();
}

class _HRState extends State<HabitRing> {
  bool _p = false;
  @override Widget build(BuildContext context) {
    final done = widget.item['done'] == 1;
    final progress = done ? 1.0 : (widget.item['streak'] ?? 0) / 30.0;
    const cyan = Color(0xFF00E5FF);

    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) { setState(() => _p = false); widget.onTap(); },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.9 : 1.0, duration: const Duration(milliseconds: 100),
        child: Container(
          width: 72, margin: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 56, height: 56, child: CircularProgressIndicator(value: progress, backgroundColor: Colors.white10, color: done ? cyan : Colors.white54, strokeWidth: 4)),
                  Icon(Icons.local_fire_department, color: done ? cyan : Colors.white70, size: 24),
                  if (done) Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x6600E5FF), blurRadius: 15), BoxShadow(color: Color(0x3300E5FF), blurRadius: 10, spreadRadius: -5, blurStyle: BlurStyle.inner)])),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.item['name'], style: TextStyle(color: done ? cyan : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}
