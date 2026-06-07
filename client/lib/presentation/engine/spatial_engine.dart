import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class SpatialEngine extends StatefulWidget {
  final List<List<String>> layout;
  final int startX, startY;
  final Widget Function(String, int, int) builder;

  const SpatialEngine({
    super.key,
    required this.layout,
    this.startX = 1,
    this.startY = 1,
    required this.builder,
  });

  @override
  State<SpatialEngine> createState() => _SpatialEngineState();
}

class _SpatialEngineState extends State<SpatialEngine> with SingleTickerProviderStateMixin {
  late int x, y;
  late AnimationController _animCtrl;
  late Animation<Offset> _anim;
  
  Offset _baseOffset = Offset.zero;
  final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);
  
  double _w = 0;
  double _h = 0;

  @override
  void initState() {
    super.initState();
    x = widget.startX;
    y = widget.startY;
    
    _animCtrl = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 350)
    );
    
    _anim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_animCtrl);
    
    _animCtrl.addListener(() {
      _dragOffset.value = _anim.value;
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _dragOffset.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (_animCtrl.isAnimating) return;
    _dragOffset.value += d.delta;
  }

  void _handlePanEnd(DragEndDetails d) {
    if (_animCtrl.isAnimating) return;
    
    final h = widget.layout.length;
    
    int newX = x;
    int newY = y;
    
    final vx = d.velocity.pixelsPerSecond.dx;
    final vy = d.velocity.pixelsPerSecond.dy;
    
    final deltaX = _dragOffset.value.dx - _baseOffset.dx;
    final deltaY = _dragOffset.value.dy - _baseOffset.dy;

    // Ταχύτητα Swipe (Fling)
    if (vx.abs() > vy.abs() && vx.abs() > 300) {
      final w = widget.layout[y].length;
      newX = (x + (vx > 0 ? -1 : 1) + w) % w;
    } else if (vy.abs() > vx.abs() && vy.abs() > 300) {
      newY = (y + (vy > 0 ? -1 : 1) + h) % h;
    } else {
      // Αργό Drag: Άλλαξε οθόνη αν τράβηξες πάνω από το 20% της οθόνης
      if (deltaX.abs() > _w * 0.2) {
         final w = widget.layout[y].length;
         newX = (x + (deltaX > 0 ? -1 : 1) + w) % w;
      } else if (deltaY.abs() > _h * 0.2) {
         newY = (y + (deltaY > 0 ? -1 : 1) + h) % h;
      }
    }
    
    // Ασφάλεια: Αν η νέα σειρά έχει λιγότερα αντικείμενα (για το μέλλον)
    final newRowWidth = widget.layout[newY].length;
    if (newX >= newRowWidth) newX = newRowWidth - 1;

    setState(() { x = newX; y = newY; });
    
    final targetOffset = Offset(-newX * _w, -newY * _h);
    
    _anim = Tween<Offset>(
      begin: _dragOffset.value,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    
    _animCtrl.forward(from: 0).then((_) {
       _baseOffset = targetOffset;
       _dragOffset.value = targetOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
            return const SizedBox.shrink();
          }
          
          if (_w != constraints.maxWidth || _h != constraints.maxHeight) {
            _w = constraints.maxWidth;
            _h = constraints.maxHeight;
            _baseOffset = Offset(-x * _w, -y * _h);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _dragOffset.value = _baseOffset;
            });
          }

          // ΚΡΥΦΗ ΔΥΝΑΜΗ: Χτίζουμε τα γραφικά 1 φορά και τα "κλειδώνουμε" στη μνήμη (RepaintBoundary)
          final List<Widget> cachedChildren = [];
          for (int r = 0; r < widget.layout.length; r++) {
            for (int c = 0; c < widget.layout[r].length; c++) {
              cachedChildren.add(
                RepaintBoundary(
                  child: widget.builder(widget.layout[r][c], r, c),
                )
              );
            }
          }

          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: ValueListenableBuilder<Offset>(
                  valueListenable: _dragOffset,
                  builder: (context, offset, _) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Τοποθετούμε τις 9 οθόνες ΔΥΝΑΜΙΚΑ μέσα στο κανονικό μέγεθος του παραθύρου!
                        for (int r = 0; r < widget.layout.length; r++)
                          for (int c = 0; c < widget.layout[r].length; c++)
                            Positioned(
                              left: c * _w + offset.dx,
                              top: r * _h + offset.dy,
                              width: _w,
                              height: _h,
                              child: cachedChildren[r * widget.layout[r].length + c],
                            ),
                      ],
                    );
                  },
                ),
              ),
              
              // Το Spatial HUD 
              Positioned(
                bottom: 16, left: 0, right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      '[ $x , $y ]',
                      style: const TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
