import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme/everforest_colors.dart';

class SpatialEngine extends StatefulWidget {
  final List<List<String>> layout; final int startX, startY; final Widget Function(String, int, int) builder;
  const SpatialEngine({super.key, required this.layout, this.startX = 1, this.startY = 1, required this.builder});
  @override State<SpatialEngine> createState() => _SpatialEngineState();
}

class _SpatialEngineState extends State<SpatialEngine> {
  late int x, y; final Map<String, Widget> _cache = {}; Offset _targetOffset = Offset.zero; Duration _aniDuration = Duration.zero;
  @override void initState() { super.initState(); x = widget.startX; y = widget.startY; }
  @override void didUpdateWidget(SpatialEngine old) {
    super.didUpdateWidget(old);
    _cache.clear();
    if (y >= widget.layout.length) { y = 0; }
    if (x >= widget.layout[y].length) { x = 0; }
  }

  void _handleSwipe(DragEndDetails d) {
    final dx = d.velocity.pixelsPerSecond.dx; final dy = d.velocity.pixelsPerSecond.dy;
    setState(() {
      _aniDuration = const Duration(milliseconds: 200); _targetOffset = Offset.zero;
      final h = widget.layout.length;
      if (dx.abs() > dy.abs() && dx.abs() > 300) {
        final w = widget.layout[y].length;
        x = (x + (dx > 0 ? -1 : 1) + w) % w;
      } else if (dy.abs() > dx.abs() && dy.abs() > 300) {
        y = (y + (dy > 0 ? -1 : 1) + h) % h;
        final w = widget.layout[y].length;
        if (x >= w) x = w - 1;
      }
    });
  }

  @override Widget build(BuildContext context) {
    final mid = widget.layout[y][x]; _cache.putIfAbsent(mid, () => KeyedSubtree(key: ValueKey(mid), child: widget.builder(mid, y, x)));
    return Scaffold(backgroundColor: EverforestColors.bg0, body: Stack(children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => setState(() { _aniDuration = Duration.zero; _targetOffset += d.delta; }), onPanEnd: _handleSwipe,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: Offset.zero, end: _targetOffset), duration: _aniDuration, curve: Curves.easeOutCubic,
          builder: (_, offset, child) => Transform.translate(offset: offset, child: child),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) { if (n is OverscrollNotification) { return false; } return false; },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1.0).animate(a), child: c)),
              child: _cache[mid],
            ),
          ),
        ),
      ),
      Positioned(bottom: 16, left: 0, right: 0, child: IgnorePointer(child: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: ApiClient.instance.queueLengthNotifier,
          builder: (_, v, __) => Text(v > 0 ? '[ $x , $y ] • ◉ $v' : '[ $x , $y ]',
            style: TextStyle(color: v > 0 ? EverforestColors.yellow : EverforestColors.grey, fontSize: 12, letterSpacing: 2, fontFamily: 'JetBrainsMono')),
        ),
      ))),
    ]));
  }
}
