import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 820,
        height: 580,
        decoration: BoxDecoration(
          color: EverforestColors.bg0,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EverforestColors.bg2, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              // Left Sidebar
              Container(
                width: 220,
                color: EverforestColors.bg1,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Options',
                        style: TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ..._options.map((opt) => _buildSidebarItem(opt)),
                    const SizedBox(height: 12),
                    const Divider(color: EverforestColors.bg2, height: 1),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Core plugins',
                        style: TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ..._corePlugins.map((plugin) => _buildSidebarItem(plugin)),
                  ],
                ),
              ),

              // Divider
              Container(width: 1, color: EverforestColors.bg2),

              // Right Content Area
              Expanded(
                child: Container(
                  color: EverforestColors.bg0,
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
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: EverforestColors.grey,
                              hoverColor: Colors.white10,
                              splashRadius: 18,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: EverforestColors.bg2, height: 1),

                      // Category Content
                      Expanded(
                        child: _buildUnderConstructionPanel(),
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

  Widget _buildSidebarItem(String title) {
    final bool isSelected = _selectedCategory == title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = title),
        hoverColor: Colors.white10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? EverforestColors.bg2 : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? EverforestColors.green : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? EverforestColors.fg : EverforestColors.grey,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnderConstructionPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tune, size: 48, color: EverforestColors.grey),
          const SizedBox(height: 16),
          Text(
            '$_selectedCategory Settings',
            style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This category is configured according to standard AppFlowy defaults.',
            style: TextStyle(color: EverforestColors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
