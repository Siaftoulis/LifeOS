import 'package:flutter/material.dart';
import '../theme/everforest_colors.dart';
import '../presentation/widgets/zen_workspace.dart';
import '../fast_capture_panel.dart';
import '../database/database.dart';
import '../presentation/widgets/radar_vision.dart';
import '../presentation/widgets/infra_hub.dart';
import '../presentation/widgets/quest_board.dart';
import '../presentation/widgets/home_view.dart';
import '../presentation/widgets/media_vault.dart';
import '../presentation/widgets/configurator.dart';
import '../presentation/widgets/void_slot.dart';

class FeatureRegistry {
  static final ValueNotifier<List<List<String>>> layoutNotifier = ValueNotifier([
    ['radar', 'obsidian', 'infra'], 
    ['quests', 'home', 'media'], 
    ['capture', 'configurator', 'void']
  ]);

  static final Map<String, Widget Function()> _builders = {
    'radar': () => const RadarVision(), 
    'obsidian': () => const ZenWorkspace(), 
    'infra': () => const InfraHub(),
    'quests': () => const QuestBoard(), 
    'home': () => const HomeView(), 
    'media': () => const MediaVault(),
    'capture': () => FastCapturePanel(db: AppDatabase.instance), 
    'configurator': () => const GridConfigurator(), 
    'void': () => const VoidSlot(),
  };

  static void rotateLayout() => layoutNotifier.value = [...layoutNotifier.value.sublist(1), layoutNotifier.value.first];

  static Widget buildModule(String id, int y, int x) {
    final Widget view = _builders[id]?.call() ?? Container(color: EverforestColors.bg0);
    return ColoredBox(
      color: EverforestColors.bg0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              readOnly: true,
              initialValue: '$y-$x: ${id.toUpperCase()}',
              style: const TextStyle(
                color: EverforestColors.fg,
                fontFamily: 'JetBrains Mono',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: EverforestColors.bg1,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: EverforestColors.bg2),
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: view,
            ),
          ),
        ],
      ),
    );
  }
}
