import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:clock/clock.dart';
import '../../theme/everforest_colors.dart';
import '../widgets/keyboard_integrity/smooth_keyboard_integrity.dart';

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
  
  bool _isFirstLayout = true;
  Offset _baseOffset = Offset.zero;
  final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);
  
  double _w = 0;
  double _h = 0;
  final FocusNode _focusNode = FocusNode();

  final List<(int, int)> _backStack = [];
  bool _isBackNav = false;
  DateTime? _lastEscapeAt;

  List<List<Widget>> _cachedModules = [];

  void _buildModuleCache() {
    _cachedModules = [];
    for (int r = 0; r < widget.layout.length; r++) {
      final rowChildren = <Widget>[];
      for (int c = 0; c < widget.layout[r].length; c++) {
        rowChildren.add(
          widget.builder(widget.layout[r][c], r, c),
        );
      }
      _cachedModules.add(rowChildren);
    }
  }

  @override
  void didUpdateWidget(SpatialEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.layout != oldWidget.layout) {
      _buildModuleCache();
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
    _buildModuleCache();
    
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
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Inner scroll views (ListView, SingleChildScrollView, etc.) handle their own scrolling.
    // We do not bump screens on normal scroll updates or overscroll to prevent disrupting inner navigation.
    return false;
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (_animCtrl.isAnimating) return;
    _dragOffset.value += d.delta;
  }

  void navigateTo(int newX, int newY) {
    final isBack = _isBackNav;
    _isBackNav = false;
    if (_animCtrl.isAnimating) return;

    if (!isBack && (newX != x || newY != y)) {
      _backStack.add((x, y));
    }

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

  void nav(int dx, int dy) {
    if (_animCtrl.isAnimating) return;
    final h = widget.layout.length;
    final w = widget.layout[y].length;
    int newX = (x + dx + w) % w;
    int newY = (y + dy + h) % h;
    final newRowWidth = widget.layout[newY].length;
    if (newX >= newRowWidth) newX = newRowWidth - 1;
    navigateTo(newX, newY);
  }

  void _goBack() {
    if (_backStack.isEmpty) return;
    _animCtrl.stop();
    final prev = _backStack.removeLast();
    _isBackNav = true;
    navigateTo(prev.$1, prev.$2);
  }

  void _goHome() {
    _backStack.clear();
    _animCtrl.stop();
    for (int r = 0; r < widget.layout.length; r++) {
      for (int c = 0; c < widget.layout[r].length; c++) {
        if (widget.layout[r][c] == 'home') {
          _isBackNav = true;
          navigateTo(c, r);
          return;
        }
      }
    }
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

  bool _isUserTyping() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;
    final context = primaryFocus.context;
    if (context == null) return false;
    
    final currentType = context.widget.runtimeType.toString();
    if (context.widget is EditableText ||
        currentType.contains('EditableText') ||
        currentType.contains('TextField') ||
        currentType.contains('TextFormField') ||
        currentType.contains('AppFlowy') ||
        currentType.contains('Editor') ||
        currentType.contains('RichText') ||
        currentType.contains('Selectable')) {
      return true;
    }
    
    bool isEditable = false;
    context.visitAncestorElements((element) {
      final type = element.widget.runtimeType.toString();
      if (element.widget is EditableText || 
          type.contains('EditableText') || 
          type.contains('TextField') || 
          type.contains('TextFormField') ||
          type.contains('AppFlowy') ||
          type.contains('Editor') ||
          type.contains('RichText') ||
          type.contains('Zen')) {
        isEditable = true;
        return false;
      }
      return true;
    });
    return isEditable;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double trueWidth = constraints.maxWidth;
          final double trueHeight = constraints.maxHeight + mq.viewInsets.bottom;


              if (trueWidth == 0 || trueHeight == 0) {
                return const SizedBox.shrink();
              }
              
              if (_w != trueWidth || _h != trueHeight) {
                _w = trueWidth;
                _h = trueHeight;
                _baseOffset = Offset(-x * _w, -y * _h);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_isFirstLayout) _isFirstLayout = false;
                  _dragOffset.value = _baseOffset;
                });
              }

              // ΚΡΥΦΗ ΔΥΝΑΜΗ: Χρησιμοποιούμε τα προ-φορτωμένα γραφικά (cached modules) 
              // έτσι ώστε να μην γίνεται ΚΑΝΕΝΑ απολύτως build στις οθόνες!
              final List<List<Widget>> cachedChildren = [];
              for (int r = 0; r < widget.layout.length; r++) {
                final rowChildren = <Widget>[];
                for (int c = 0; c < widget.layout[r].length; c++) {
                  rowChildren.add(
                    SmoothKeyboardIntegrity(
                      isActive: (c == x && r == y),
                      child: RepaintBoundary(
                        child: _cachedModules[r][c],
                      ),
                    )
                  );
                }
                cachedChildren.add(rowChildren);
              }

              return Focus(
                focusNode: _focusNode,

                skipTraversal: true,
                onKeyEvent: (FocusNode node, KeyEvent event) {
                  if (_isUserTyping()) return KeyEventResult.ignored;

                  if (event is KeyDownEvent) {
                    final key = event.logicalKey;

                    if (key == LogicalKeyboardKey.escape) {
                      // ανοιχτό dialog/μενού: το κλείνει πρώτα το Navigator
                      if (Navigator.of(context).canPop()) return KeyEventResult.ignored;
                      _focusNode.requestFocus();
                      final now = clock.now();
                      final isDoubleEscape = _lastEscapeAt != null &&
                          now.difference(_lastEscapeAt!) < const Duration(milliseconds: 400);
                      _lastEscapeAt = now;
                      if (isDoubleEscape) {
                        _goHome();
                      } else {
                        _goBack();
                      }
                      return KeyEventResult.handled;
                    }

                    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

                    if (isCtrlPressed) {
                      if (key == LogicalKeyboardKey.arrowLeft) {
                        nav(-1, 0);
                        return KeyEventResult.handled;
                      } else if (key == LogicalKeyboardKey.arrowRight) {
                        nav(1, 0);
                        return KeyEventResult.handled;
                      } else if (key == LogicalKeyboardKey.arrowUp) {
                        nav(0, -1);
                        return KeyEventResult.handled;
                      } else if (key == LogicalKeyboardKey.arrowDown) {
                        nav(0, 1);
                        return KeyEventResult.handled;
                      }
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: Stack(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (details) {
                          final hitTestResult = HitTestResult();
                          WidgetsBinding.instance.hitTestInView(
                            hitTestResult,
                            details.globalPosition,
                            View.of(context).viewId,
                          );
                          bool tappedEditable = false;
                          for (final entry in hitTestResult.path) {
                            final target = entry.target;
                            final typeStr = target.runtimeType.toString();
                            if (typeStr.contains('Editable') ||
                                typeStr.contains('AppFlowy') ||
                                typeStr.contains('TextField') ||
                                typeStr.contains('RichText') ||
                                typeStr.contains('AppFlowyRichText') ||
                                typeStr.contains('RenderParagraph') ||
                                typeStr.contains('RenderEditable') ||
                                typeStr.contains('Zen')) {
                              tappedEditable = true;
                              break;
                            }
                          }
                          if (!tappedEditable) {
                            _focusNode.requestFocus();
                          }
                        },
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
                                      child: cachedChildren[r][c],
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
                  ),
                ),
              );
            },
          ),
      );
  }
}
