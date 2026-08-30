import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/widgets/home_screen/lock_screen_overlay.dart';
import 'presentation/widgets/common/update_ready_banner.dart';
import 'presentation/widgets/common/global_search_dialog.dart';
import 'global_keys.dart';
import 'spatial_engine_scaffold.dart';
import 'database/preferences_service.dart';
import 'api_client.dart';
import 'theme/everforest_colors.dart';

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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          if (isUnlocked) GlobalSearchDialog.show(context);
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          if (isUnlocked) GlobalSearchDialog.show(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Stack(
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
            if (isUnlocked)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => GlobalSearchDialog.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: EverforestColors.bg1.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: EverforestColors.green.withValues(alpha: 0.5), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded, color: EverforestColors.green, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Search (Ctrl+K)',
                            style: TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ValueListenableBuilder<bool>(
              valueListenable: PreferencesService.showConnectionStatusOverlay,
              builder: (context, show, _) {
                if (!show || !isUnlocked) return const SizedBox.shrink();
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: ValueListenableBuilder<String>(
                    valueListenable: ApiClient.instance.connectionStatusNotifier,
                    builder: (context, status, _) {
                      final isMesh = status.contains('HEADSCALE');
                      final color = isMesh ? EverforestColors.blue : EverforestColors.green;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: EverforestColors.bg1.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const UpdateReadyBanner(),
          ],
        ),
      ),
    );
  }
}
