import 'package:flutter/material.dart';
import 'core/base_plugin.dart';
import 'api_client.dart';
import 'vm_card.dart';
import 'habit_panel.dart';
import 'fast_capture_panel.dart';
import 'plugins/markdown/markdown_plugin.dart';
import 'plugins/gallery/gallery_plugin.dart';
import 'plugins/map_view/map_view_plugin.dart';
import 'plugins/live_sharing/live_sharing_plugin.dart';
import 'plugins/settings/settings_view.dart';

class FeatureItem {
  final String id, title; final IconData icon; final WidgetBuilder viewBuilder;
  const FeatureItem(this.id, this.title, this.icon, this.viewBuilder);
}

class _LegacyPlugin implements BasePlugin {
  final String title, pluginId; final IconData icon; final Widget view;
  _LegacyPlugin(this.pluginId, this.title, this.icon, this.view);
  @override Widget buildView(BuildContext c) => view;
  @override Future<void> initialize(dynamic db, ApiClient api) async {}
}

class FeatureRegistry {
  static final List<BasePlugin> _plugins = [];

  static List<FeatureItem> buildRegistry(dynamic db, ApiClient api) {
    if (_plugins.isEmpty) {
      _plugins.addAll([
        _LegacyPlugin('FEAT-001', 'Fast Capture', Icons.flash_on, FastCapturePanel(db: db)),
        _LegacyPlugin('UI-002', 'Habits Matrix', Icons.grid_on, HabitMatrixGrid(db: db)),
        _LegacyPlugin('UI-003', 'Hyper-V Control', Icons.computer, VMControlCard(name: 'Dev-Node', initialState: VMState.stopped, apiClient: api)),
        MarkdownPlugin(),
        GalleryPlugin(),
        MapViewPlugin(),
        LiveSharingPlugin(),
        _LegacyPlugin('SET-001', 'Settings', Icons.settings, SettingsView(db: db, api: api)),
      ]);
      for (final p in _plugins) { p.initialize(db, api); }
    }
    return _plugins.map((p) => FeatureItem(p.pluginId, p.title, p.icon, p.buildView)).toList();
  }
}
