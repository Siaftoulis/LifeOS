import 'package:flutter/material.dart';
import '../../core/base_plugin.dart';
import '../../api_client.dart';

class LiveSharingPlugin implements BasePlugin {
  @override String get pluginId => 'PLUG-LIVE';
  @override String get title => 'Live Sharing';
  @override IconData get icon => Icons.share;

  @override Future<void> initialize(dynamic db, ApiClient api) async {}

  @override Widget buildView(BuildContext context) {
    return const Center(child: Text("Live Sharing WebSockets module not implemented yet.", style: TextStyle(color: Colors.grey)));
  }
}
