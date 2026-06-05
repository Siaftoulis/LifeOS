import 'package:flutter/material.dart';
import '../../api_client.dart';

class SpatialEngine extends StatefulWidget {
  final List<List<String>> layout; final int startX, startY; final Widget Function(String) builder;
  const SpatialEngine({super.key, required this.layout, this.startX = 1, this.startY = 1, required this.builder});
  @override State<SpatialEngine> createState() => _SpatialEngineState();
}

class _SpatialEngineState extends State<SpatialEngine> {
  late int x, y; final Map<String, Widget> _cache = {}; Offset _targetOffset = Offset.zero; Duration _aniDuration = Duration.zero;
  @override void initState() { super.initState(); x = widget.startX; y = widget.startY; }
  @override void didUpdateWidget(SpatialEngine old) { super.didUpdateWidget(old); if (y >= widget.layout.length || x >= widget.layout[0].length) { x = 0; y = 0; } }

  void _handleSwipe(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx, vy = d.velocity.pixelsPerSecond.dy;
    setState(() {
      _aniDuration = const Duration(milliseconds: 200); _targetOffset = Offset.zero;
      if (vx.abs() > 500 || vy.abs() > 500) {
        final w = widget.layout[0].length, h = widget.layout.length;
        if (vx.abs() > 500) x = (x + (vx > 0 ? -1 : 1)) % w;
        if (vy.abs() > 500) y = (y + (vy > 0 ? -1 : 1)) % h;
        x = (x + w) % w; y = (y + h) % h;
      }
    });
  }

  @override Widget build(BuildContext context) {
    final mid = widget.layout[y][x]; _cache.putIfAbsent(mid, () => KeyedSubtree(key: ValueKey(mid), child: widget.builder(mid)));
    return Scaffold(backgroundColor: const Color(0xFF09090B), body: Stack(children: [
      GestureDetector(
        onPanUpdate: (d) => setState(() { _aniDuration = Duration.zero; _targetOffset += d.delta; }), onPanEnd: _handleSwipe,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: Offset.zero, end: _targetOffset), duration: _aniDuration, curve: Curves.easeOutCubic,
          builder: (_, offset, child) => Transform.translate(offset: offset, child: child),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1.0).animate(a), child: c)),
            child: _cache[mid],
          ),
        ),
      ),
      Positioned(bottom: 16, left: 0, right: 0, child: IgnorePointer(child: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: ApiClient.instance.queueLengthNotifier,
          builder: (_, v, __) => Text(v > 0 ? '[ $x , $y ] • ◉ $v' : '[ $x , $y ]',
            style: TextStyle(color: v > 0 ? Colors.amberAccent : const Color(0x5500E5FF), fontSize: 12, letterSpacing: 2, fontFamily: 'JetBrainsMono')),
        ),
      ))),
    ]));
  }
}
