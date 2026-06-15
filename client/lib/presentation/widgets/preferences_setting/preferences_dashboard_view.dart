import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'grid_configurator_widget.dart';

class PreferencesDashboardView extends StatelessWidget {
  const PreferencesDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Preferences & System Settings', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  flex: 3,
                  child: GridConfiguratorWidget(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EverforestColors.bg2),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: EverforestColors.green, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'System Notice',
                              style: TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Primary system and user configuration options have been relocated to the main Configurator module for centralized control.',
                          style: TextStyle(color: EverforestColors.fg, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'The App Drawer (Launcher) and Tailscale Mesh Monitor are now registered as standalone modules in the Spatial UI Registry, allowing you to configure and launch them directly on your spatial matrix grid.',
                          style: TextStyle(color: EverforestColors.grey, fontSize: 12, height: 1.5),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: EverforestColors.bg2.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.hub, color: EverforestColors.blue, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'LifeOS Spatial Engine v1.2',
                                  style: TextStyle(
                                    color: EverforestColors.grey,
                                    fontSize: 11,
                                    fontFamily: 'JetBrainsMono',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
