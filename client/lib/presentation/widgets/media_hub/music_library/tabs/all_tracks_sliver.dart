import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../api_client.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/everforest_colors.dart';
import '../components/heart_button.dart';
import '../track_metadata_modal.dart';

class TrackThumbnail extends StatelessWidget {
  const TrackThumbnail({
    super.key,
    required this.url,
    this.size = 48,
    this.borderRadius = 8,
  });

  final String url;
  final double size;
  final double borderRadius;

  String _sanitizeThumbnailUrl(String url) {
    if (url.isEmpty) return '';
    if (kIsWeb && Uri.base.scheme == 'https' && url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final secureUrl = _sanitizeThumbnailUrl(url);
    if (secureUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child:
            const Icon(Icons.music_note_rounded, color: EverforestColors.blue),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          secureUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: EverforestColors.bg1,
            child: const Icon(Icons.music_note_rounded,
                color: EverforestColors.blue),
          ),
        ),
      ),
    );
  }
}

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.currentList,
    required this.index,
    required this.isOfflineLocal,
    required this.isDownloadingOffline,
    required this.canPlay,
    required this.onDownloadOffline,
    required this.onDeleteTrack,
    required this.onPlay,
    required this.onWebNotice,
    this.onAddToPlaylist,
  });

  final MusicTrack track;
  final List<MusicTrack> currentList;
  final int index;
  final bool isOfflineLocal;
  final bool isDownloadingOffline;
  final bool canPlay;
  final void Function(MusicTrack track) onDownloadOffline;
  final void Function(MusicTrack track) onDeleteTrack;
  final void Function(List<MusicTrack> list, int index) onPlay;
  final VoidCallback onWebNotice;
  final VoidCallback? onAddToPlaylist;

  String _fmt(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final remS = s % 60;
    return '$m:${remS.toString().padLeft(2, '0')}';
  }

  void _showMetadata(BuildContext context) {
    final streamUrl =
        '${ApiClient.instance.daemonUrl}/api/v1/music/stream/?id=${track.id}';
    TrackMetadataModal.show(
      context,
      title: track.title,
      artist: track.artist,
      album: track.album,
      trackId: track.id,
      url: streamUrl,
      duration: Duration(seconds: track.duration.round()),
      track: track,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return ListTile(
      leading: GestureDetector(
        onTap: () => _showMetadata(context),
        child: TrackThumbnail(url: track.thumbnail, size: 48),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: EverforestColors.fg, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${track.artist}${track.album.isNotEmpty ? ' · ${track.album}' : ''}${track.duration > 0 ? ' · ${_fmt(track.duration)}' : ''}${isOfflineLocal ? ' · 📱 On device' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeartButton(track: track, size: 20),
          const SizedBox(width: 4),
          if (isOfflineLocal)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.download_done_rounded,
                  color: EverforestColors.green, size: 20),
            )
          else if (isDownloadingOffline)
            const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: EverforestColors.aqua),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download_for_offline_rounded,
                  color: EverforestColors.aqua, size: 20),
              tooltip: 'Save to this device (offline)',
              onPressed: () => onDownloadOffline(track),
            ),
          if (isWide) ...[
            if (onAddToPlaylist != null)
              IconButton(
                icon: const Icon(Icons.playlist_add_rounded,
                    color: EverforestColors.grey, size: 22),
                tooltip: 'Add to Playlist',
                onPressed: onAddToPlaylist,
              ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded,
                  color: EverforestColors.grey, size: 20),
              tooltip: 'Inspect Audio Specs',
              onPressed: () => _showMetadata(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: EverforestColors.red, size: 20),
              tooltip: 'Delete Song',
              onPressed: () => onDeleteTrack(track),
            ),
          ] else ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: EverforestColors.grey, size: 20),
              tooltip: 'More actions',
              color: EverforestColors.bg1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              onSelected: (val) {
                if (val == 'playlist') {
                  onAddToPlaylist?.call();
                } else if (val == 'specs') {
                  _showMetadata(context);
                } else if (val == 'delete') {
                  onDeleteTrack(track);
                }
              },
              itemBuilder: (ctx) => [
                if (onAddToPlaylist != null)
                  const PopupMenuItem(
                    value: 'playlist',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add_rounded,
                            color: EverforestColors.fg, size: 20),
                        SizedBox(width: 10),
                        Text('Add to Playlist',
                            style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'specs',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: EverforestColors.fg, size: 20),
                      SizedBox(width: 10),
                      Text('Audio Specs & Info',
                          style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 8),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: EverforestColors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Delete from Library',
                          style: TextStyle(
                              color: EverforestColors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      onTap: canPlay ? () => onPlay(currentList, index) : onWebNotice,
      onLongPress: () => _showMetadata(context),
    );
  }
}

enum TrackSortOption {
  titleAsc('Title (A-Z)', Icons.sort_by_alpha_rounded),
  titleDesc('Title (Z-A)', Icons.sort_by_alpha_rounded),
  artistAsc('Artist (A-Z)', Icons.person_outline_rounded),
  dateAddedDesc('Date Added (Newest)', Icons.access_time_rounded),
  dateAddedAsc('Date Added (Oldest)', Icons.history_rounded),
  durationDesc('Duration (Longest)', Icons.timer_outlined),
  durationAsc('Duration (Shortest)', Icons.timer_rounded);

