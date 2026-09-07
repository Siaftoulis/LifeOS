import 'package:flutter/material.dart';
import '../../../../../core/update/ota_update_service.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../../../common/release_notes_sheet.dart';
import 'poweramp_settings_sheet.dart';

/// 1:1 Poweramp Menu Bottom Sheet matching Screenshot 5.
class PowerampMenuSheet extends StatelessWidget {
  const PowerampMenuSheet({super.key});

  static void show(BuildContext context) {
    final skin = context.skin;
    showModalBottomSheet(
      context: context,
      backgroundColor: skin.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PowerampMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Center drag handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Header: POWERAMP Full Version
            Text(
              'POWERAMP',
              style: TextStyle(
                color: skin.fg,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Full Version',
              style: TextStyle(
                color: skin.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Settings Tile
            ListTile(
              leading: Icon(Icons.settings_rounded, color: skin.fg, size: 24),
              title: Text(
                'Settings',
                style: TextStyle(color: skin.fg, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: skin.textMuted, size: 20),
              onTap: () {
                Navigator.pop(context);
                PowerampSettingsSheet.show(context);
              },
            ),

            // Pills row: [ Library ] [ Feature Packages ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildPill(
                    label: 'Library',
                    skin: skin,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildPill(
                    label: 'Feature Packages',
                    skin: skin,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Poweramp Audiophile DSP Engine Active'),
                          backgroundColor: skin.bg1,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Changelog
            ListTile(
              leading: Icon(Icons.graphic_eq_rounded, color: skin.fg, size: 24),
              title: Text(
                'Changelog',
                style: TextStyle(color: skin.fg, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'LifeOS Poweramp Engine & System Updates',
                style: TextStyle(color: skin.textMuted, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                final ota = OtaUpdateService.instance;
                final rel = await ota.fetchLatestRelease();
                if (context.mounted) {
                  if (rel != null) {
                    ReleaseNotesSheet.show(context, rel);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No changelog available')),
                    );
                  }
                }
              },
            ),

            // Help
            ListTile(
              leading: Icon(Icons.help_outline_rounded, color: skin.fg, size: 24),
              title: Text(
                'Help & Gestures',
                style: TextStyle(color: skin.fg, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Swipe down from player to view tracklist, swipe right to navigate folders',
                style: TextStyle(color: skin.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required AppSkin skin,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: skin.fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
