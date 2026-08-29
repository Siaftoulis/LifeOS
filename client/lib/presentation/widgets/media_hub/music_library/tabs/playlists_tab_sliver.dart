import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../theme/everforest_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Playlist>>(
      valueListenable: MusicRepository.instance.playlists,
      builder: (context, playlists, _) {
        final totalItems = playlists.length + 1; // +1 for "Create Playlist" card

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 140,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
                        color: EverforestColors.bg1,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: EverforestColors.green.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: EverforestColors.green
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: EverforestColors.green, size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Create Playlist',
                            style: TextStyle(
                              color: EverforestColors.green,
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
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
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
                                color: playlist.isSmart
                                    ? EverforestColors.yellow
                                        .withValues(alpha: 0.15)
                                    : EverforestColors.bg2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                playlist.isSmart
                                    ? Icons.auto_awesome_rounded
                                    : Icons.playlist_play_rounded,
                                color: playlist.isSmart
                                    ? EverforestColors.yellow
                                    : EverforestColors.green,
                                size: 22,
                              ),
                            ),
                            const Spacer(),
                            if (playlist.isSmart)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: EverforestColors.yellow
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SMART',
                                  style: TextStyle(
                                    color: EverforestColors.yellow,
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
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${playlist.trackCount} songs',
                              style: const TextStyle(
                                color: EverforestColors.grey,
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
        );
      },
    );
  }
}
