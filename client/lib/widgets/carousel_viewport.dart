import 'package:flutter/material.dart';
import '../feature_registry.dart';

class CarouselViewport extends StatelessWidget {
  final PageController controller;
  final List<FeatureItem> features;
  final ValueChanged<int> onPageChanged;

  const CarouselViewport({super.key, required this.controller, required this.features, required this.onPageChanged});

  @override Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      onPageChanged: onPageChanged,
      itemCount: features.length,
      itemBuilder: (ctx, i) => features[i].viewBuilder(ctx),
    );
  }
}
