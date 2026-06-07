import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/feature_registry.dart';
import '../../theme/colors.dart';

class ZenEditor extends StatefulWidget {
  const ZenEditor({super.key});

  @override
  State<ZenEditor> createState() => _ZenState();
}

class _ZenState extends State<ZenEditor> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  Offset _currentOffset = Offset.zero;
  int gridX = 1;
  int gridY = 1;
  bool _initialized = false;

  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _curtainOpen = false;



  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.addListener(() {
      setState(() {
        _currentOffset = _offsetAnimation.value;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _keyboardFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _animateTo(double sw, double sh) {
    final endOffset = Offset(-gridX * sw, -gridY * sh);
    _offsetAnimation = Tween<Offset>(begin: _currentOffset, end: endOffset).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0);
  }

  void _snapToNearest(Offset displacement, double sw, double sh) {
    int nextX = gridX;
    int nextY = gridY;

    if (displacement.dx.abs() > displacement.dy.abs()) {
      if (displacement.dx > 50) {
        nextX = (gridX - 1 + 3) % 3;
      } else if (displacement.dx < -50) {
        nextX = (gridX + 1) % 3;
      }
    } else {
      if (displacement.dy > 50) {
        nextY = (gridY - 1 + 3) % 3;
      } else if (displacement.dy < -50) {
        nextY = (gridY + 1) % 3;
      }
    }

    gridX = nextX;
    gridY = nextY;
    _animateTo(sw, sh);
  }

  void _navigateByKey(LogicalKeyboardKey key, double sw, double sh) {
    int nextX = gridX;
    int nextY = gridY;

    if (key == LogicalKeyboardKey.arrowLeft) {
      nextX = (gridX - 1 + 3) % 3;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      nextX = (gridX + 1) % 3;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      nextY = (gridY - 1 + 3) % 3;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      nextY = (gridY + 1) % 3;
    }

    if (nextX != gridX || nextY != gridY) {
      gridX = nextX;
      gridY = nextY;
      _animateTo(sw, sh);
    }
  }

  void _toggleCurtain(bool open) {
    setState(() {
      _curtainOpen = open;
      if (!open) {
        _searchFocusNode.unfocus();
        _keyboardFocusNode.requestFocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sw = size.width;
    final sh = size.height;

    if (!_initialized && sw > 0 && sh > 0) {
      gridX = 1;
      gridY = 1;
      _currentOffset = Offset(-gridX * sw, -gridY * sh);
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: MochaColors.crust,
      body: Stack(
        children: [
          // 1. Spatial Grid Canvas
          Focus(
            focusNode: _keyboardFocusNode,
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && !_searchFocusNode.hasFocus) {
                _navigateByKey(event.logicalKey, sw, sh);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                _animController.stop();
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentOffset += details.delta;
                });
              },
              onPanEnd: (details) {
                final targetOfCurrent = Offset(-gridX * sw, -gridY * sh);
                final displacement = _currentOffset - targetOfCurrent;
                _snapToNearest(displacement, sw, sh);
              },
              child: ValueListenableBuilder<List<List<String>>>(
                valueListenable: FeatureRegistry.layoutNotifier,
                builder: (context, currentLayout, _) {
                  return Transform.translate(
                    offset: _currentOffset,
                    child: SizedBox(
                      width: sw * 3,
                      height: sh * 3,
                      child: Stack(
                        children: [
                          for (int y = 0; y < 3; y++)
                            for (int x = 0; x < 3; x++)
                              Positioned(
                                left: x * sw,
                                top: y * sh,
                                width: sw,
                                height: sh,
                                child: ColoredBox(
                                  color: MochaColors.base,
                                  child: FeatureRegistry.buildModule(currentLayout[y][x], y, x),
                                ),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. HUD Coordinates Overlay (low opacity, no interaction)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.3,
                  child: Text(
                    '[ $gridY, $gridX ]',
                    style: const TextStyle(
                      color: MochaColors.text,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Glass-Curtain Search Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuad,
            top: _curtainOpen ? 0 : -250,
            left: 0,
            right: 0,
            height: 280,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: ColoredBox(
                  color: const Color(0xBF1E1E2E), // 75% opacity base
                  child: Stack(
                    children: [
                      // Search content
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 30,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _toggleCurtain(false),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: GestureDetector(
                                onTap: () {}, // Absorb taps inside search input area
                                child: TextField(
                                  focusNode: _searchFocusNode,
                                  controller: _searchController,
                                  cursorColor: MochaColors.mauve,
                                  style: const TextStyle(
                                    color: MochaColors.text,
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 18,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Fuzzy search nexus...',
                                    hintStyle: TextStyle(
                                      color: MochaColors.overlay0,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                    prefixIcon: Icon(Icons.search, color: MochaColors.mauve),
                                  ),
                                  onSubmitted: (t) {
                                    _toggleCurtain(false);
                                    _searchController.clear();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Drag/Tap handle at the bottom of the curtain
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 30,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (details) {
                            if (details.delta.dy > 5) {
                              _toggleCurtain(true);
                            } else if (details.delta.dy < -5) {
                              _toggleCurtain(false);
                            }
                          },
                          onTap: () {
                            _toggleCurtain(!_curtainOpen);
                          },
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: MochaColors.overlay1.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
