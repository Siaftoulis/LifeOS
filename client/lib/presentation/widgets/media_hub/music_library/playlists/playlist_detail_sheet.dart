import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../core/music_playback/playback_models.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../components/heart_button.dart';
import '../components/music_cover_art.dart';
import '../components/poweramp_track_context_sheet.dart';
import '../music_formatters.dart';
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
    final allMap = <String, MusicTrack>{
      for (var t in MusicRepository.instance.tracks.value) t.id: t,
      for (var o in MusicRepository.instance.offlineTracks.value)
        o.id: MusicTrack(
          id: o.id,
          title: o.title,
          artist: o.artist ?? '',
          album: o.album ?? '',
          thumbnail: o.thumbnail ?? '',
          thumbnailUrl: o.thumbnail ?? '',
          filePath: o.filePath,
          duration: o.duration.toDouble(),
        ),
      for (var e in MusicRepository.instance.knownTrackMetadata.entries)
        e.key: e.value,
    };

    final List<MusicTrack> resolved = [];
    for (final p in pt) {
      if (allMap.containsKey(p.trackId)) {
        final existing = allMap[p.trackId]!;
        final track = existing.filePath.isEmpty && p.track.filePath.isNotEmpty
            ? MusicTrack(
                id: existing.id,
                title: existing.title,
                artist: existing.artist,
                album: existing.album,
                thumbnail: existing.thumbnail,
                thumbnailUrl: existing.thumbnailUrl,
                duration: existing.duration,
                filePath: p.track.filePath,
              )
            : existing;
        resolved.add(track);
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

  PlaybackItem _toPlaybackItem(MusicTrack t) {
    final effectiveUrl = t.filePath.isNotEmpty
        ? t.filePath
        : widget.streamUrlFor(t.id);
    return PlaybackItem(
      id: t.id,
      url: effectiveUrl,
      title: t.title,
      artist: t.artist,
      thumbnail: t.thumbnail.isNotEmpty ? t.thumbnail : t.thumbnailUrl,
      album: t.album,
      filePath: t.filePath,
    );
  }

  Future<void> _playAll({bool shuffle = false}) async {
    if (!widget.canPlay) {
      widget.onWebNotice();
      return;
    }
    if (_fullTracks.isEmpty) return;

    final queue = _fullTracks.map(_toPlaybackItem).toList();

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
    final skin = context.skin;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: skin.bg1,
        title: Text('Delete Playlist',
            style: TextStyle(
                color: skin.red, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${_currentPlaylist.name}"? Songs in this playlist will remain in your library.',
          style: TextStyle(color: skin.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: skin.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: skin.red.withValues(alpha: 0.2),
              foregroundColor: skin.red,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await MusicRepository.instance.deletePlaylist(_currentPlaylist.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _iconForPlaylist(Playlist p) {
    if (!p.isSmart) return Icons.playlist_play_rounded;
    switch (p.smartType.toLowerCase().trim()) {
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

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final isSmart = _currentPlaylist.isSmart;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: skin.bg0,
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
                    color: isSmart
                        ? skin.yellow.withValues(alpha: 0.15)
                        : skin.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSmart
                          ? skin.yellow.withValues(alpha: 0.35)
                          : skin.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    _iconForPlaylist(_currentPlaylist),
                    color: isSmart ? skin.yellow : skin.accent,
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
                          if (isSmart) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: skin.yellow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SMART MIX',
                                style: TextStyle(
                                  color: skin.yellow,
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
                              style: TextStyle(
                                color: skin.fg,
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
                            : (isSmart
                                ? 'Rule: ${_currentPlaylist.smartType}${_currentPlaylist.smartConfig.isNotEmpty ? " (${_currentPlaylist.smartConfig})" : ""}'
                                : '${_fullTracks.length} tracks'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: skin.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_fullTracks.length} songs',
                        style: TextStyle(
                          color: isSmart ? skin.yellow : skin.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_rounded,
                      color: skin.textMuted, size: 20),
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
                  icon: Icon(Icons.delete_outline_rounded,
                      color: skin.red, size: 20),
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
                      backgroundColor: isSmart ? skin.yellow : skin.accent,
                      foregroundColor: isSmart ? Colors.black : skin.accentContrast,
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
                      foregroundColor: skin.fg,
                      side: BorderSide(color: skin.bg2),
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

          Divider(color: skin.bg2, height: 16),

          // Track List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: isSmart ? skin.yellow : skin.accent),
                  )
                : _fullTracks.isEmpty
                    ? Center(
                        child: Text(
                          isSmart
                              ? 'No songs matching this rule yet.\nImport local files or download matching tracks!'
                              : 'No songs in this playlist yet.\nTap ... on any track to add it!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: skin.textMuted, fontSize: 14),
                        ),
                      )
                    : isSmart
                        ? ListView.builder(
                            padding: const EdgeInsets.only(bottom: 40),
                            itemCount: _fullTracks.length,
                            itemBuilder: (context, i) {
                              final t = _fullTracks[i];
                              return _buildTrackTile(context, t, i, skin, isSmart: true);
                            },
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 40),
                            itemCount: _fullTracks.length,
                            // ignore: deprecated_member_use
                            onReorder: _reorder,
                            itemBuilder: (context, i) {
                              final t = _fullTracks[i];
                              return _buildTrackTile(context, t, i, skin, isSmart: false);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(
    BuildContext context,
    MusicTrack t,
    int index,
    dynamic skin, {
    required bool isSmart,
  }) {
    return ListTile(
      key: ValueKey('${t.id}_$index'),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSmart) ...[
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded,
                  color: skin.textMuted, size: 20),
            ),
            const SizedBox(width: 8),
          ] else ...[
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: skin.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          MusicCoverArt(
            url: t.thumbnail.isNotEmpty ? t.thumbnail : t.thumbnailUrl,
            size: 42,
            borderRadius: 8,
          ),
        ],
      ),
      title: Text(
        t.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: skin.fg,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${t.artist}${t.duration > 0 ? ' · ${formatTrackDuration(t.duration)}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: skin.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeartButton(track: t, size: 18),
          if (!isSmart)
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  color: skin.textMuted, size: 18),
              tooltip: 'Remove from playlist',
              onPressed: () => _deleteTrack(index),
            ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: skin.textMuted, size: 20),
            tooltip: 'Track options',
            onPressed: () {
              PowerampTrackContextSheet.show(
                context,
                track: t,
              );
            },
          ),
        ],
      ),
      onTap: widget.canPlay
          ? () => widget.playbackController.playQueue(
                _fullTracks.map(_toPlaybackItem).toList(),
                startIndex: index,
              )
          : widget.onWebNotice,
      onLongPress: () {
        PowerampTrackContextSheet.show(
          context,
          track: t,
        );
      },
    );
  }
}
