import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'grid_configurator_widget.dart';
import 'system_updates_widget.dart';
import 'preset_manager_card.dart';

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
                  child: Column(
                    children: const [
                      PresetManagerCard(),
                      SizedBox(height: 16),
                      Expanded(child: SystemUpdatesWidget()),
                    ],
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
