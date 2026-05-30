import 'package:flutter/material.dart';

class RadialDial extends StatefulWidget {
  final PageController pageController;
  const RadialDial({super.key, required this.pageController});
  @override State<RadialDial> createState() => _RadialDialState();
}

class _RadialDialState extends State<RadialDial> {
  Offset? _center; bool _expanded = false; int _active = -1;
  Offset _pos = Offset.zero;

  double get dx => _center != null ? _pos.dx - _center!.dx : 0;
  double get dy => _center != null ? _pos.dy - _center!.dy : 0;

  int get activeQuadrant {
    if (dx > 0 && dy < 0) return 0; // Gallery
    if (dx < 0 && dy < 0) return 1; // Notes
    if (dx < 0 && dy > 0) return 2; // Habits
    return 3;                       // Capture
  }

  void _onUp() {
    if (_expanded && _active != -1) {
      widget.pageController.animateToPage([6, 5, 1, 0][_active], duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
    setState(() { _expanded = false; _center = null; _active = -1; });
  }

  @override Widget build(BuildContext context) {
    return Stack(children: [
      if (_expanded) Positioned.fill(child: Listener(
        onPointerMove: (e) => setState(() { _pos = e.position; _active = activeQuadrant; }),
        onPointerUp: (_) => _onUp(),
        child: Container(
          color: const Color(0x1A7C3AED),
          child: Stack(alignment: Alignment.bottomCenter, children: [
            Positioned(bottom: -60, child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black54, border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 2)))),
            ...List.generate(4, (i) => _sector(i)),
          ]),
        ),
      )),
      Align(alignment: Alignment.bottomCenter, child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Listener(
          onPointerDown: (e) => setState(() { _center = _pos = e.position; _expanded = true; }),
          child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x66000000), border: Border.all(color: const Color(0xFF00E5FF), width: 2)), child: const Icon(Icons.radio_button_checked, color: Color(0xFF00E5FF))),
        ),
      )),
    ]);
  }

  Widget _sector(int i) {
    final sel = _active == i; final align = [const Alignment(0.4, 0.75), const Alignment(-0.4, 0.75), const Alignment(-0.4, 0.95), const Alignment(0.4, 0.95)][i];
    return Align(alignment: align, child: Text(['Gallery', 'Notes', 'Habits', 'Capture'][i], style: TextStyle(color: sel ? const Color(0xFF00E5FF) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13)));
  }
}
