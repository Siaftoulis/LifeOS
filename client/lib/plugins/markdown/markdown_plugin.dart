import 'package:flutter/material.dart';
import '../../core/base_plugin.dart';
import '../../api_client.dart';
import 'zen_editor.dart';

class MarkdownPlugin implements BasePlugin {
  @override String get pluginId => 'PLUG-MD';
  @override String get title => 'Markdown Sync';
  @override IconData get icon => Icons.book;

  @override Future<void> initialize(dynamic db, ApiClient api) async {}

  @override Widget buildView(BuildContext context) => const ZenEditor();
}
