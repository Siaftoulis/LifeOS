import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/everforest_colors.dart';
import 'create_playlist_dialog.dart';

class AddToPlaylistSheet extends StatefulWidget {
  const AddToPlaylistSheet({
    super.key,
    required this.track,
  });

  final MusicTrack track;

  static Future<void> show(BuildContext context, MusicTrack track) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(track: track),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final Map<String, bool> _playlistMembership = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    final playlists = MusicRepository.instance.playlists.value;
    if (playlists.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait(
        playlists.map((p) async {
          try {
            final tracks =
                await MusicRepository.instance.getPlaylistTracks(p.id);
            final isIn = tracks.any((t) => t.trackId == widget.track.id);
            return MapEntry(p.id, isIn);
          } catch (e) {
            debugPrint('Error loading playlist membership for ${p.id}: $e');
            return MapEntry(p.id, _playlistMembership[p.id] ?? false);
          }
        }),
      );

      if (mounted) {
        setState(() {
          for (final entry in results) {
            _playlistMembership[entry.key] = entry.value;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in concurrent playlist membership loading: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleMembership(Playlist playlist) async {
    final currentlyIn = _playlistMembership[playlist.id] ?? false;
    setState(() => _playlistMembership[playlist.id] = !currentlyIn);

    if (currentlyIn) {
      await MusicRepository.instance
          .removeTrackFromPlaylist(playlist.id, widget.track.id);
    } else {
      await MusicRepository.instance
          .addTrackToPlaylist(playlist.id, widget.track.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add to Playlist',
                        style: TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: EverforestColors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add,
                      color: EverforestColors.green, size: 18),
                  label: const Text(
                    'New',
                    style: TextStyle(
                        color: EverforestColors.green,
                        fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final created = await CreatePlaylistDialog.show(context);
                    if (created != null && mounted) {
                      await _toggleMembership(created);
                      _loadMembership();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(color: EverforestColors.bg2, height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: EverforestColors.green),
                  )
                : ValueListenableBuilder<List<Playlist>>(
                    valueListenable: MusicRepository.instance.playlists,
                    builder: (context, playlists, _) {
                      if (playlists.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.queue_music_rounded,
                                  color: EverforestColors.grey, size: 40),
                              const SizedBox(height: 12),
                              const Text('No playlists created yet',
                                  style: TextStyle(
                                      color: EverforestColors.grey,
                                      fontSize: 14)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Create Playlist'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EverforestColors.green,
                                  foregroundColor: EverforestColors.bg0,
                                ),
                                onPressed: () async {
                                  final created =
                                      await CreatePlaylistDialog.show(context);
                                  if (created != null && mounted) {
                                    await _toggleMembership(created);
                                    _loadMembership();
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: playlists.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final p = playlists[i];
                          final isInPlaylist =
                              _playlistMembership[p.id] ?? false;

                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            tileColor: isInPlaylist
                                ? EverforestColors.green.withValues(alpha: 0.1)
                                : EverforestColors.bg1,
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isInPlaylist
                                    ? EverforestColors.green
                                        .withValues(alpha: 0.2)
                                    : EverforestColors.bg2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                p.isSmart
                                    ? Icons.auto_awesome_rounded
                                    : Icons.playlist_play_rounded,
                                color: isInPlaylist
                                    ? EverforestColors.green
                                    : EverforestColors.grey,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                color: isInPlaylist
                                    ? EverforestColors.green
                                    : EverforestColors.fg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${p.trackCount} tracks${p.description.isNotEmpty ? ' · ${p.description}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: EverforestColors.grey, fontSize: 12),
                            ),
                            trailing: Checkbox(
                              value: isInPlaylist,
                              activeColor: EverforestColors.green,
                              checkColor: EverforestColors.bg0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              onChanged: (_) => _toggleMembership(p),
                            ),
                            onTap: () => _toggleMembership(p),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
