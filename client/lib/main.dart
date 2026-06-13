import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'update_manager.dart';
import 'api_client.dart';
import 'desktop_widget_manager.dart';
import 'theme.dart';
import 'database/database.dart';
import 'database/preferences_service.dart';
import 'feature_registry.dart';
import 'presentation/engine/spatial_engine.dart';
import 'presentation/widgets/configurator.dart';
import 'presentation/widgets/nexus_dashboard.dart';
import 'presentation/widgets/zen_workspace.dart';
import 'fast_capture_panel.dart';
import 'presentation/widgets/radar_vision.dart';
import 'presentation/widgets/infra_hub.dart';
import 'presentation/widgets/quest_board.dart';
import 'presentation/widgets/home_view.dart';
import 'presentation/widgets/media_vault.dart';
import 'presentation/widgets/void_slot.dart';
import 'presentation/widgets/accounting/accounting_view.dart';
import 'presentation/widgets/banking/banking_dashboard_view.dart';
import 'presentation/widgets/book_library/book_library_dashboard.dart';
import 'presentation/widgets/chtm/chtm_view.dart';
import 'presentation/widgets/cloud/cloud_backup_dashboard.dart';
import 'presentation/widgets/darkweb/torrent_dashboard_view.dart';
import 'presentation/widgets/flashcards/flashcards_dashboard.dart';
import 'presentation/widgets/home_management/smart_home_dashboard.dart';
import 'presentation/widgets/home_screen/lock_screen_overlay.dart';
import 'presentation/widgets/knowledge_base/knowledge_base_dashboard.dart';
import 'presentation/widgets/maps_live_tracking/maps_dashboard_widget.dart';
import 'presentation/widgets/movie_library/movie_library_dashboard.dart';
import 'presentation/widgets/music_library/music_dashboard_widget.dart';
import 'presentation/widgets/obsidian_zen/zen_editor_widget.dart';
import 'presentation/widgets/photo_video_gallery/gallery_grid_widget.dart';
import 'presentation/widgets/point_star_system/point_star_dashboard.dart';
import 'presentation/widgets/preferences_setting/preferences_dashboard_view.dart';
import 'presentation/widgets/project_infinity/project_infinity_dashboard.dart';
import 'presentation/widgets/virtual_machine/vm_management_dashboard.dart';
import 'presentation/widgets/youtube_client/youtube_client_dashboard.dart';
import 'theme/everforest_colors.dart';

Future<void> main(List<String> args) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await PreferencesService.load();
    if (args.contains('multi_window')) {
      DesktopWidgetManager.runWidgetOverlay(args);
      return;
    }

    final db = AppDatabase(NativeDatabase.memory());
    final baseUrl = await ApiClient.discoverBaseUrl();
    final api = ApiClient(baseUrl: baseUrl);
    FeatureRegistry.buildRegistry(db, api);

    runApp(const LifeOSMainApp());
  } catch (e, stack) {
    debugPrint("CRITICAL INITIALIZATION ERROR: $e\n$stack");
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text("$e\n\n$stack", style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ),
      ),
    ));
  }
}

class LifeOSMainApp extends StatelessWidget {
  const LifeOSMainApp({super.key});

  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, title: 'LifeOS', theme: OLEDTheme.build(),
      home: Builder(builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) => UpdateManager.checkForUpdates(ctx, ApiClient.instance));
        return ValueListenableBuilder<List<List<String>>>(
          valueListenable: PreferencesService.layout,
          builder: (context, layout, _) {
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
            return Scaffold(
              backgroundColor: EverforestColors.bg0,
              body: SpatialEngine(
                layout: layout,
                startX: startX,
                startY: startY,
                builder: (moduleId, y, x) {
                  if (moduleId == 'configurator') {
                    return const GridConfigurator();
                  } else if (moduleId == 'nexus') {
                    return const NexusDashboard();
                  } else if (moduleId == 'radar') {
                    return const RadarVision();
                  } else if (moduleId == 'obsidian') {
                    return const ZenWorkspace();
                  } else if (moduleId == 'infra') {
                    return const InfraHub();
                  } else if (moduleId == 'quests') {
                    return const QuestBoard();
                  } else if (moduleId == 'home') {
                    return const HomeView();
                  } else if (moduleId == 'media') {
                    return const MediaVault();
                  } else if (moduleId == 'capture') {
                    return FastCapturePanel(db: AppDatabase.instance);
                  } else if (moduleId == 'accounting') {
                    return const AccountingView();
                  } else if (moduleId == 'banking') {
                    return const BankingDashboardView();
                  } else if (moduleId == 'books') {
                    return const BookLibraryDashboard();
                  } else if (moduleId == 'chtm') {
                    return const CHTMView();
                  } else if (moduleId == 'cloud') {
                    return const CloudBackupDashboard();
                  } else if (moduleId == 'darkweb') {
                    return const TorrentDashboardView();
                  } else if (moduleId == 'flashcards') {
                    return const FlashcardsDashboard();
                  } else if (moduleId == 'home_management') {
                    return const SmartHomeDashboard();
                  } else if (moduleId == 'home_screen') {
                    return const LockScreenOverlay();
                  } else if (moduleId == 'knowledge_base') {
                    return const KnowledgeBaseDashboard();
                  } else if (moduleId == 'maps_live_tracking') {
                    return const MapsDashboardWidget();
                  } else if (moduleId == 'movie_library') {
                    return const MovieLibraryDashboard();
                  } else if (moduleId == 'music_library') {
                    return const MusicDashboardWidget();
                  } else if (moduleId == 'obsidian_zen') {
                    return const ZenEditorWidget();
                  } else if (moduleId == 'photo_video_gallery') {
                    return const GalleryGridWidget();
                  } else if (moduleId == 'point_star_system') {
                    return const PointStarDashboard();
                  } else if (moduleId == 'preferences_setting') {
                    return const PreferencesDashboardView();
                  } else if (moduleId == 'project_infinity') {
                    return const ProjectInfinityDashboard();
                  } else if (moduleId == 'virtual_machine') {
                    return const VMManagementDashboard();
                  } else if (moduleId == 'youtube_client') {
                    return const YoutubeClientDashboard();
                  } else if (moduleId == 'void') {
                    return const VoidSlot();
                  } else {
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
                },
              ),
            );
          },
        );
      }),
    );
  }
}
