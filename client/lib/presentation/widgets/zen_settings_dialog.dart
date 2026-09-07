import 'package:flutter/material.dart';
import '../../theme/app_skin_manager.dart';
import 'preferences_setting/customization_settings_widget.dart';

class ZenSettingsDialog extends StatefulWidget {
  const ZenSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ZenSettingsDialog(),
    );
  }

  @override
  State<ZenSettingsDialog> createState() => _ZenSettingsDialogState();
}

class _ZenSettingsDialogState extends State<ZenSettingsDialog> {
  String _selectedCategory = 'Appearance';

  final List<String> _options = [
    'Mobile',
    'Editor',
    'Files & Links',
    'Appearance',
    'Hotkeys',
    'About',
  ];

  final List<String> _corePlugins = [
    'Backlinks',
    'Command palette',
    'Daily notes',
  ];

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 840,
        height: 620,
        decoration: BoxDecoration(
          color: skin.bg0,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: skin.bg2, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Left Sidebar
              Container(
                width: 220,
                color: skin.bg1,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Options',
                        style: TextStyle(
                          color: skin.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ..._options.map((opt) => _buildSidebarItem(opt, skin)),
                    const SizedBox(height: 12),
                    Divider(color: skin.bg2, height: 1),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Core plugins',
                        style: TextStyle(
                          color: skin.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ..._corePlugins.map((plugin) => _buildSidebarItem(plugin, skin)),
                  ],
                ),
              ),

              // Divider
              Container(width: 1, color: skin.bg2),

              // Right Content Area
              Expanded(
                child: Container(
                  color: skin.bg0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCategory,
                              style: TextStyle(
                                color: skin.fg,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: skin.textMuted,
                              hoverColor: Colors.white10,
                              splashRadius: 18,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: skin.bg2, height: 1),

                      // Category Content
                      Expanded(
                        child: _selectedCategory == 'Appearance'
                            ? const SingleChildScrollView(
                                padding: EdgeInsets.all(20),
                                physics: BouncingScrollPhysics(),
                                child: CustomizationSettingsWidget(),
                              )
                            : _buildUnderConstructionPanel(skin),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String title, dynamic skin) {
    final bool isSelected = _selectedCategory == title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = title),
        hoverColor: Colors.white10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? skin.bg2 : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? skin.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? skin.fg : skin.textMuted,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnderConstructionPanel(dynamic skin) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 48, color: skin.textMuted),
          const SizedBox(height: 16),
          Text(
            '$_selectedCategory Settings',
            style: TextStyle(color: skin.fg, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This category is configured according to standard AppFlowy defaults.',
            style: TextStyle(color: skin.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
