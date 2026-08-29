import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/everforest_colors.dart';

class TrackThumbnail extends StatelessWidget {
  const TrackThumbnail({super.key, required this.url, this.size = 48});

  final String url;
  final double size;

  String _sanitizeThumbnailUrl(String url) {
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
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            const Icon(Icons.music_note_rounded, color: EverforestColors.blue),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
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

  String _fmt(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final remS = s % 60;
    return '$m:${remS.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: TrackThumbnail(url: track.thumbnail, size: 48),
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
          if (isOfflineLocal)
            const Icon(Icons.download_done_rounded,
                color: EverforestColors.green, size: 20)
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
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: EverforestColors.grey, size: 20),
            tooltip: 'Delete Song',
            onPressed: () => onDeleteTrack(track),
          ),
          if (canPlay)
            IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded,
                  color: EverforestColors.fg, size: 32),
              onPressed: () => onPlay(currentList, index),
            )
          else
            const Tooltip(
              message: 'Playback is available in the LifeOS native app',
              child: Icon(Icons.phonelink_lock_rounded,
                  color: EverforestColors.grey, size: 20),
            ),
        ],
      ),
      onTap: canPlay ? () => onPlay(currentList, index) : onWebNotice,
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
  });

  final List<MusicTrack> tracks;
  final Set<String> offlineDownloading;
  final bool canPlay;
  final void Function(MusicTrack track) onDownloadOffline;
  final void Function(MusicTrack track) onDeleteTrack;
  final void Function(List<MusicTrack> list, int index) onPlay;
  final VoidCallback onWebNotice;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: Text(
              'No downloaded songs yet.\nSearch YouTube Music above to download!',
              textAlign: TextAlign.center,
              style: TextStyle(color: EverforestColors.grey, fontSize: 15),
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
          );
        },
        childCount: tracks.length,
      ),
    );
  }
}
