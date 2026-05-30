import 'package:flutter/material.dart';
import '../feature_registry.dart';
import '../theme.dart';

class DesktopNavigationRail extends StatelessWidget {
  final int selectedIndex; final ValueChanged<int> onSelected; final List<FeatureItem> features;
  const DesktopNavigationRail({super.key, required this.selectedIndex, required this.onSelected, required this.features});

  @override Widget build(BuildContext context) {
    final core = features.sublist(0, features.length - 1);
    final setIdx = features.length - 1;
    return Column(children: [
      Expanded(child: NavigationRail(
        backgroundColor: OLEDTheme.bg, selectedIndex: selectedIndex == setIdx ? null : selectedIndex,
        onDestinationSelected: onSelected, unselectedIconTheme: const IconThemeData(color: OLEDTheme.textSecondary),
        selectedIconTheme: const IconThemeData(color: OLEDTheme.accent),
        destinations: [for (final f in core) NavigationRailDestination(icon: Icon(f.icon), label: Text(f.title))],
      )),
      IconButton(
        icon: Icon(features.last.icon, color: selectedIndex == setIdx ? OLEDTheme.accent : OLEDTheme.textSecondary),
        onPressed: () => onSelected(setIdx),
      ),
      const SizedBox(height: 16),
    ]);
  }
}
