import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../feature_registry.dart';

class CarouselViewport extends StatefulWidget {
  final PageController controller;
  final List<FeatureItem> features;
  final ValueChanged<int> onPageChanged;

  const CarouselViewport({super.key, required this.controller, required this.features, required this.onPageChanged});

  @override
  State<CarouselViewport> createState() => _CarouselViewportState();
}

class _CarouselViewportState extends State<CarouselViewport> {
  int _overscrollCount = 0;
  bool _isOverscrolling = false;
  Timer? _overscrollTimer;

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      bool isOverscroll = false;
      bool isTop = false;
      
      if (notification is OverscrollNotification) {
        if (notification.dragDetails != null) {
          isOverscroll = true;
          isTop = notification.overscroll < 0;
        }
      } else if (notification is ScrollUpdateNotification && notification.metrics.outOfRange) {
        if (notification.dragDetails != null) {
          isOverscroll = true;
          isTop = notification.metrics.pixels < notification.metrics.minScrollExtent;
        }
      }

      if (isOverscroll) {
        if (!_isOverscrolling) {
          _isOverscrolling = true;
          _overscrollCount++;
          debugPrint('CarouselViewport: Overscroll detected! Count: $_overscrollCount, Top: $isTop');
          
          if (_overscrollCount >= 1) {
            _overscrollCount = 0;
            debugPrint('CarouselViewport: Single overscroll threshold reached. Navigating...');
            if (widget.controller.page != null) {
              if (isTop && widget.controller.page! > 0) {
                widget.controller.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
              } else if (!isTop && widget.controller.page! < widget.features.length - 1) {
                widget.controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
              }
            }
          }
          
          _overscrollTimer?.cancel();
          _overscrollTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _overscrollCount = 0);
              debugPrint('CarouselViewport: Overscroll timer expired, count reset.');
            }
          });
        }
      } else if (notification is UserScrollNotification && notification.direction == ScrollDirection.idle) {
        _isOverscrolling = false;
      } else if (notification is ScrollEndNotification) {
        _isOverscrolling = false;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _overscrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        ),
        child: PageView.builder(
          controller: widget.controller,
          physics: const BouncingScrollPhysics(),
          onPageChanged: widget.onPageChanged,
          itemCount: widget.features.length,
          itemBuilder: (ctx, i) => widget.features[i].viewBuilder(ctx),
        ),
      ),
    );
  }
}
