import 'package:flutter/material.dart';
import '../theme/zen_theme_service.dart';
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
    final theme = ZenThemeService.instance;

    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
        final colors = theme.current;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 820,
            height: 580,
            decoration: BoxDecoration(
              color: colors.bg0,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.bg2, width: 1),
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
                    color: colors.bg1,
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
                        ..._options.map((opt) => _buildSidebarItem(opt, colors)),
                        const SizedBox(height: 12),
                        Divider(color: colors.bg2, height: 1),
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
                        ..._corePlugins.map((plugin) => _buildSidebarItem(plugin, colors)),
                      ],
                    ),
                  ),

                  // Divider
                  Container(width: 1, color: colors.bg2),

                  // Right Content Area
                  Expanded(
                    child: Container(
                      color: colors.bg0,
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
                                    color: colors.fg,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: colors.grey,
                                  hoverColor: Colors.white10,
                                  splashRadius: 18,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: colors.bg2, height: 1),

                          // Category Content
                          Expanded(
                            child: _selectedCategory == 'Appearance'
                                ? _buildAppearancePanel(theme, colors)
                                : _buildUnderConstructionPanel(colors),
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
      },
    );
  }

  Widget _buildSidebarItem(String title, ZenThemePreset colors) {
    final bool isSelected = _selectedCategory == title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = title),
        hoverColor: Colors.white10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.bg2 : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? ZenThemeService.instance.accentColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? colors.fg : colors.grey,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearancePanel(ZenThemeService theme, ZenThemePreset colors) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // 1. Base color scheme
        const Text(
          'Base color scheme',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          "Choose Obsidian's default color scheme.",
          style: TextStyle(color: colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: colors.bg1,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.bg2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: theme.baseColorScheme,
              dropdownColor: colors.bg1,
              isExpanded: true,
              style: TextStyle(color: colors.fg, fontSize: 14),
              icon: Icon(Icons.arrow_drop_down, color: colors.grey),
              items: ['Dark', 'Light'].map((scheme) {
                return DropdownMenuItem(
                  value: scheme,
                  child: Text(scheme),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) theme.setBaseColorScheme(val);
              },
            ),
          ),
        ),

        const SizedBox(height: 24),
        Divider(color: colors.bg2),
        const SizedBox(height: 20),

        // 2. Accent color
        const Text(
          'Accent color',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the accent color used throughout the app.',
          style: TextStyle(color: colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...ZenThemeService.accentSwatches.map((color) {
              final isSelected = theme.accentColor == color;
              return GestureDetector(
                onTap: () => theme.setAccentColor(color),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)]
                        : [],
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              );
            }),
          ],
        ),

        const SizedBox(height: 24),
        Divider(color: colors.bg2),
        const SizedBox(height: 20),

        // 3. Themes
        const Text(
          'Themes',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage installed themes and browse community themes.',
          style: TextStyle(color: colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bg1,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.bg2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: theme.current.name,
                    dropdownColor: colors.bg1,
                    isExpanded: true,
                    style: TextStyle(color: colors.fg, fontSize: 14, fontWeight: FontWeight.w600),
                    icon: Icon(Icons.arrow_drop_down, color: colors.grey),
                    items: ZenThemeService.presets.map((preset) {
                      return DropdownMenuItem(
                        value: preset.name,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: preset.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(preset.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) theme.setPreset(val);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Divider(color: colors.bg2),
        const SizedBox(height: 20),

        // 4. Text Font Family
        const Text(
          'Text font',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Change the font family used in the editor.',
          style: TextStyle(color: colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: colors.bg1,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.bg2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: theme.fontFamily,
              dropdownColor: colors.bg1,
              isExpanded: true,
              style: TextStyle(color: colors.fg, fontSize: 14),
              icon: Icon(Icons.arrow_drop_down, color: colors.grey),
              items: ZenThemeService.availableFonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(font, style: TextStyle(fontFamily: font == 'System Default' ? null : font)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) theme.setFontFamily(val);
              },
            ),
          ),
        ),

        const SizedBox(height: 24),
        Divider(color: colors.bg2),
        const SizedBox(height: 20),

        // 5. Font Size
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Font size',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bg1,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${theme.fontSize.toInt()} px',
                style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Adjust editor font size.',
          style: TextStyle(color: colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.accentColor,
            inactiveTrackColor: colors.bg2,
            thumbColor: theme.accentColor,
            overlayColor: theme.accentColor.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: theme.fontSize,
            min: 12.0,
            max: 26.0,
            divisions: 14,
            label: '${theme.fontSize.toInt()}px',
            onChanged: (val) => theme.setFontSize(val),
          ),
        ),
      ],
    );
  }

  Widget _buildUnderConstructionPanel(ZenThemePreset colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 48, color: colors.grey),
          const SizedBox(height: 16),
          Text(
            '$_selectedCategory Settings',
            style: TextStyle(color: colors.fg, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This category is configured according to standard Obsidian defaults.',
            style: TextStyle(color: colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
