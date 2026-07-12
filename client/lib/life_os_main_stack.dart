import 'package:flutter/material.dart';
import 'presentation/widgets/home_screen/lock_screen_overlay.dart';
import 'global_keys.dart';
import 'spatial_engine_scaffold.dart';

class LifeOSMainStack extends StatelessWidget {
  final bool isUnlocked;
  final List<List<String>> layout;
  final VoidCallback onUnlock;

  const LifeOSMainStack({
    super.key,
    required this.isUnlocked,
    required this.layout,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    int startX = 0;
    int startY = 0;
    for (int i = 0; i < layout.length; i++) {
      for (int j = 0; j < layout[i].length; j++) {
        if (layout[i][j] == 'home') {
          startY = i;
          startX = j;
          break;
        }
      }
    }

    return Stack(
      children: [
        Offstage(
          offstage: !isUnlocked,
          child: RepaintBoundary(
            key: devScreenCaptureKey,
            child: SpatialEngineScaffold(
              layout: layout,
              startX: startX,
              startY: startY,
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: !isUnlocked
                ? LockScreenOverlay(
                    key: const ValueKey('lock_screen'),
                    onUnlocked: onUnlock,
                  )
                : const SizedBox.shrink(key: ValueKey('empty_lock')),
          ),
        ),
      ],
    );
  }
}
