import 'package:flutter/material.dart';
import '../theme/everforest_colors.dart';
import '../presentation/widgets/home_view.dart';
import '../presentation/widgets/configurator.dart';
import '../presentation/widgets/void_slot.dart';
import '../presentation/widgets/finance/finance_hub_dashboard.dart';
import '../presentation/widgets/media_hub/media_hub_dashboard.dart';
import '../presentation/widgets/rpg_hub/rpg_hub_dashboard.dart';
import '../presentation/widgets/infra/infra_hub_dashboard.dart';
import '../presentation/widgets/knowledge_hub/knowledge_hub_dashboard.dart';
import '../presentation/widgets/chtm/chtm_view.dart';
import '../presentation/widgets/preferences_setting/android_launcher_widget.dart';
import '../database/preferences_service.dart';
import '../presentation/widgets/zen_workspace.dart';
import '../presentation/widgets/book_library/book_library_dashboard.dart';
import '../presentation/widgets/flashcards/flashcards_dashboard.dart';
import '../presentation/widgets/knowledge_base/knowledge_base_dashboard.dart';
import '../presentation/widgets/project_infinity/project_infinity_dashboard.dart';

class FeatureRegistry {
  static ValueNotifier<List<List<String>>> get layoutNotifier => PreferencesService.layout;

  static List<String> get availableModules =>
      _builders.keys.where((id) => id != 'void').toList();

  static final Map<String, Widget Function()> _builders = {
    'infra': () => const InfraHubDashboard(),
    'knowledge_hub': () => const KnowledgeHubDashboard(),
    'home': () => const HomeView(), 
    'configurator': () => const GridConfigurator(), 
    'finance': () => const FinanceHubDashboard(),
    'chtm': () => const CHTMView(),
    'media_hub': () => const MediaHubDashboard(),
    'rpg_hub': () => const RpgHubDashboard(),
    'app_drawer': () => const AndroidLauncherWidget(),
    'void': () => const VoidSlot(),
    'obsidian_zen': () => const ZenWorkspace(),
    'knowledge_base': () => const KnowledgeBaseDashboard(),
    'flashcards': () => const FlashcardsDashboard(),
    'books': () => const BookLibraryDashboard(),
    'project_infinity': () => const ProjectInfinityDashboard(),
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
