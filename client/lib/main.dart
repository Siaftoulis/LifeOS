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
