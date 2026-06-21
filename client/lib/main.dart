import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value, Variable;
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:window_manager/window_manager.dart';
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
import 'presentation/widgets/photo_video_gallery/gallery_grid_widget.dart';
import 'presentation/widgets/point_star_system/point_star_dashboard.dart';
import 'presentation/widgets/preferences_setting/preferences_dashboard_view.dart';
import 'presentation/widgets/preferences_setting/android_launcher_widget.dart';
import 'presentation/widgets/preferences_setting/tailscale_node_monitor_widget.dart';
import 'presentation/widgets/project_infinity/project_infinity_dashboard.dart';
import 'presentation/widgets/virtual_machine/vm_management_dashboard.dart';
import 'presentation/widgets/youtube_client/youtube_client_dashboard.dart';
import 'plugins/location_tracker/location_tracker_plugin.dart';
import 'theme/everforest_colors.dart';
import 'auth_service.dart';
import 'core/dev_simulation_service.dart' as import_dev_sim;
import 'core/local_discovery_service.dart';
import 'core/vpn_manager.dart';

final GlobalKey devScreenCaptureKey = GlobalKey();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<SpatialEngineState> spatialEngineKey = GlobalKey<SpatialEngineState>();

Future<void> main(List<String> args) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize built-in VPN before any network requests (Custom DDNS)
    await VpnManager.instance.initialize();
    
    // Start local peer discovery (mDNS) for offline sync
    LocalDiscoveryService.instance.start();
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 720),
        minimumSize: Size(1024, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    if (Platform.isAndroid) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        debugPrint('Failed to set high refresh rate: $e');
      }
    }
    await PreferencesService.load();
    if (PreferencesService.rememberMe.value && PreferencesService.authToken.value.isNotEmpty) {
      AuthService.instance.restoreSession(
        PreferencesService.authToken.value,
        PreferencesService.userProfileJson.value,
      );
    }
    if (args.contains('multi_window')) {
      DesktopWidgetManager.runWidgetOverlay(args);
      return;
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File('${dbFolder.path}/lifeos.sqlite');
    final db = AppDatabase(NativeDatabase(dbFile));
    final urls = await Future.wait([
      ApiClient.discoverBaseUrl(),
      ApiClient.discoverDaemonUrl(),
    ]);
    final api = ApiClient(baseUrl: urls[0], daemonUrl: urls[1]);
    FeatureRegistry.buildRegistry(db, api);

    final locationPlugin = LocationTrackerPlugin();
    // Fire and forget so we don't block runApp
    locationPlugin.initialize(db, api);

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

class LifeOSMainApp extends StatefulWidget {
  const LifeOSMainApp({super.key});

  @override
  State<LifeOSMainApp> createState() => _LifeOSMainAppState();
}

class _LifeOSMainAppState extends State<LifeOSMainApp> {
  bool _isUnlocked = false;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _isUnlocked = AuthService.instance.isAuthenticated;
    AuthService.instance.currentUser.addListener(_handleAuthChange);
    _startNotificationPolling();
  }

  @override
  void dispose() {
    AuthService.instance.currentUser.removeListener(_handleAuthChange);
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _handleAuthChange() {
    final authenticated = AuthService.instance.isAuthenticated;
    if (authenticated != _isUnlocked) {
      setState(() {
        _isUnlocked = authenticated;
      });
    }
  }

  void _startNotificationPolling() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final List<dynamic> list = await ApiClient.instance.postDaemon('/api/v1/notifications', {});
        final dao = AppDatabase.instance.homeScreenDao;
        for (final item in list) {
          final String id = item['id'] ?? '';
          final String title = item['title'] ?? '';
          final String message = item['message'] ?? '';
          final String category = item['category'] ?? 'SYSTEM';
          final int createdAt = item['created_at'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
          
          final existing = await AppDatabase.instance.customSelect(
            'SELECT 1 FROM local_notifications WHERE id = ?',
            variables: [Variable.withString(id)],
          ).getSingleOrNull();

          if (existing == null) {
            await dao.insertNotification(LocalNotificationsCompanion.insert(
              id: id,
              title: title,
              message: message,
              category: category,
              createdAt: createdAt,
            ));
          }
        }
      } catch (e) {
        debugPrint('Error polling notifications: $e');
      }
    });
  }

  @override Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
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

            if (!_isUnlocked) {
              return LockScreenOverlay(
                onUnlocked: () => setState(() => _isUnlocked = true),
              );
            }

            return RepaintBoundary(
              key: devScreenCaptureKey,
              child: Listener(
                onPointerUp: (e) {
                  import_dev_sim.DevSimulationService.onUserInteraction();
                },
                child: Scaffold(
                  backgroundColor: EverforestColors.bg0,
                  body: SpatialEngine(
                    key: spatialEngineKey,
                    layout: layout,
                    startX: startX,
                    startY: startY,
                    builder: (moduleId, y, x) {
                      final moduleWidget = () {
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
                          return const HomeView();
                        } else if (moduleId == 'knowledge_base') {
                          return const KnowledgeBaseDashboard();
                        } else if (moduleId == 'maps_live_tracking') {
                          return const MapsDashboardWidget();
                        } else if (moduleId == 'movie_library') {
                          return const MovieLibraryDashboard();
                        } else if (moduleId == 'music_library') {
                          return const MusicDashboardWidget();
                        } else if (moduleId == 'obsidian_zen') {
                          return const ZenWorkspace();
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
                        } else if (moduleId == 'app_drawer') {
                          return const AndroidLauncherWidget();
                        } else if (moduleId == 'tailscale_mesh') {
                          return const TailscaleNodeMonitorWidget();
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
                      }();
                      return KeyedSubtree(
                        key: import_dev_sim.DevSimulationService.getModuleKey(moduleId),
                        child: moduleWidget,
                      );
                    },
              ), // SpatialEngine
            ), // Scaffold
            ), // Listener
          ); // RepaintBoundary
          },
        );
      }),
    );
  }

  void _showPinDialog(BuildContext context) {
    String pin = '';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: EverforestColors.bg1,
              title: const Text('Enter PIN', style: TextStyle(color: EverforestColors.fg)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pin.padRight(4, '•'),
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 32, letterSpacing: 16),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(10, (i) {
                      final digit = (i + 1) % 10;
                      return ActionChip(
                        backgroundColor: EverforestColors.bg2,
                        label: Text('$digit', style: const TextStyle(color: EverforestColors.fg, fontSize: 24)),
                        onPressed: () {
                          if (pin.length < 4) {
                            setDialogState(() => pin += '$digit');
                            if (pin.length == 4) {
                              if (pin == '0000') {
                                Navigator.pop(context);
                                setState(() => _isUnlocked = true);
                              } else {
                                setDialogState(() => pin = '');
                              }
                            }
                          }
                        },
                      );
                    }),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
}
