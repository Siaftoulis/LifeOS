import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/everforest_colors.dart';
import 'all_tracks_sliver.dart';

class ArtistsSliver extends StatelessWidget {
  const ArtistsSliver({
    super.key,
    required this.artistGroups,
    required this.selectedArtist,
    required this.canPlay,
    required this.offlineDownloading,
    required this.onSelectArtist,
    required this.onClearArtist,
    required this.onPlayTrackList,
    required this.onDownloadOffline,
    required this.onDeleteTrack,
    required this.onWebNotice,
  });

  final Map<String, List<MusicTrack>> artistGroups;
  final String? selectedArtist;
  final bool canPlay;
  final Set<String> offlineDownloading;
  final ValueChanged<String> onSelectArtist;
  final VoidCallback onClearArtist;
  final void Function(List<MusicTrack> list, int index) onPlayTrackList;
  final void Function(MusicTrack track) onDownloadOffline;
  final void Function(MusicTrack track) onDeleteTrack;
  final VoidCallback onWebNotice;

  @override
  Widget build(BuildContext context) {
    if (artistGroups.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    if (selectedArtist != null && artistGroups.containsKey(selectedArtist)) {
      final artistTracks = artistGroups[selectedArtist]!;
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: EverforestColors.fg),
                    onPressed: onClearArtist,
                  ),
                  Text(
                    selectedArtist!,
                    style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (canPlay)
                    ElevatedButton.icon(
                      onPressed: () => onPlayTrackList(artistTracks, 0),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Play All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EverforestColors.green,
                        foregroundColor: EverforestColors.bg0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final t = artistTracks[i];
                final isOffline = MusicRepository.instance.isOffline(t.id);
                return TrackTile(
                  track: t,
                  currentList: artistTracks,
                  index: i,
                  isOfflineLocal: isOffline,
                  isDownloadingOffline: offlineDownloading.contains(t.id),
                  canPlay: canPlay,
                  onDownloadOffline: onDownloadOffline,
                  onDeleteTrack: onDeleteTrack,
                  onPlay: onPlayTrackList,
                  onWebNotice: onWebNotice,
                );
              },
              childCount: artistTracks.length,
            ),
          ),
        ],
      );
    }

    final artists = artistGroups.keys.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final artist = artists[i];
          final tracks = artistGroups[artist]!;
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: EverforestColors.bg2,
              child: Icon(Icons.person_rounded, color: EverforestColors.aqua),
            ),
            title: Text(
              artist,
              style: const TextStyle(
                  color: EverforestColors.fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
            subtitle: Text(
              '${tracks.length} song${tracks.length > 1 ? 's' : ''}',
              style:
                  const TextStyle(color: EverforestColors.grey, fontSize: 13),
            ),
            trailing: canPlay
                ? IconButton(
                    icon: const Icon(Icons.play_circle_fill_rounded,
                        color: EverforestColors.green, size: 34),
                    tooltip: 'Play $artist',
                    onPressed: () => onPlayTrackList(tracks, 0),
                  )
                : const Icon(Icons.phonelink_lock_rounded,
                    color: EverforestColors.grey, size: 20),
            onTap: () => onSelectArtist(artist),
          );
        },
        childCount: artists.length,
      ),
    );
  }
}

class GenresSliver extends StatelessWidget {
  const GenresSliver({
    super.key,
    required this.genreGroups,
    required this.selectedGenre,
    required this.canPlay,
    required this.offlineDownloading,
    required this.onSelectGenre,
    required this.onClearGenre,
    required this.onPlayTrackList,
    required this.onDownloadOffline,
    required this.onDeleteTrack,
    required this.onWebNotice,
  });

  final Map<String, List<MusicTrack>> genreGroups;
  final String? selectedGenre;
  final bool canPlay;
  final Set<String> offlineDownloading;
  final ValueChanged<String> onSelectGenre;
  final VoidCallback onClearGenre;
  final void Function(List<MusicTrack> list, int index) onPlayTrackList;
  final void Function(MusicTrack track) onDownloadOffline;
  final void Function(MusicTrack track) onDeleteTrack;
  final VoidCallback onWebNotice;

  @override
  Widget build(BuildContext context) {
    if (genreGroups.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    if (selectedGenre != null && genreGroups.containsKey(selectedGenre)) {
      final genreTracks = genreGroups[selectedGenre]!;
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: EverforestColors.fg),
                    onPressed: onClearGenre,
                  ),
                  Text(
                    selectedGenre!,
                    style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (canPlay)
                    ElevatedButton.icon(
                      onPressed: () => onPlayTrackList(genreTracks, 0),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Play Genre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EverforestColors.green,
                        foregroundColor: EverforestColors.bg0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final t = genreTracks[i];
                final isOffline = MusicRepository.instance.isOffline(t.id);
                return TrackTile(
                  track: t,
                  currentList: genreTracks,
                  index: i,
                  isOfflineLocal: isOffline,
                  isDownloadingOffline: offlineDownloading.contains(t.id),
                  canPlay: canPlay,
                  onDownloadOffline: onDownloadOffline,
                  onDeleteTrack: onDeleteTrack,
                  onPlay: onPlayTrackList,
                  onWebNotice: onWebNotice,
                );
              },
              childCount: genreTracks.length,
            ),
          ),
        ],
      );
    }

    final genres = genreGroups.keys.toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisExtent: 100,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final genre = genres[i];
            final tracks = genreGroups[genre]!;
            return InkWell(
              onTap: () => onSelectGenre(genre),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: EverforestColors.bg1,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            genre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tracks.length} tracks',
                            style: const TextStyle(
                                color: EverforestColors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (canPlay)
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill_rounded,
                            color: EverforestColors.green, size: 34),
                        tooltip: 'Play Mix',
                        onPressed: () => onPlayTrackList(tracks, 0),
                      )
                    else
                      const Icon(Icons.phonelink_lock_rounded,
                          color: EverforestColors.grey, size: 20),
                  ],
                ),
              ),
            );
          },
          childCount: genres.length,
        ),
      ),
    );
  }
}
