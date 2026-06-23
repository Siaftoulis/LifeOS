import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import '../../theme/everforest_colors.dart';
import '../../database/preferences_service.dart';

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
  State<SpatialEngine> createState() => SpatialEngineState();
}

class SpatialEngineState extends State<SpatialEngine> with SingleTickerProviderStateMixin {
  late int x, y;
  late AnimationController _animCtrl;
  late Animation<Offset> _anim;
  
  bool _hasBumpedInCurrentDrag = false;
  DateTime? _lastBumpTime;
  String? _lastBumpDirection;
  
  Offset _baseOffset = Offset.zero;
  final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);
  
  double _w = 0;
  double _h = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(SpatialEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.layout != oldWidget.layout) {
      if (widget.layout.isNotEmpty) {
        y = y.clamp(0, widget.layout.length - 1);
        if (widget.layout[y].isNotEmpty) {
          x = x.clamp(0, widget.layout[y].length - 1);
        } else {
          x = 0;
        }
      } else {
        x = 0;
        y = 0;
      }
    }
  }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _dragOffset.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!PreferencesService.spatialGestures.value) return false;

    if (notification is ScrollStartNotification) {
      _hasBumpedInCurrentDrag = false;
    } else if (notification is ScrollUpdateNotification) {
      if (_hasBumpedInCurrentDrag) return false;

      final metrics = notification.metrics;
      final delta = notification.scrollDelta ?? 0.0;
      if (delta == 0) return false;

      final atTop = metrics.pixels <= metrics.minScrollExtent;
      final atBottom = metrics.pixels >= metrics.maxScrollExtent;

      if (atTop && delta < -1.0) {
        _hasBumpedInCurrentDrag = true;
        _registerBump('up');
      } else if (atBottom && delta > 1.0) {
        _hasBumpedInCurrentDrag = true;
        _registerBump('down');
      }
    } else if (notification is ScrollEndNotification) {
      _hasBumpedInCurrentDrag = false;
    }
    return false;
  }

  void _registerBump(String direction) {
    final now = DateTime.now();
    if (_lastBumpDirection == direction && _lastBumpTime != null) {
      final diff = now.difference(_lastBumpTime!);
      if (diff.inMilliseconds > 100 && diff.inMilliseconds < 800) {
        _lastBumpTime = null;
        _lastBumpDirection = null;
        if (direction == 'up') {
          _nav(0, -1);
        } else {
          _nav(0, 1);
        }
        return;
      }
    }
    _lastBumpTime = now;
    _lastBumpDirection = direction;
  }

  bool _isOverInteractiveWidget(Offset globalPosition) {
    const double deadZoneRadius = 24.0;
    final offsets = [
      Offset.zero,
      const Offset(deadZoneRadius, 0),
      const Offset(-deadZoneRadius, 0),
      const Offset(0, deadZoneRadius),
      const Offset(0, -deadZoneRadius),
      const Offset(deadZoneRadius * 0.707, deadZoneRadius * 0.707),
      const Offset(-deadZoneRadius * 0.707, deadZoneRadius * 0.707),
      const Offset(deadZoneRadius * 0.707, -deadZoneRadius * 0.707),
      const Offset(-deadZoneRadius * 0.707, -deadZoneRadius * 0.707),
      const Offset(12.0, 0),
      const Offset(-12.0, 0),
      const Offset(0, 12.0),
      const Offset(0, -12.0),
    ];

    for (final offset in offsets) {
      final point = globalPosition + offset;
      try {
        final hitTestResult = HitTestResult();
        GestureBinding.instance.hitTest(hitTestResult, point);
        for (final entry in hitTestResult.path) {
          final target = entry.target;
          final targetName = target.runtimeType.toString().toLowerCase();
          
          if (targetName.contains('semanticsgesturehandler') ||
              targetName.contains('inkwell') ||
              targetName.contains('inksplash') ||
              targetName.contains('inkfeatures') ||
              targetName.contains('renderink') ||
              targetName.contains('button') ||
              targetName.contains('switch') ||
              targetName.contains('toggle') ||
              targetName.contains('checkbox') ||
              targetName.contains('radio') ||
              targetName.contains('editable') ||
              targetName.contains('textfield') ||
              targetName.contains('input') ||
              targetName.contains('field') ||
              targetName.contains('menu') ||
              targetName.contains('popup') ||
              targetName.contains('dropdown') ||
              targetName.contains('dialog') ||
              targetName.contains('overlay') ||
              targetName.contains('select') ||
              targetName.contains('picker') ||
              targetName.contains('slider') ||
              targetName.contains('scrollbar')) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (_animCtrl.isAnimating) return;
    _dragOffset.value += d.delta;
  }

  void navigateTo(int newX, int newY) {
    if (_animCtrl.isAnimating) return;

    setState(() {
      x = newX;
      y = newY;
    });

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

  void _nav(int dx, int dy) {
    if (_animCtrl.isAnimating) return;
    final h = widget.layout.length;
    final w = widget.layout[y].length;
    int newX = (x + dx + w) % w;
    int newY = (y + dy + h) % h;
    final newRowWidth = widget.layout[newY].length;
    if (newX >= newRowWidth) newX = newRowWidth - 1;
    navigateTo(newX, newY);
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
    if (vx.abs() > vy.abs() && vx.abs() > 200) {
      final w = widget.layout[y].length;
      newX = (x + (vx > 0 ? -1 : 1) + w) % w;
    } else if (vy.abs() > vx.abs() && vy.abs() > 200) {
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

    navigateTo(newX, newY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      body: ValueListenableBuilder<bool>(
        valueListenable: PreferencesService.spatialGestures,
        builder: (context, gesturesEnabled, _) {
          return LayoutBuilder(
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
              final List<List<Widget>> cachedChildren = [];
              for (int r = 0; r < widget.layout.length; r++) {
                final rowChildren = <Widget>[];
                for (int c = 0; c < widget.layout[r].length; c++) {
                  rowChildren.add(
                    RepaintBoundary(
                      child: widget.builder(widget.layout[r][c], r, c),
                    )
                  );
                }
                cachedChildren.add(rowChildren);
              }

              final colW = _w / 3;
              final rowH = _h / 3;

              return Focus(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: (FocusNode node, KeyEvent event) {
                  if (event is KeyDownEvent) {
                    final key = event.logicalKey;
                    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
                      _nav(-1, 0);
                      return KeyEventResult.handled;
                    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
                      _nav(1, 0);
                      return KeyEventResult.handled;
                    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
                      _nav(0, -1);
                      return KeyEventResult.handled;
                    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
                      _nav(0, 1);
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: Stack(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _focusNode.requestFocus();
                        },
                        onPanDown: (_) {
                          _focusNode.requestFocus();
                        },
                        onPanUpdate: gesturesEnabled ? _handlePanUpdate : null,
                        onPanEnd: gesturesEnabled ? _handlePanEnd : null,
                        onDoubleTapDown: (details) {
                          if (_isOverInteractiveWidget(details.globalPosition)) return;
                          PreferencesService.setSpatialGestures(!PreferencesService.spatialGestures.value);
                        },
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
                                      child: cachedChildren[r][c],
                                    ),
                              ],
                            );
                          },
                        ),
                      ),
                      
                      // Kotatsu 3x3 Overlay Grid System (Active ONLY when spatialGestures is disabled)
                      if (!gesturesEnabled) ...[
                        // Left Column overlay zone (Column 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          width: colW,
                          height: _h,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _focusNode.requestFocus();
                              _nav(-1, 0);
                            },
                            onDoubleTapDown: (details) {
                              if (_isOverInteractiveWidget(details.globalPosition)) return;
                              PreferencesService.setSpatialGestures(!PreferencesService.spatialGestures.value);
                            },
                            onHorizontalDragEnd: (details) {
                              final vx = details.velocity.pixelsPerSecond.dx;
                              if (vx.abs() > 200) {
                                _nav(vx > 0 ? -1 : 1, 0);
                              }
                            },
                          ),
                        ),
                        // Right Column overlay zone (Column 2)
                        Positioned(
                          right: 0,
                          top: 0,
                          width: colW,
                          height: _h,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _focusNode.requestFocus();
                              _nav(1, 0);
                            },
                            onDoubleTapDown: (details) {
                              if (_isOverInteractiveWidget(details.globalPosition)) return;
                              PreferencesService.setSpatialGestures(!PreferencesService.spatialGestures.value);
                            },
                            onHorizontalDragEnd: (details) {
                              final vx = details.velocity.pixelsPerSecond.dx;
                              if (vx.abs() > 200) {
                                _nav(vx > 0 ? -1 : 1, 0);
                              }
                            },
                          ),
                        ),
                        // Top Center overlay zone (Column 1, Row 0)
                        Positioned(
                          left: colW,
                          top: 0,
                          width: colW,
                          height: rowH,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _focusNode.requestFocus();
                              _nav(0, -1);
                            },
                            onDoubleTapDown: (details) {
                              if (_isOverInteractiveWidget(details.globalPosition)) return;
                              PreferencesService.setSpatialGestures(!PreferencesService.spatialGestures.value);
                            },
                            onVerticalDragEnd: (details) {
                              final vy = details.velocity.pixelsPerSecond.dy;
                              if (vy.abs() > 200) {
                                _nav(0, vy > 0 ? -1 : 1);
                              }
                            },
                          ),
                        ),
                        // Bottom Center overlay zone (Column 1, Row 2)
                        Positioned(
                          left: colW,
                          bottom: 0,
                          width: colW,
                          height: rowH,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _focusNode.requestFocus();
                              _nav(0, 1);
                            },
                            onDoubleTapDown: (details) {
                              if (_isOverInteractiveWidget(details.globalPosition)) return;
                              PreferencesService.setSpatialGestures(!PreferencesService.spatialGestures.value);
                            },
                            onVerticalDragEnd: (details) {
                              final vy = details.velocity.pixelsPerSecond.dy;
                              if (vy.abs() > 200) {
                                _nav(0, vy > 0 ? -1 : 1);
                              }
                            },
                          ),
                        ),
                      ],

                      // Το Spatial HUD 
                      Positioned(
                        bottom: 16, left: 0, right: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: Text(
                              '[ $x , $y ] ${gesturesEnabled ? "• GESTURES" : "• GRID"}',
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
