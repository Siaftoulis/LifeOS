import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../core/music_playback/playback_models.dart';
import '../../../../../theme/everforest_colors.dart';
import '../components/heart_button.dart';
import '../tabs/all_tracks_sliver.dart';
import 'create_playlist_dialog.dart';

class PlaylistDetailSheet extends StatefulWidget {
  const PlaylistDetailSheet({
    super.key,
    required this.playlist,
    required this.canPlay,
    required this.playbackController,
    required this.onWebNotice,
    required this.streamUrlFor,
  });

  final Playlist playlist;
  final bool canPlay;
  final PlaybackController playbackController;
  final VoidCallback onWebNotice;
  final String Function(String trackId) streamUrlFor;

  static Future<void> show(
    BuildContext context, {
    required Playlist playlist,
    required bool canPlay,
    required PlaybackController playbackController,
    required VoidCallback onWebNotice,
    required String Function(String trackId) streamUrlFor,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaylistDetailSheet(
        playlist: playlist,
        canPlay: canPlay,
        playbackController: playbackController,
        onWebNotice: onWebNotice,
        streamUrlFor: streamUrlFor,
      ),
    );
  }

  @override
  State<PlaylistDetailSheet> createState() => _PlaylistDetailSheetState();
}

class _PlaylistDetailSheetState extends State<PlaylistDetailSheet> {
  late Playlist _currentPlaylist;
  List<PlaylistTrack> _playlistTracks = [];
  List<MusicTrack> _fullTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final pt =
        await MusicRepository.instance.getPlaylistTracks(_currentPlaylist.id);
    final allMap = {for (var t in MusicRepository.instance.tracks.value) t.id: t};

    final List<MusicTrack> resolved = [];
    for (final p in pt) {
      if (allMap.containsKey(p.trackId)) {
        resolved.add(allMap[p.trackId]!);
      } else if (p.track.id.isNotEmpty &&
          ((p.track.title.isNotEmpty && p.track.title != 'Unknown') ||
              (p.track.artist.isNotEmpty && p.track.artist != 'Unknown'))) {
        resolved.add(p.track);
        MusicRepository.instance.rememberTrack(p.track);
      } else {
        final fallback = MusicTrack(
          id: p.trackId,
          title: p.track.title.isNotEmpty && p.track.title != 'Unknown'
              ? p.track.title
              : 'Track ${p.trackId}',
          artist: p.track.artist.isNotEmpty && p.track.artist != 'Unknown'
              ? p.track.artist
              : 'Unknown Artist',
          album: p.track.album,
          thumbnail: p.track.thumbnail,
          duration: p.track.duration,
          filePath: p.track.filePath,
        );
        resolved.add(fallback);
      }
    }

