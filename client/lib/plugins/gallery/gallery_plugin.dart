import 'package:flutter/material.dart';
import '../../core/base_plugin.dart';
import '../../api_client.dart';
import 'gallery_view.dart';

class GalleryPlugin implements BasePlugin {
  @override String get pluginId => 'PLUG-GAL';
  @override String get title => 'Media Gallery';
  @override IconData get icon => Icons.photo_library;

  @override Future<void> initialize(dynamic db, ApiClient api) async {}

  @override Widget buildView(BuildContext context) => const GalleryView();
}
