import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../music_formatters.dart';

/// Modal bottom sheet allowing users to select download quality mode:
/// - "best": Multi-source waterfall (FLAC lossless -> 320k HQ -> YouTube Pristine Opus)
/// - "fast": Direct YouTube stream extraction
class DownloadQualitySheet extends StatelessWidget {
  final MusicTrack track;

  const DownloadQualitySheet({
    super.key,
    required this.track,
  });

  static Future<String?> show(BuildContext context, {required MusicTrack track}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DownloadQualitySheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    return Container(
      decoration: BoxDecoration(
        color: skin.bg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Track Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: skin.bg2,
                    child: track.thumbnail.isNotEmpty
                        ? Image.network(
                            sanitizeMusicThumbnailUrl(track.thumbnail),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.music_note_rounded,
                              color: skin.accent,
                              size: 24,
                            ),
                          )
                        : Icon(
                            Icons.music_note_rounded,
                            color: skin.accent,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: skin.fg,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${track.artist.isNotEmpty ? track.artist : "Unknown Artist"} · ${formatTrackDuration(track.duration)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: skin.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              'SELECT AUDIO QUALITY',
              style: TextStyle(
                color: skin.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Option 1: Automatic Best Quality
            _QualityOptionTile(
              icon: Icons.auto_awesome_rounded,
              iconColor: skin.accent,
              title: 'Automatic Best Quality',
              tag: '💎 LOSSLESS / HQ',
              description:
                  'Waterfall search across open lossless sources (FLAC/ALAC), 320k streams, or pristine Opus with HD cover art.',
              isRecommended: true,
              skin: skin,
              onTap: () => Navigator.of(context).pop('best'),
            ),

            const SizedBox(height: 10),

            // Option 2: Fast Download
            _QualityOptionTile(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Fast Download',
              tag: '⚡ DIRECT STREAM',
              description:
                  'Direct YouTube Music stream extraction without multi-source fallback. Fast and lightweight.',
              isRecommended: false,
              skin: skin,
              onTap: () => Navigator.of(context).pop('fast'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String tag;
  final String description;
  final bool isRecommended;
  final AppSkin skin;
  final VoidCallback onTap;

  const _QualityOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.tag,
    required this.description,
    required this.isRecommended,
    required this.skin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRecommended
              ? skin.accent.withValues(alpha: 0.1)
              : skin.bg2.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRecommended
                ? skin.accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: isRecommended ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: skin.fg,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: skin.textMuted,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: skin.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
