import 'package:flutter/material.dart';
import '../feature_registry.dart';
import '../theme.dart';

class DesktopNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<FeatureItem> features;

  const DesktopNavigationRail({super.key, required this.selectedIndex, required this.onSelected, required this.features});

  @override Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: OLEDTheme.bg,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      unselectedIconTheme: const IconThemeData(color: OLEDTheme.textSecondary),
      selectedIconTheme: const IconThemeData(color: OLEDTheme.accent),
      destinations: [for (final f in features) NavigationRailDestination(icon: Icon(f.icon), label: Text(f.title))],
    );
  }
}
