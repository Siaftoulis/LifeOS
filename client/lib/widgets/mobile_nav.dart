import 'dart:ui';
import 'package:flutter/material.dart';
import '../feature_registry.dart';
import '../theme.dart';
import '../database/preferences_service.dart';

class MobileNavigationBar extends StatelessWidget {
  final int selectedIndex; final ValueChanged<int> onSelected; final List<FeatureItem> features;
  const MobileNavigationBar({super.key, required this.selectedIndex, required this.onSelected, required this.features});

  @override Widget build(BuildContext context) {
    final mode = PreferencesService.navProfile.value;
    if (mode == 'Swipe' || mode == 'Dial') return const SizedBox.shrink();
    int f = features.indexWhere((x) => x.title.contains('Habits')), d = features.indexWhere((x) => x.title.contains('Gallery'));
    int z = features.indexWhere((x) => x.title.contains('Markdown')), s = features.indexWhere((x) => x.title.contains('Settings'));
    final btn = [(f != -1 ? f : 0, Icons.water), (d != -1 ? d : 0, Icons.dialpad), (z != -1 ? z : 0, Icons.spa), (s != -1 ? s : 0, Icons.settings)];
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: BottomAppBar(
          elevation: 0, color: const Color.fromRGBO(9, 9, 11, 0.8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: btn.map((b) => IconButton(icon: Icon(b.$2, color: selectedIndex == b.$1 ? OLEDTheme.accent : OLEDTheme.textSecondary), onPressed: () => onSelected(b.$1))).toList(),
          ),
        ),
      ),
    );
  }
}
