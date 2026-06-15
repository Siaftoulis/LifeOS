import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';
import 'desktop_widget/widget_layout.dart';

/// Initializes the secondary frameless, transparent viewport instance for Windows 11.
class DesktopWidgetManager {
  static final ValueNotifier<Map<String, dynamic>> widgetData = ValueNotifier({});

  static void runWidgetOverlay(List<String> args) {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'update_metrics' || call.method == 'update_vms') {
        widgetData.value = jsonDecode(call.arguments.toString());
      }
      return 'acknowledged';
    });
    
    runApp(const WidgetOverlayApp());
  }
}

class WidgetOverlayApp extends StatelessWidget {
  const WidgetOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.transparent),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ValueListenableBuilder<Map<String, dynamic>>(
            valueListenable: DesktopWidgetManager.widgetData,
            builder: (context, data, _) => WidgetGlassmorphismLayout(data: data),
          ),
        ),
      ),
    );
  }
}
