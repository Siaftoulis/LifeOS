import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../playlists/create_playlist_dialog.dart';
import '../playlists/playlist_detail_sheet.dart';

class PlaylistsTabSliver extends StatelessWidget {
  const PlaylistsTabSliver({
    super.key,
    required this.canPlay,
    required this.playbackController,
    required this.onWebNotice,
    required this.streamUrlFor,
  });

  final bool canPlay;
  final PlaybackController playbackController;
  final VoidCallback onWebNotice;
  final String Function(String trackId) streamUrlFor;

  static const List<_QuickMixPreset> _quickPresets = [
    _QuickMixPreset(
      name: 'Rock Mix',
      icon: '🎸',
      smartType: 'genre',
      smartConfig: 'Rock',
    ),
    _QuickMixPreset(
      name: '80s Retro',
      icon: '🕹️',
      smartType: 'decade',
      smartConfig: '1980s',
    ),
    _QuickMixPreset(
      name: '90s Hits',
      icon: '⚡',
      smartType: 'decade',
      smartConfig: '1990s',
    ),
    _QuickMixPreset(
      name: 'Heavy Rotation',
      icon: '🔥',
      smartType: 'most_played',
      smartConfig: '',
    ),
    _QuickMixPreset(
      name: 'Recently Added',
      icon: '🕒',
      smartType: 'recently_added',
      smartConfig: '',
    ),
    _QuickMixPreset(
      name: 'Synthwave',
      icon: '🎧',
      smartType: 'genre',
      smartConfig: 'Synthwave',
    ),
    _QuickMixPreset(
      name: 'Soundtracks',
      icon: '🎬',
      smartType: 'folder',
      smartConfig: 'Soundtracks',
    ),
  ];

  void _onQuickPresetTap(
    BuildContext context,
    _QuickMixPreset preset,
    List<Playlist> playlists,
  ) {
    Playlist? match;
    for (final p in playlists) {
      if (p.isSmart) {
        if (p.smartType == preset.smartType &&
            p.smartConfig.toLowerCase().trim() ==
                preset.smartConfig.toLowerCase().trim()) {
          match = p;
          break;
        }
        if (p.name.toLowerCase().trim() == preset.name.toLowerCase().trim()) {
          match = p;
          break;
        }
      }
    }

    if (match != null) {
      PlaylistDetailSheet.show(
        context,
        playlist: match,
        canPlay: canPlay,
        playbackController: playbackController,
        onWebNotice: onWebNotice,
        streamUrlFor: streamUrlFor,
      );
    } else {
      CreatePlaylistDialog.show(
        context,
        initialSmartType: preset.smartType,
        initialSmartConfig: preset.smartConfig,
        initialName: preset.name,
      ).then((created) {
        if (created != null && context.mounted) {
          PlaylistDetailSheet.show(
            context,
            playlist: created,
            canPlay: canPlay,
            playbackController: playbackController,
            onWebNotice: onWebNotice,
            streamUrlFor: streamUrlFor,
          );
        }
      });
    }
  }

  IconData _iconForSmartType(String type) {
    switch (type.toLowerCase().trim()) {
      case 'genre':
        return Icons.music_note_rounded;
      case 'decade':
      case 'year':
        return Icons.calendar_month_rounded;
      case 'folder':
        return Icons.folder_special_rounded;
      case 'recently_added':
        return Icons.schedule_rounded;
      case 'most_played':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _badgeForSmartPlaylist(Playlist p) {
    final type = p.smartType.toLowerCase().trim();
    final cfg = p.smartConfig.trim();
    if (type == 'recently_added') return 'RECENT';
    if (type == 'most_played') return 'TOP PLAYED';
    if (type == 'decade') return cfg.isNotEmpty ? cfg.toUpperCase() : 'DECADE';
    if (type == 'genre') return cfg.isNotEmpty ? cfg.toUpperCase() : 'GENRE';
    if (type == 'folder') return cfg.isNotEmpty ? cfg.toUpperCase() : 'FOLDER';
    return 'SMART';
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    return ValueListenableBuilder<List<Playlist>>(
      valueListenable: MusicRepository.instance.playlists,
      builder: (context, playlists, _) {
        final totalItems = playlists.length + 1; // +1 for "Create Playlist" card

        return SliverMainAxisGroup(
          slivers: [
            // Quick Smart Mixes Horizontal Carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: skin.yellow),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Smart Mixes',
                          style: TextStyle(
                            color: skin.fg,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• Tap to open or auto-generate',
                          style: TextStyle(color: skin.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickPresets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final preset = _quickPresets[i];
                          final exists = playlists.any((p) =>
                              p.isSmart &&
                              ((p.smartType == preset.smartType &&
                                      p.smartConfig.toLowerCase().trim() ==
                                          preset.smartConfig.toLowerCase().trim()) ||
                                  p.name.toLowerCase().trim() ==
                                      preset.name.toLowerCase().trim()));

                          return InkWell(
                            onTap: () => _onQuickPresetTap(context, preset, playlists),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: exists
                                    ? skin.yellow.withValues(alpha: 0.14)
                                    : skin.bg1,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: exists
                                      ? skin.yellow.withValues(alpha: 0.45)
                                      : skin.bg2,
                                  width: exists ? 1.3 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(preset.icon,
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Text(
                                    preset.name,
                                    style: TextStyle(
                                      color: exists ? skin.yellow : skin.fg,
                                      fontSize: 12,
                                      fontWeight: exists
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  if (exists) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: skin.yellow,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Playlists Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      // Create Playlist Card
                      return InkWell(
                        onTap: () => CreatePlaylistDialog.show(context),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: skin.bg1,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: skin.accent.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: skin.accent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add_rounded,
                                    color: skin.accent, size: 28),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Create Playlist',
                                style: TextStyle(
                                  color: skin.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final playlist = playlists[index - 1];
                    final isSmart = playlist.isSmart;
                    final icon = isSmart
                        ? _iconForSmartType(playlist.smartType)
                        : Icons.playlist_play_rounded;
                    final badge = isSmart ? _badgeForSmartPlaylist(playlist) : null;

                    return InkWell(
                      onTap: () {
                        PlaylistDetailSheet.show(
                          context,
                          playlist: playlist,
                          canPlay: canPlay,
                          playbackController: playbackController,
                          onWebNotice: onWebNotice,
                          streamUrlFor: streamUrlFor,
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: skin.bg1,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSmart
                                ? skin.yellow.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.08),
                            width: isSmart ? 1.2 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSmart
                                        ? skin.yellow.withValues(alpha: 0.15)
                                        : skin.bg2,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isSmart ? skin.yellow : skin.accent,
                                    size: 22,
                                  ),
                                ),
                                const Spacer(),
                                if (badge != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: skin.yellow.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      badge,
                                      style: TextStyle(
                                        color: skin.yellow,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: skin.fg,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${playlist.trackCount} songs',
                                  style: TextStyle(
                                    color: skin.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: totalItems,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickMixPreset {
  final String name;
  final String icon;
  final String smartType;
  final String smartConfig;

  const _QuickMixPreset({
    required this.name,
    required this.icon,
    required this.smartType,
    required this.smartConfig,
  });
}
