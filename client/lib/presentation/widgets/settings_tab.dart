import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class CustomSettingsTab extends StatefulWidget {
  const CustomSettingsTab({super.key});
  @override
  State<CustomSettingsTab> createState() => _CustomSettingsTabState();
}

class _CustomSettingsTabState extends State<CustomSettingsTab> {
  bool _syncEnabled = true;
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MochaColors.base,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        children: [
          const Text(
            'SETTINGS',
            style: TextStyle(
              color: MochaColors.mauve,
              fontFamily: 'JetBrains Mono',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Catppuccin Mocha Theme Config', style: TextStyle(color: MochaColors.overlay0, fontSize: 12)),
          const SizedBox(height: 32),
          _buildRow('Enable Tailnet Sync', Switch(
            value: _syncEnabled,
            activeColor: MochaColors.green,
            activeTrackColor: MochaColors.surface0,
            inactiveThumbColor: MochaColors.overlay0,
            inactiveTrackColor: MochaColors.crust,
            onChanged: (v) => setState(() => _syncEnabled = v),
          )),
          const Divider(color: MochaColors.surface0, height: 32),
          _buildRow('OLED Deep Black Canvas', Switch(
            value: _darkMode,
            activeColor: MochaColors.mauve,
            activeTrackColor: MochaColors.surface0,
            inactiveThumbColor: MochaColors.overlay0,
            inactiveTrackColor: MochaColors.crust,
            onChanged: (v) => setState(() => _darkMode = v),
          )),
          const Divider(color: MochaColors.surface0, height: 32),
          const Text('SYSTEM METRICS', style: TextStyle(color: MochaColors.sky, fontFamily: 'JetBrains Mono', fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Workspace Node: pds-desktop\nDevice IP: 192.168.1.7\nSync Status: Nominal', style: TextStyle(color: MochaColors.text, height: 1.6, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRow(String title, Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: MochaColors.text, fontSize: 15, fontWeight: FontWeight.w500)),
        child,
      ],
    );
  }
}
