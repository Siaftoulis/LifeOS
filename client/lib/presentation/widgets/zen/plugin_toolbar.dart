import 'package:flutter/material.dart';

class PluginToolbar extends StatelessWidget {
  final Map<String, bool> plugins;
  final ValueChanged<String> onToggle;

  const PluginToolbar({super.key, required this.plugins, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: plugins.keys.map((name) {
        final isEnabled = plugins[name]!;
        return FilterChip(
          label: Text(name, style: const TextStyle(fontSize: 11)),
          selected: isEnabled,
          selectedColor: const Color(0x1500E5FF),
          checkmarkColor: const Color(0xFF00E5FF),
          side: BorderSide(color: isEnabled ? const Color(0xFF00E5FF) : const Color(0xFF27272A)),
          onSelected: (_) => onToggle(name),
        );
      }).toList(),
    );
  }
}
