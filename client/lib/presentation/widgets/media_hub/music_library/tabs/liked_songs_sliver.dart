import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/app_skin_manager.dart';
import 'all_tracks_sliver.dart';

class LikedSongsSliver extends StatelessWidget {
  const LikedSongsSliver({
    super.key,
    required this.canPlay,
    required this.offlineDownloading,
    required this.onDownloadOffline,
    required this.onDeleteTrack,
    required this.onPlayTrackList,
    required this.onWebNotice,
    required this.onAddToPlaylist,
  });

  final bool canPlay;
  final Set<String> offlineDownloading;
  final void Function(MusicTrack track) onDownloadOffline;
  final void Function(MusicTrack track) onDeleteTrack;
  final void Function(List<MusicTrack> list, int index) onPlayTrackList;
  final VoidCallback onWebNotice;
  final void Function(MusicTrack track) onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return ValueListenableBuilder<List<MusicTrack>>(
      valueListenable: MusicRepository.instance.likedTracks,
      builder: (context, likedTracks, _) {
        if (likedTracks.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        color: skin.textMuted, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No liked songs yet',
                      style: TextStyle(
                          color: skin.fg,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart icon on any song to save it to your favorites!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: skin.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            // Header Banner
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        skin.red.withValues(alpha: 0.25),
                        skin.bg1,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: skin.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: skin.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.favorite_rounded,
                            color: skin.red, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Liked Songs',
                              style: TextStyle(
                                color: skin.fg,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${likedTracks.length} favorite songs',
                              style: TextStyle(
                                  color: skin.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (canPlay) ...[
                        IconButton(
                          icon: Icon(Icons.play_circle_fill_rounded,
                              color: skin.accent, size: 38),
                          tooltip: 'Play All Liked',
                          onPressed: () => onPlayTrackList(likedTracks, 0),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Track list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final t = likedTracks[i];
                  final isOffline = MusicRepository.instance.isOffline(t.id);

                  return TrackTile(
                    track: t,
                    currentList: likedTracks,
                    index: i,
                    isOfflineLocal: isOffline,
                    isDownloadingOffline: offlineDownloading.contains(t.id),
                    canPlay: canPlay,
                    onDownloadOffline: onDownloadOffline,
                    onDeleteTrack: onDeleteTrack,
                    onPlay: onPlayTrackList,
                    onWebNotice: onWebNotice,
                    onAddToPlaylist: () => onAddToPlaylist(t),
                  );
                },
                childCount: likedTracks.length,
              ),
            ),
          ],
        );
      },
    );
  }
}
