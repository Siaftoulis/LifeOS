import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'update_manager.dart';
import 'api_client.dart';
import 'desktop_widget_manager.dart';
import 'theme.dart';
import 'plugins/markdown/zen_editor.dart';
import 'database/database.dart';
import 'database/preferences_service.dart';
import 'feature_registry.dart';

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
        return const ZenEditor();
      }),
    );
  }
}
