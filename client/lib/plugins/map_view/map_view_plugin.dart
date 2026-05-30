import 'package:flutter/material.dart';
import '../../core/base_plugin.dart';
import '../../api_client.dart';
import 'dark_radar.dart';

class MapViewPlugin implements BasePlugin {
  @override String get pluginId => 'PLUG-MAP';
  @override String get title => 'Map View';
  @override IconData get icon => Icons.map;

  @override Future<void> initialize(dynamic db, ApiClient api) async {}

  @override Widget buildView(BuildContext context) => const DarkRadar();
}
