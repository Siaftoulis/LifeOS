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
import '../presentation/widgets/accounting/accounting_view.dart';
import '../presentation/widgets/banking/banking_dashboard_view.dart';
import '../presentation/widgets/book_library/book_library_dashboard.dart';
import '../presentation/widgets/chtm/chtm_view.dart';
import '../presentation/widgets/cloud/cloud_backup_dashboard.dart';
import '../presentation/widgets/darkweb/torrent_dashboard_view.dart';
import '../presentation/widgets/flashcards/flashcards_dashboard.dart';
import '../presentation/widgets/home_management/smart_home_dashboard.dart';
import '../presentation/widgets/home_screen/lock_screen_overlay.dart';
import '../presentation/widgets/knowledge_base/knowledge_base_dashboard.dart';
import '../presentation/widgets/maps_live_tracking/maps_dashboard_widget.dart';
import '../presentation/widgets/movie_library/movie_library_dashboard.dart';
import '../presentation/widgets/music_library/music_dashboard_widget.dart';
import '../presentation/widgets/photo_video_gallery/gallery_grid_widget.dart';
import '../presentation/widgets/point_star_system/point_star_dashboard.dart';
import '../presentation/widgets/preferences_setting/preferences_dashboard_view.dart';
import '../presentation/widgets/preferences_setting/android_launcher_widget.dart';
import '../presentation/widgets/preferences_setting/tailscale_node_monitor_widget.dart';
import '../presentation/widgets/project_infinity/project_infinity_dashboard.dart';
import '../presentation/widgets/virtual_machine/vm_management_dashboard.dart';
import '../presentation/widgets/youtube_client/youtube_client_dashboard.dart';

import '../presentation/widgets/point_star_system/gated_module_wrapper.dart';
import '../database/preferences_service.dart';

class FeatureRegistry {
  static ValueNotifier<List<List<String>>> get layoutNotifier => PreferencesService.layout;

  static final Map<String, Widget Function()> _builders = {
    'radar': () => const RadarVision(), 
    'infra': () => const InfraHub(),
    'quests': () => const QuestBoard(), 
    'home': () => const HomeView(), 
    'media': () => const MediaVault(),
    'capture': () => FastCapturePanel(db: AppDatabase.instance), 
    'configurator': () => const GridConfigurator(), 
    'accounting': () => const AccountingView(),
    'banking': () => const BankingDashboardView(),
    'books': () => const BookLibraryDashboard(),
    'chtm': () => const CHTMView(),
    'cloud': () => const CloudBackupDashboard(),
    'darkweb': () => const GatedModuleWrapper(
      moduleName: 'Dark Web Management',
      requiredPoints: 50,
      moduleIcon: Icons.security,
      child: TorrentDashboardView(),
    ),
    'flashcards': () => const FlashcardsDashboard(),
    'home_management': () => const SmartHomeDashboard(),
    'home_screen': () => const HomeView(),
    'knowledge_base': () => const KnowledgeBaseDashboard(),
    'maps_live_tracking': () => const MapsDashboardWidget(),
    'movie_library': () => const GatedModuleWrapper(
      moduleName: 'Movie Library',
      requiredPoints: 20,
      moduleIcon: Icons.movie,
      child: MovieLibraryDashboard(),
    ),
    'music_library': () => const MusicDashboardWidget(),
    'obsidian_zen': () => const ZenWorkspace(),
    'photo_video_gallery': () => const GalleryGridWidget(),
    'point_star_system': () => const PointStarDashboard(),
    'preferences_setting': () => const PreferencesDashboardView(),
    'project_infinity': () => const ProjectInfinityDashboard(),
    'virtual_machine': () => const GatedModuleWrapper(
      moduleName: 'Virtual Machine Management',
      requiredPoints: 100,
      moduleIcon: Icons.computer,
      child: VMManagementDashboard(),
    ),
    'youtube_client': () => const GatedModuleWrapper(
      moduleName: 'YouTube Client',
      requiredPoints: 30,
      moduleIcon: Icons.video_library,
      child: YoutubeClientDashboard(),
    ),
    'app_drawer': () => const AndroidLauncherWidget(),
    'tailscale_mesh': () => const TailscaleNodeMonitorWidget(),
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
