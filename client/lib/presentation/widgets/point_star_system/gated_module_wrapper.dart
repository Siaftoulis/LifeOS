import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';

class GatedModuleWrapper extends StatelessWidget {
  final Widget child;
  final String moduleName;
  final int requiredPoints;
  final IconData moduleIcon;

  const GatedModuleWrapper({
    super.key,
    required this.child,
    required this.moduleName,
    required this.requiredPoints,
    this.moduleIcon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemUser?>(
      stream: AppDatabase.instance.homeScreenDao.watchCurrentUser(),
      builder: (context, snapshot) {
        final currentPoints = snapshot.data?.currentPoints ?? 0;

        if (currentPoints >= requiredPoints) {
          return child;
        }

        return Stack(
          children: [
            // Render the child but blur it out heavily to tease what's behind
            ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.3,
                    child: child,
                  ),
                ),
              ),
            ),
            
            // The Glassmorphic Lock Overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: EverforestColors.bg0.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: EverforestColors.red.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(moduleIcon, size: 48, color: EverforestColors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Access Restricted',
                      style: TextStyle(
                        color: EverforestColors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      moduleName,
                      style: const TextStyle(color: EverforestColors.fg, fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: EverforestColors.bg1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EverforestColors.yellow.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: EverforestColors.yellow, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$currentPoints / $requiredPoints',
                            style: const TextStyle(
                              color: EverforestColors.yellow,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Complete daily habits and quests\nto earn Star Points.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
