import 'package:flutter/material.dart';
import '../feature_registry.dart';
import '../theme/app_skin_manager.dart';

class DesktopNavigationRail extends StatelessWidget {
  final int selectedIndex; final ValueChanged<int> onSelected; final List<FeatureItem> features;
  const DesktopNavigationRail({super.key, required this.selectedIndex, required this.onSelected, required this.features});

  @override Widget build(BuildContext context) {
    final skin = context.skin;
    final core = features.sublist(0, features.length - 1);
    final setIdx = features.length - 1;
    return Column(children: [
      Expanded(child: NavigationRail(
        backgroundColor: skin.bg0, selectedIndex: selectedIndex == setIdx ? null : selectedIndex,
        onDestinationSelected: onSelected, unselectedIconTheme: IconThemeData(color: skin.textMuted),
        selectedIconTheme: IconThemeData(color: skin.accent),
        destinations: [for (final f in core) NavigationRailDestination(icon: Icon(f.icon), label: Text(f.title))],
      )),
      IconButton(
        icon: Icon(features.last.icon, color: selectedIndex == setIdx ? skin.accent : skin.textMuted),
        onPressed: () => onSelected(setIdx),
      ),
      const SizedBox(height: 16),
    ]);
  }
}
