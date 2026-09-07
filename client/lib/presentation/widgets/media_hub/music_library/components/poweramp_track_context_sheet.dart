import 'package:flutter/material.dart';
import '../../../../../api_client.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../core/music_playback/playback_models.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../music_formatters.dart';
import '../playlists/add_to_playlist_sheet.dart';
import '../track_metadata_modal.dart';

/// Poweramp Long-Press Track Contextual Action Sheet.
class PowerampTrackContextSheet extends StatelessWidget {
  final MusicTrack track;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onDelete;

  const PowerampTrackContextSheet({
    super.key,
    required this.track,
    this.onPlayNext,
    this.onAddToQueue,
    this.onDelete,
  });

  static void show(
    BuildContext context, {
    required MusicTrack track,
    VoidCallback? onPlayNext,
    VoidCallback? onAddToQueue,
    VoidCallback? onDelete,
  }) {
    final skin = context.skin;
    showModalBottomSheet(
      context: context,
      backgroundColor: skin.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PowerampTrackContextSheet(
        track: track,
        onPlayNext: onPlayNext,
        onAddToQueue: onAddToQueue,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Center drag handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Track Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: skin.bg2,
                    child: track.thumbnail.isNotEmpty
                        ? Image.network(
                            sanitizeMusicThumbnailUrl(track.thumbnail),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.music_note_rounded,
                              color: skin.accent,
                              size: 26,
                            ),
                          )
                        : Icon(
                            Icons.music_note_rounded,
                            color: skin.accent,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: skin.fg,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${track.artist.isNotEmpty ? track.artist : "Unknown Artist"} · ${formatTrackDuration(track.duration)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: skin.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 6),

            // 0. Start YouTube Music Radio
            _buildActionTile(
              icon: Icons.sensors_rounded,
              title: 'Start YouTube Music Radio',
              subtitle: 'Algorithmic endless mix based on this track',
              skin: skin,
              onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Starting Radio based on "${track.title}"...'),
                    backgroundColor: skin.bg1,
                  ),
                );
                final recs = await MusicRepository.instance.getRecommendations(
                  seedTrackId: track.id,
                  limit: 20,
                );
                final streamUrl = track.filePath.isNotEmpty
                    ? track.filePath
                    : '${ApiClient.instance.daemonUrl}/api/v1/music/ytstream/stream.m4a?id=${track.id}';
                final queue = [
                  PlaybackItem(
                    id: track.id,
                    url: streamUrl,
                    title: track.title,
                    artist: track.artist,
                    thumbnail: track.thumbnail,
                    album: track.album,
                  ),
                  for (final r in recs)
                    PlaybackItem(
                      id: r.id,
                      url: r.filePath.isNotEmpty
                          ? r.filePath
                          : '${ApiClient.instance.daemonUrl}/api/v1/music/ytstream/stream.m4a?id=${r.id}',
                      title: r.title,
                      artist: r.artist,
                      thumbnail: r.thumbnail,
                      album: r.album,
                    ),
                ];
                PlaybackController.instance.playQueue(queue, startIndex: 0);
              },
            ),

            // 1. Play Next
            _buildActionTile(
              icon: Icons.playlist_play_rounded,
              title: 'Play Next',
              subtitle: 'Insert immediately after current track',
              skin: skin,
              onTap: () {
                Navigator.pop(context);
                final item = PlaybackItem(
                  id: track.id,
                  url: '',
                  title: track.title,
                  artist: track.artist,
                  album: track.album,
                  thumbnail: track.thumbnail,
                );
                PlaybackController.instance.insertNext(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playing next: ${track.title}'),
                    backgroundColor: skin.bg1,
                  ),
                );
              },
            ),

            // 2. Add to Queue
            _buildActionTile(
              icon: Icons.queue_music_rounded,
              title: 'Add to Queue',
              subtitle: 'Append to the end of the current queue',
              skin: skin,
              onTap: () {
                Navigator.pop(context);
                final item = PlaybackItem(
                  id: track.id,
                  url: '',
                  title: track.title,
                  artist: track.artist,
                  album: track.album,
                  thumbnail: track.thumbnail,
                );
                PlaybackController.instance.addToQueue(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to queue: ${track.title}'),
                    backgroundColor: skin.bg1,
                  ),
                );
              },
            ),

            // 3. Add to Playlist
            _buildActionTile(
              icon: Icons.playlist_add_rounded,
              title: 'Add to Playlist',
              subtitle: 'Save to a custom or existing playlist',
              skin: skin,
              onTap: () {
                Navigator.pop(context);
                AddToPlaylistSheet.show(context, track);
              },
            ),

            // 4. Track Info / Tags
            _buildActionTile(
              icon: Icons.info_outline_rounded,
              title: 'Track Info & Audio Tags',
              subtitle: 'Inspect bitrate, format, sampling rate, path',
              skin: skin,
              onTap: () {
                Navigator.pop(context);
                TrackMetadataModal.show(
                  context,
                  title: track.title,
                  artist: track.artist,
                  album: track.album,
                  trackId: track.id,
                  url: '',
                  duration: Duration(seconds: track.duration.round()),
                  track: track,
                );
              },
            ),

            // 5. Toggle Favorite
            ValueListenableBuilder<Set<String>>(
              valueListenable: MusicRepository.instance.likedTrackIds,
              builder: (context, likedIds, _) {
                final isLiked = likedIds.contains(track.id);
                return _buildActionTile(
                  icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isLiked ? skin.red : skin.fg,
                  title: isLiked ? 'Remove from Favorites' : 'Add to Favorites',
                  subtitle: isLiked ? 'Saved in Liked Songs' : 'Mark as liked',
                  skin: skin,
                  onTap: () async {
                    Navigator.pop(context);
                    await MusicRepository.instance.toggleLike(track);
                  },
                );
              },
            ),

            // 6. Delete
            if (onDelete != null)
              _buildActionTile(
                icon: Icons.delete_outline_rounded,
                iconColor: skin.red,
                title: 'Delete from Library',
                subtitle: 'Remove audio file from disk',
                skin: skin,
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppSkin skin,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? skin.fg, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: skin.fg,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: skin.textMuted,
          fontSize: 11.5,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onTap: onTap,
    );
  }
}
