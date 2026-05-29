import 'package:flutter/material.dart';
import 'desktop_widget_manager.dart';

void main(List<String> args) {
  // Identify if current runtime instance is a secondary Windows desktop widget sub-window
  if (args.contains('multi_window')) {
    DesktopWidgetManager.runWidgetOverlay(args);
    return;
  }

  // Bypassed if multi_window: Primary App Initialization
  runApp(const LifeOSMainApp());
}

class LifeOSMainApp extends StatelessWidget {
  const LifeOSMainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('LifeOS Primary Window')),
      ),
    );
  }
}
