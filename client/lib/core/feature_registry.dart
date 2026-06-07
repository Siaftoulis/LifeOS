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

import '../database/preferences_service.dart';

class FeatureRegistry {
  static ValueNotifier<List<List<String>>> get layoutNotifier => PreferencesService.layout;

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
    final Widget view = _builders[id]?.call() ?? const Center(
      child: Text('UNMAPPED', style: TextStyle(color: EverforestColors.red)),
    );
    return ClipRect(
      child: view,
    );
  }
}
