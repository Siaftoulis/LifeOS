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
    ['0,0', '0,1', '0,2'], 
    ['1,0', '1,1', '1,2'], 
    ['2,0', '2,1', '2,2']
  ]);

  static final Map<String, Widget Function()> _builders = {
    '0,0': () => const RadarVision(), 
    '0,1': () => const ZenWorkspace(), 
    '0,2': () => const InfraHub(),
    '1,0': () => const QuestBoard(), 
    '1,1': () => const HomeView(), 
    '1,2': () => const MediaVault(),
    '2,0': () => FastCapturePanel(db: AppDatabase.instance), 
    '2,1': () => const GridConfigurator(), 
    '2,2': () => const VoidSlot(),
  };

  static void rotateLayout() => layoutNotifier.value = [...layoutNotifier.value.sublist(1), layoutNotifier.value.first];

  static Widget buildModule(String id, int y, int x) {
    // Παίρνουμε το view απευθείας, χωρίς περιττά "τυλίγματα"
    final Widget view = _builders[id]?.call() ?? const Center(
      child: Text('UNMAPPED', style: TextStyle(color: EverforestColors.red)),
    );

    // ΕΠΙΣΤΡΕΦΟΥΜΕ ΑΠΕΥΘΕΙΑΣ ΤΟ VIEW.
    // Δεν χρειαζόμαστε το ColoredBox και το Stack με το black54 
    // που σου έκρυβε το UI!
    return ClipRect(
      child: view,
    );
  }
}