  final String label;
  final IconData icon;
  const TrackSortOption(this.label, this.icon);
}

/// Pure helper to filter and sort library tracks without mutating source list.
List<MusicTrack> filterAndSortTracks(
  List<MusicTrack> source, {
  required String query,
  required TrackSortOption sortOption,
}) {
  var list = List<MusicTrack>.from(source);
  if (query.trim().isNotEmpty) {
    final q = query.trim().toLowerCase();
    list = list.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.artist.toLowerCase().contains(q) ||
          t.album.toLowerCase().contains(q);
    }).toList();
  }
  switch (sortOption) {
    case TrackSortOption.titleAsc:
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case TrackSortOption.titleDesc:
      list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      break;
    case TrackSortOption.artistAsc:
      list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      break;
    case TrackSortOption.dateAddedDesc:
      list.sort((a, b) => (b.addedAt ?? 0).compareTo(a.addedAt ?? 0));
      break;
    case TrackSortOption.dateAddedAsc:
      list.sort((a, b) => (a.addedAt ?? 0).compareTo(b.addedAt ?? 0));
      break;
    case TrackSortOption.durationDesc:
      list.sort((a, b) => b.duration.compareTo(a.duration));
      break;
    case TrackSortOption.durationAsc:
      list.sort((a, b) => a.duration.compareTo(b.duration));
      break;
  }
  return list;
}

class AllTracksFilterBar extends StatelessWidget {
  const AllTracksFilterBar({
    super.key,
    required this.controller,
    required this.sortOption,
    required this.onQueryChanged,
    required this.onSortOptionChanged,
    required this.totalCount,
    required this.filteredCount,
    required this.onClearQuery,
  });

  final TextEditingController controller;
  final TrackSortOption sortOption;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TrackSortOption> onSortOptionChanged;
  final int totalCount;
  final int filteredCount;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    final isFiltered = controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: EverforestColors.grey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onQueryChanged,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: 'Filter tracks, artists, albums...',
                  hintStyle: TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            if (isFiltered)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: EverforestColors.grey, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Clear filter',
                onPressed: onClearQuery,
              ),
            const SizedBox(width: 6),
            Container(
              height: 16,
              width: 1,
              color: EverforestColors.bg2,
            ),
            const SizedBox(width: 6),
            PopupMenuButton<TrackSortOption>(
              tooltip: 'Sort tracks: ${sortOption.label}',
              color: EverforestColors.bg1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              onSelected: onSortOptionChanged,
              itemBuilder: (ctx) => TrackSortOption.values.map((opt) {
                final isSelected = opt == sortOption;
                return PopupMenuItem<TrackSortOption>(
                  value: opt,
                  child: Row(
                    children: [
                      Icon(opt.icon,
                          color: isSelected
                              ? EverforestColors.aqua
                              : EverforestColors.grey,
                          size: 18),
                      const SizedBox(width: 10),
                      Text(
                        opt.label,
                        style: TextStyle(
                          color: isSelected
                              ? EverforestColors.aqua
                              : EverforestColors.fg,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sortOption.icon,
                        color: EverforestColors.aqua, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isFiltered ? '$filteredCount/$totalCount' : '$totalCount',
                      style: const TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AllTracksSliver extends StatelessWidget {
  const AllTracksSliver({
    super.key,
    required this.tracks,
    required this.offlineDownloading,
    required this.canPlay,
    required this.onDownloadOffline,
    required this.onDeleteTrack,
    required this.onPlay,
    required this.onWebNotice,
    this.onAddToPlaylist,
    this.emptyMessage,
  });

  final List<MusicTrack> tracks;
  final Set<String> offlineDownloading;
  final bool canPlay;
  final void Function(MusicTrack track) onDownloadOffline;
  final void Function(MusicTrack track) onDeleteTrack;
  final void Function(List<MusicTrack> list, int index) onPlay;
  final VoidCallback onWebNotice;
  final void Function(MusicTrack track)? onAddToPlaylist;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: Text(
              emptyMessage ??
                  'No downloaded songs yet.\nSearch YouTube Music above to download!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: EverforestColors.grey, fontSize: 14),
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final t = tracks[i];
          final isOffline = MusicRepository.instance.isOffline(t.id);
          return TrackTile(
            track: t,
            currentList: tracks,
            index: i,
            isOfflineLocal: isOffline,
            isDownloadingOffline: offlineDownloading.contains(t.id),
            canPlay: canPlay,
            onDownloadOffline: onDownloadOffline,
            onDeleteTrack: onDeleteTrack,
            onPlay: onPlay,
            onWebNotice: onWebNotice,
            onAddToPlaylist:
                onAddToPlaylist != null ? () => onAddToPlaylist!(t) : null,
          );
        },
        childCount: tracks.length,
      ),
    );
  }
}