    if (mounted) {
      setState(() {
        _playlistTracks = pt;
        _fullTracks = resolved;
        _isLoading = false;
      });
    }
  }

  String _fmt(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final remS = s % 60;
    return '$m:${remS.toString().padLeft(2, '0')}';
  }

  Future<void> _playAll({bool shuffle = false}) async {
    if (!widget.canPlay) {
      widget.onWebNotice();
      return;
    }
    if (_fullTracks.isEmpty) return;

    final queue = _fullTracks
        .map((t) => PlaybackItem(
              id: t.id,
              url: widget.streamUrlFor(t.id),
              title: t.title,
              artist: t.artist,
              thumbnail: t.thumbnail,
              album: t.album,
            ))
        .toList();

    if (shuffle) queue.shuffle();
    await widget.playbackController.playQueue(queue, startIndex: 0);
  }

  Future<void> _deleteTrack(int index) async {
    final t = _playlistTracks[index];
    setState(() {
      _playlistTracks.removeAt(index);
      _fullTracks.removeAt(index);
    });
    await MusicRepository.instance
        .removeTrackFromPlaylist(_currentPlaylist.id, t.trackId);
    await MusicRepository.instance.loadPlaylists();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final pt = _playlistTracks.removeAt(oldIndex);
    final ft = _fullTracks.removeAt(oldIndex);
    _playlistTracks.insert(newIndex, pt);
    _fullTracks.insert(newIndex, ft);
    setState(() {});

    await MusicRepository.instance.reorderPlaylistTrack(
      _currentPlaylist.id,
      pt.trackId,
      newIndex,
    );
  }

  void _confirmDeletePlaylist() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Delete Playlist',
            style: TextStyle(
                color: EverforestColors.red, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${_currentPlaylist.name}"? Songs in this playlist will remain in your library.',
          style: const TextStyle(color: EverforestColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.red.withValues(alpha: 0.2),
              foregroundColor: EverforestColors.red,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await MusicRepository.instance.deletePlaylist(_currentPlaylist.id);
              await MusicRepository.instance.loadPlaylists();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: EverforestColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: EverforestColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    _currentPlaylist.isSmart
                        ? Icons.auto_awesome_rounded
                        : Icons.playlist_play_rounded,
                    color: EverforestColors.green,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_currentPlaylist.isSmart) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: EverforestColors.yellow
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'SMART MIX',
                                style: TextStyle(
                                  color: EverforestColors.yellow,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _currentPlaylist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentPlaylist.description.isNotEmpty
                            ? _currentPlaylist.description
                            : '${_fullTracks.length} tracks',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: EverforestColors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_fullTracks.length} songs',
                        style: const TextStyle(
                          color: EverforestColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      color: EverforestColors.grey, size: 20),
                  tooltip: 'Edit Details',
                  onPressed: () async {
                    final updated = await CreatePlaylistDialog.show(
                      context,
                      initialPlaylist: _currentPlaylist,
                    );
                    if (updated != null && mounted) {
                      setState(() => _currentPlaylist = updated);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: EverforestColors.red, size: 20),
                  tooltip: 'Delete Playlist',
                  onPressed: _confirmDeletePlaylist,
                ),
              ],
            ),
          ),

          // Action Buttons: Play All & Shuffle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('Play All',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EverforestColors.green,
                      foregroundColor: EverforestColors.bg0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _fullTracks.isNotEmpty ? () => _playAll() : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text('Shuffle',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EverforestColors.fg,
                      side: const BorderSide(color: EverforestColors.bg2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _fullTracks.isNotEmpty
                        ? () => _playAll(shuffle: true)
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: EverforestColors.bg2, height: 16),

          // Reorderable Track List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: EverforestColors.green),
                  )
                : _fullTracks.isEmpty
                    ? const Center(
                        child: Text(
                          'No songs in this playlist yet.\nTap ... on any track to add it!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: EverforestColors.grey, fontSize: 14),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: _fullTracks.length,
                        // ignore: deprecated_member_use
                        onReorder: _reorder,
                        itemBuilder: (context, i) {
                          final t = _fullTracks[i];
                          return ListTile(
                            key: ValueKey(t.id + i.toString()),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(Icons.drag_handle_rounded,
                                      color: EverforestColors.grey, size: 20),
                                ),
                                const SizedBox(width: 10),
                                TrackThumbnail(url: t.thumbnail, size: 40),
                              ],
                            ),
                            title: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: EverforestColors.fg,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${t.artist}${t.duration > 0 ? ' · ${_fmt(t.duration)}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: EverforestColors.grey, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HeartButton(track: t, size: 18),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: EverforestColors.grey, size: 18),
                                  tooltip: 'Remove from playlist',
                                  onPressed: () => _deleteTrack(i),
                                ),
                              ],
                            ),
                            onTap: widget.canPlay
                                ? () => widget.playbackController.playQueue(
                                      _fullTracks
                                          .map((x) => PlaybackItem(
                                                id: x.id,
                                                url: widget.streamUrlFor(x.id),
                                                title: x.title,
                                                artist: x.artist,
                                                thumbnail: x.thumbnail,
                                                album: x.album,
                                              ))
                                          .toList(),
                                      startIndex: i,
                                    )
                                : widget.onWebNotice,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
