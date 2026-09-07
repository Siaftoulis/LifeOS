import 'package:flutter/material.dart';
import '../../../theme/app_skin.dart';
import '../../../theme/app_skin_registry.dart';
import '../../../theme/app_skin_manager.dart';

class CustomizationSettingsWidget extends StatefulWidget {
  const CustomizationSettingsWidget({super.key});

  @override
  State<CustomizationSettingsWidget> createState() => _CustomizationSettingsWidgetState();
}

class _CustomizationSettingsWidgetState extends State<CustomizationSettingsWidget> {
  String _activeFilter = 'All';

  final List<String> _filters = ['All', 'Dark', 'Light', 'OLED', 'Obsidian'];

  List<AppSkin> _getFilteredSkins() {
    return AppSkinRegistry.allSkins.where((skin) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Dark') return skin.isDark && !skin.isOled;
      if (_activeFilter == 'Light') return !skin.isDark;
      if (_activeFilter == 'OLED') return skin.isOled;
      if (_activeFilter == 'Obsidian') {
        return skin.tags.any((t) => t.toLowerCase().contains('obsidian')) ||
            skin.id == 'catppuccin_mocha' ||
            skin.id == 'default_dark' ||
            skin.id == 'nord';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSkin>(
      valueListenable: AppSkinManager.currentSkinNotifier,
      builder: (context, activeSkin, _) {
        final filteredSkins = _getFilteredSkins();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Theme Spotlight Header
            _buildActiveSkinBanner(activeSkin),
            const SizedBox(height: 16),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? (activeSkin.isDark ? Colors.black : Colors.white)
                              : activeSkin.textMuted,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: activeSkin.bg1,
                      selectedColor: activeSkin.accent,
                      checkmarkColor: activeSkin.isDark ? Colors.black : Colors.white,
                      side: BorderSide(
                        color: isSelected ? activeSkin.accent : activeSkin.bg2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        if (val) setState(() => _activeFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Skins Grid / Cards
            ...filteredSkins.map((skin) => _SkinCard(
                  skin: skin,
                  isActive: skin.id == activeSkin.id,
                  currentAppSkin: activeSkin,
                  onSelect: () => AppSkinManager.setSkin(skin.id),
                )),
          ],
        );
      },
    );
  }

  Widget _buildActiveSkinBanner(AppSkin skin) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: skin.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: skin.accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: skin.accent.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: skin.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.palette_rounded, color: skin.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          skin.name,
                          style: TextStyle(
                            color: skin.fg,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: skin.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: skin.isDark ? Colors.black : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      skin.description,
                      style: TextStyle(color: skin.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Swatch row
          Row(
            children: [
              Text(
                'PALETTE: ',
                style: TextStyle(
                  color: skin.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              _buildColorDot(skin.bg0, 'Base'),
              _buildColorDot(skin.bg1, 'Card'),
              _buildColorDot(skin.bg2, 'Border'),
              _buildColorDot(skin.accent, 'Accent'),
              _buildColorDot(skin.fg, 'Text'),
              _buildColorDot(skin.green, 'Success'),
              _buildColorDot(skin.red, 'Danger'),
              _buildColorDot(skin.purple, 'Purple'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color, String label) {
    return Tooltip(
      message: label,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final AppSkin skin;
  final bool isActive;
  final AppSkin currentAppSkin;
  final VoidCallback onSelect;

  const _SkinCard({
    required this.skin,
    required this.isActive,
    required this.currentAppSkin,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: currentAppSkin.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? currentAppSkin.accent : currentAppSkin.bg2,
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: currentAppSkin.accent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title + tags + selection status
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            skin.name,
                            style: TextStyle(
                              color: currentAppSkin.fg,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (skin.isOled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.purpleAccent, width: 0.8),
                              ),
                              child: const Text(
                                'OLED 100%',
                                style: TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: currentAppSkin.accent, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'Applied',
                            style: TextStyle(
                              color: currentAppSkin.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      TextButton(
                        onPressed: onSelect,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: currentAppSkin.accent,
                        ),
                        child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  skin.description,
                  style: TextStyle(color: currentAppSkin.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Live Preview Mockup Box
                _buildLivePreviewBox(),
                const SizedBox(height: 12),

                // Swatch preview strip
                Row(
                  children: [
                    _buildSwatchStrip(),
                    const Spacer(),
                    // Brightness badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: currentAppSkin.bg2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            skin.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            size: 12,
                            color: currentAppSkin.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            skin.isDark ? 'Dark Mode' : 'Light Mode',
                            style: TextStyle(color: currentAppSkin.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwatchStrip() {
    final colors = [skin.bg0, skin.bg1, skin.bg2, skin.accent, skin.fg];
    return Row(
      children: colors.map((c) {
        return Container(
          width: 24,
          height: 20,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLivePreviewBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: skin.bg0,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: skin.bg2, width: 1),
      ),
      child: Row(
        children: [
          // Mini icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: skin.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.hub_rounded, color: skin.accent, size: 14),
          ),
          const SizedBox(width: 8),
          // Mini title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LifeOS Surface',
                  style: TextStyle(
                    color: skin.fg,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Clean contrast & typography',
                  style: TextStyle(
                    color: skin.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          // Mini button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: skin.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Action',
              style: TextStyle(
                color: skin.isDark ? Colors.black : Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
