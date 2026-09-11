import 'package:flutter/material.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../../../../../theme/app_skin_registry.dart';
import '../poweramp_equalizer_modal.dart';
import 'home_widget_customizer_sheet.dart';
import 'lossless_sources_modal.dart';

/// 1:1 Poweramp Settings screen matching Screenshot 4.
class PowerampSettingsSheet extends StatelessWidget {
  const PowerampSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PowerampSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final topPadding = MediaQuery.of(context).padding.top;

    final settingsItems = [
      (
        icon: Icons.layers_rounded,
        iconColor: const Color(0xFF8C9EFF),
        title: 'Look and Feel',
        desc: 'Skin, player interface, language, notifications',
        onTap: () {
          _showSkinPicker(context, skin);
        },
      ),
      (
        icon: Icons.widgets_rounded,
        iconColor: const Color(0xFF38BDF8),
        title: 'Home Screen Widget',
        desc: 'Artwork preview, transparency, themes, and controls',
        onTap: () {
          HomeWidgetCustomizerSheet.show(context);
        },
      ),
      (
        icon: Icons.volume_up_rounded,
        iconColor: const Color(0xFFFF80AB),
        title: 'Audio',
        desc: 'Crossfade, replay gain, volume, output',
        onTap: () {
          PowerampEqualizerModal.show(context, initialMode: 0);
        },
      ),
      (
        icon: Icons.hub_rounded,
        iconColor: const Color(0xFF38BDF8),
        title: 'Lossless Sources & Integrations',
        desc: 'Soulseek (slskd) P2P, Tidal, Deezer HiFi credentials',
        onTap: () {
          LosslessSourcesModal.show(context);
        },
      ),
      (
        icon: Icons.graphic_eq_rounded,
        iconColor: const Color(0xFFEA80FC),
        title: 'Visualization',
        desc: 'Faded controls opacity, preset duration',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dynamic Spectrogram & VU Meter active'),
              backgroundColor: skin.bg1,
            ),
          );
        },
      ),
      (
        icon: Icons.wallpaper_rounded,
        iconColor: const Color(0xFF80CBC4),
        title: 'Background',
        desc: 'Blur, details, intensity, saturation',
        onTap: () {},
      ),
      (
        icon: Icons.image_rounded,
        iconColor: const Color(0xFFA5D6A7),
        title: 'Album Art',
        desc: 'Download, quality, cache cleanup',
        onTap: () {},
      ),
      (
        icon: Icons.folder_rounded,
        iconColor: const Color(0xFF90CAF9),
        title: 'Library',
        desc: 'Rescan, music folders, list, queue options',
        onTap: () {},
      ),
      (
        icon: Icons.headphones_rounded,
        iconColor: const Color(0xFFB0BEC5),
        title: 'Headset/Bluetooth',
        desc: 'Pause/resume on connection, headset buttons',
        onTap: () {},
      ),
      (
        icon: Icons.lock_clock_rounded,
        iconColor: const Color(0xFFFFB74D),
        title: 'Lock Screen',
        desc: 'Poweramp lock screen options',
        onTap: () {},
      ),
      (
        icon: Icons.more_horiz_rounded,
        iconColor: const Color(0xFF80DEEA),
        title: 'Misc',
        desc: 'Scrobbling, Android Auto, other tweaks',
        onTap: () {},
      ),
      (
        icon: Icons.show_chart_rounded,
        iconColor: Colors.white70,
        title: 'About',
        desc: 'Version/changelog, translations info',
        onTap: () {},
      ),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: skin.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding > 0 ? 12 : 16),
          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: skin.fg, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: skin.fg,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.search_rounded, color: skin.fg, size: 22),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: skin.fg, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Text(
              'Settings',
              style: TextStyle(
                color: skin.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // List of items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: settingsItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, i) {
                final item = settingsItems[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(item.icon, color: item.iconColor, size: 22),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: skin.fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.desc,
                      style: TextStyle(
                        color: skin.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  onTap: item.onTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSkinPicker(BuildContext context, AppSkin activeSkin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: activeSkin.bg0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Poweramp Skin',
              style: TextStyle(
                color: activeSkin.fg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: AppSkinRegistry.allSkins.length,
                itemBuilder: (context, i) {
                  final skin = AppSkinRegistry.allSkins[i];
                  final isCurrent = skin.id == activeSkin.id;
                  return ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: skin.bg0,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? skin.accent : Colors.white24,
                          width: isCurrent ? 2.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: skin.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      skin.name,
                      style: TextStyle(
                        color: skin.fg,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      skin.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: skin.textMuted, fontSize: 12),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle_rounded, color: skin.accent)
                        : null,
                    onTap: () async {
                      await AppSkinManager.setSkin(skin.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

