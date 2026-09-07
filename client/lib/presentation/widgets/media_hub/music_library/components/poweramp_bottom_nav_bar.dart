import 'package:flutter/material.dart';
import '../../../../../theme/app_skin_manager.dart';

/// 1:1 Poweramp 4-Destination Bottom Navigation Bar matching Screenshots 1-5.
class PowerampBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PowerampBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    final destinations = [
      (icon: Icons.grid_view_rounded, label: 'Library', tooltip: 'Library Hub'),
      (icon: Icons.equalizer_rounded, label: 'Equalizer', tooltip: 'Equalizer & Tone'),
      (icon: Icons.search_rounded, label: 'Search', tooltip: 'Search Library'),
      (icon: Icons.menu_rounded, label: 'Menu', tooltip: 'Poweramp Menu'),
    ];

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: skin.bg0,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(destinations.length, (i) {
          final isSelected = currentIndex == i;
          final d = destinations[i];
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(i),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? skin.accent.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      d.icon,
                      size: isSelected ? 26 : 24,
                      color: isSelected ? (skin.isOled ? Colors.white : skin.accent) : skin.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
