import 'package:flutter/material.dart';
import 'presentation/widgets/configurator.dart';
import 'presentation/widgets/nexus_dashboard.dart';
import 'presentation/widgets/zen_workspace.dart';
import 'presentation/widgets/home_view.dart';
import 'presentation/widgets/void_slot.dart';
import 'presentation/widgets/finance/finance_hub_dashboard.dart';
import 'presentation/widgets/media_hub/media_hub_dashboard.dart';
import 'presentation/widgets/rpg_hub/rpg_hub_dashboard.dart';
import 'presentation/widgets/infra/infra_hub_dashboard.dart';
import 'presentation/widgets/book_library/book_library_dashboard.dart';
import 'presentation/widgets/chtm/chtm_view.dart';
import 'presentation/widgets/flashcards/flashcards_dashboard.dart';
import 'presentation/widgets/home_management/smart_home_dashboard.dart';
import 'presentation/widgets/knowledge_base/knowledge_base_dashboard.dart';
import 'presentation/widgets/knowledge_hub/knowledge_hub_dashboard.dart';
import 'presentation/widgets/maps_live_tracking/maps_dashboard_widget.dart';
import 'presentation/widgets/preferences_setting/preferences_dashboard_view.dart';
import 'presentation/widgets/preferences_setting/android_launcher_widget.dart';
import 'presentation/widgets/project_infinity/project_infinity_dashboard.dart';

class AppModuleRouter {
  static Widget buildModule(String moduleId) {
    switch (moduleId) {
      case 'configurator': return const GridConfigurator();
      case 'nexus': return const NexusDashboard();
      case 'obsidian': return const ZenWorkspace();
      case 'infra': return const InfraHubDashboard();
      case 'quests': return const RpgHubDashboard();
      case 'home': return const HomeView();
      case 'knowledge_hub': return const KnowledgeHubDashboard();
      case 'accounting': return const FinanceHubDashboard();
      case 'banking': return const FinanceHubDashboard();
      case 'finance': return const FinanceHubDashboard();
      case 'books': return const BookLibraryDashboard();
      case 'chtm': return const CHTMView();
      case 'cloud': return const InfraHubDashboard();
      case 'darkweb': return const InfraHubDashboard();
      case 'flashcards': return const FlashcardsDashboard();
      case 'home_management': return const SmartHomeDashboard();
      case 'knowledge_base': return const KnowledgeBaseDashboard();
      case 'maps_live_tracking': return const MapsDashboardWidget();
      case 'movie_library': return const MediaHubDashboard();
      case 'music_library': return const MediaHubDashboard();
      case 'photo_video_gallery': return const MediaHubDashboard();
      case 'media_hub': return const MediaHubDashboard();
      case 'point_star_system': return const RpgHubDashboard();
      case 'rpg_hub': return const RpgHubDashboard();
      case 'preferences_setting': return const PreferencesDashboardView();
      case 'project_infinity': return const ProjectInfinityDashboard();
      case 'obsidian_zen': return const ZenWorkspace();
      case 'virtual_machine': return const InfraHubDashboard();
      case 'youtube_client': return const MediaHubDashboard();
      case 'app_drawer': return const AndroidLauncherWidget();
      case 'rpg': return const RpgHubDashboard();
      case 'void': return const VoidSlot();
      default:
        return Container(
          color: const Color(0xFF09090B),
          child: Center(
            child: Text(
              'MODULE: ${moduleId.toUpperCase()}',
              style: const TextStyle(color: Colors.white, fontFamily: 'JetBrainsMono'),
            ),
          ),
        );
    }
  }
}
