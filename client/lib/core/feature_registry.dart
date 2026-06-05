import 'package:flutter/material.dart';
import '../presentation/widgets/zen_workspace.dart';
import '../presentation/widgets/nexus_dashboard.dart';
import '../presentation/widgets/settings_panel.dart';
import '../presentation/widgets/tasks_grid.dart';
import '../presentation/widgets/media_gallery.dart';
import '../presentation/widgets/server_hub.dart';
import '../presentation/widgets/maps_view.dart';
import '../presentation/widgets/camera_viewport.dart';
import '../presentation/widgets/system_logs.dart';

class FeatureRegistry {
  static final ValueNotifier<List<List<String>>> layoutNotifier = ValueNotifier([['maps', 'camera', 'settings'], ['tasks', 'nexus', 'obsidian'], ['gallery', 'server', 'logs']]);

  static final Map<String, Widget Function()> _builders = {
    'obsidian': () => const ZenWorkspace(), 'nexus': () => const NexusDashboard(), 'settings': () => const SettingsPanel(),
    'tasks': () => const TasksGrid(), 'gallery': () => const MediaGallery(), 'server': () => const ServerHub(),
    'maps': () => const MapsView(), 'camera': () => const CameraViewport(), 'logs': () => const SystemLogs(),
  };

  static void rotateLayout() => layoutNotifier.value = [...layoutNotifier.value.sublist(1), layoutNotifier.value.first];

  static Widget buildModule(String id) => _builders[id]?.call() ?? Container(
    color: const Color(0xFF09090B),
    child: Center(child: Text('${id.toUpperCase()} MODULE', style: const TextStyle(color: Color(0xFFF8FFF4), fontSize: 20))),
  );
}
