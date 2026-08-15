import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/rendering.dart';
import 'app_bootstrap.dart';
import 'core/offline_map_service.dart';
import 'desktop_widget_manager.dart';

@pragma('vm:entry-point')
Future<void> main([List<String> args = const []]) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPaintSizeEnabled = false;
    
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
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

    if (!kIsWeb && Platform.isAndroid) {
      unawaited(FlutterDisplayMode.setHighRefreshRate().catchError((e) {
        debugPrint('Failed to set high refresh rate: $e');
      }));
    }

    if (!kIsWeb && args.contains('multi_window')) {
      DesktopWidgetManager.runWidgetOverlay(args);
      return;
    }

    try {
      if (!kIsWeb) {
        await OfflineMapService.init();
      }
    } catch (e) {
      debugPrint('Failed to init offline map cache: $e');
    }

    runApp(const BootstrapApp());
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
