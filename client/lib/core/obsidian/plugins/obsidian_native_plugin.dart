import 'package:flutter/material.dart';

/// Base interface for all native Flutter Obsidian plugins (Option B)
abstract class ObsidianNativePlugin {
  String get pluginId;
  String get name;
  String get description;
  String get version;

  /// Called when the plugin is enabled
  Future<void> onEnable() async {}

  /// Called when the plugin is disabled
  Future<void> onDisable() async {}

  /// Hook for modifying markdown text before it gets saved or parsed
  String onBeforeParse(String markdown) {
    return markdown;
  }

  /// Hook for building custom markdown blocks (like Dataview)
  /// Returns a Widget if the plugin claims this block type, otherwise null
  Widget? buildCustomBlock(BuildContext context, String blockType, String content) {
    return null;
  }

  /// Hook for adding tabs to the sidebars
  List<ObsidianSidebarView> getSidebarViews() {
    return [];
  }
}

enum SidebarPosition { left, right }

class ObsidianSidebarView {
  final String viewId;
  final String title;
  final IconData icon;
  final SidebarPosition position;
  final Widget Function(BuildContext context) builder;

  ObsidianSidebarView({
    required this.viewId,
    required this.title,
    required this.icon,
    required this.position,
    required this.builder,
  });
}
