import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../core/music_playback/playback_models.dart';
import '../../../../../database/database.dart' hide MusicTrack;
import '../../../../../theme/everforest_colors.dart';
import 'all_tracks_sliver.dart';

class OfflineTracksSliver extends StatelessWidget {
  const OfflineTracksSliver({
    super.key,
    required this.currentTrackId,
    required this.canPlay,
    required this.playbackController,
    required this.onDeleteOffline,
    required this.onWebNotice,
    required this.streamUrlFor,
  });

  final String currentTrackId;
  final bool canPlay;
  final PlaybackController playbackController;
  final void Function(OfflineMusicTrack track) onDeleteOffline;
  final VoidCallback onWebNotice;
  final String Function(String trackId) streamUrlFor;

  String _fmt(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final remS = s % 60;
    return '$m:${remS.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OfflineMusicTrack>>(
      valueListenable: MusicRepository.instance.offlineTracks,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: Text(
                  'Nothing saved to this device yet.\nTap the download icon on any song to make it\nplayable offline — no internet needed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 15,
                      height: 1.5),
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final o = list[i];
              final isPlaying = currentTrackId == o.id;
              final playQueue = list
                  .map((x) => PlaybackItem(
                        id: x.id,
                        url: x.filePath.isNotEmpty
                            ? Uri.file(x.filePath).toString()
                            : streamUrlFor(x.id),
                        title: x.title,
                        artist: x.artist ?? '',
                        thumbnail: x.thumbnail ?? '',
                        album: x.album ?? '',
                      ))
                  .toList();
              return ListTile(
                leading: Stack(
                  children: [
                    TrackThumbnail(url: o.thumbnail ?? '', size: 48),
                    if (isPlaying)
                      const Positioned(
                        right: 2,
                        bottom: 2,
                        child: Icon(Icons.graphic_eq_rounded,
                            color: EverforestColors.green, size: 16),
                      ),
                  ],
                ),
                title: Text(o.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying
                          ? EverforestColors.green
                          : EverforestColors.fg,
                      fontWeight: FontWeight.w600,
                    )),
                subtitle: Text(
                  '${o.artist ?? 'Unknown'}${o.duration > 0 ? ' · ${_fmt(o.duration)}' : ''} · 📱 On this device',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: EverforestColors.grey, fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: EverforestColors.grey, size: 20),
                      tooltip: 'Remove from this device',
                      onPressed: () => onDeleteOffline(o),
                    ),
                    if (canPlay)
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill_rounded,
                            color: EverforestColors.fg, size: 32),
                        onPressed: () => playbackController.playQueue(playQueue,
                            startIndex: i),
                      )
                    else
                      const Tooltip(
                        message:
                            'Playback is available in the LifeOS native app',
                        child: Icon(Icons.phonelink_lock_rounded,
                            color: EverforestColors.grey, size: 20),
                      ),
                  ],
                ),
                onTap: canPlay
                    ? () =>
                        playbackController.playQueue(playQueue, startIndex: i)
                    : onWebNotice,
              );
            },
            childCount: list.length,
          ),
        );
      },
    );
  }
}

class PhoneSongsSliver extends StatelessWidget {
  const PhoneSongsSliver({
    super.key,
    required this.phoneSongs,
    required this.playbackController,
  });

  final List<SongModel> phoneSongs;
  final PlaybackController playbackController;

  String _fmt(double ms) {
    final s = (ms / 1000).round();
    final m = s ~/ 60;
    final remS = s % 60;
    return '$m:${remS.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'On This Phone',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final s = phoneSongs[i];
              final phoneQueue = phoneSongs
                  .map((x) => PlaybackItem(
                        id: x.uri ?? x.id.toString(),
                        url: x.uri ?? '',
                        title: x.title,
                        artist: x.artist ?? '',
                        thumbnail: '',
                        album: x.album ?? '',
                      ))
                  .toList();
              return ListTile(
                leading: const Icon(Icons.music_note_rounded,
                    color: EverforestColors.blue, size: 40),
                title: Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: EverforestColors.fg,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${s.artist} · ${_fmt((s.duration ?? 0).toDouble())}',
                  style: const TextStyle(
                      color: EverforestColors.grey, fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded,
                      color: EverforestColors.fg, size: 32),
                  onPressed: () =>
                      playbackController.playQueue(phoneQueue, startIndex: i),
                ),
                onTap: () =>
                    playbackController.playQueue(phoneQueue, startIndex: i),
              );
            },
            childCount: phoneSongs.length,
          ),
        ),
      ],
    );
  }
}
