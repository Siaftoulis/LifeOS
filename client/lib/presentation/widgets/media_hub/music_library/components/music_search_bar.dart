import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../api_client.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../core/music_playback/playback_models.dart';
import '../../../../../theme/everforest_colors.dart';
import 'heart_button.dart';

class MusicSearchBar extends StatelessWidget {
  const MusicSearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.query,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isSearching;
  final String query;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search YouTube Music...',
          hintStyle: const TextStyle(color: EverforestColors.grey),
          prefixIcon: const Icon(Icons.search, color: EverforestColors.green),
          suffixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EverforestColors.green,
                    ),
                  ),
                )
              : query.isEmpty
                  ? null
                  : IconButton(
                      icon:
                          const Icon(Icons.clear, color: EverforestColors.grey),
                      onPressed: onClear,
                    ),
          filled: true,
          fillColor: EverforestColors.bg1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class MusicSearchResults extends StatelessWidget {
  const MusicSearchResults({
    super.key,
    required this.isSearching,
    required this.searchError,
    required this.query,
    required this.results,
    required this.downloading,
    required this.canPlay,
    required this.playbackController,
    required this.onRetry,
    required this.onDownload,
    required this.onWebNotice,
    this.onAddToPlaylist,
  });

  final bool isSearching;
  final String? searchError;
  final String query;
  final List<MusicTrack> results;
  final Set<String> downloading;
  final bool canPlay;
  final PlaybackController playbackController;
  final VoidCallback onRetry;
  final void Function(MusicTrack track) onDownload;
  final VoidCallback onWebNotice;
  final void Function(MusicTrack track)? onAddToPlaylist;

  String _sanitizeThumbnailUrl(String url) {
    if (kIsWeb && Uri.base.scheme == 'https' && url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  Widget _thumbnail(String url, double size) {
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
      child: Image.network(secureUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: EverforestColors.bg1,
                child: const Icon(Icons.music_note_rounded,
                    color: EverforestColors.blue),
              )),
    );
  }

  String _fmt(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final remS = s % 60;
    return '$m:${remS.toString().padLeft(2, '0')}';
  }

  PlaybackItem _itemFromTrack(MusicTrack t) => PlaybackItem(
        id: t.id,
        url: '${ApiClient.instance.daemonUrl}/api/v1/music/stream/?id=${t.id}',
        title: t.title,
        artist: t.artist,
        thumbnail: t.thumbnail,
        album: t.album,
      );

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: EverforestColors.green),
            SizedBox(height: 16),
            Text(
              'Searching YouTube Music...',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    if (searchError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: EverforestColors.red, size: 40),
            const SizedBox(height: 12),
            Text(searchError!,
                style:
                    const TextStyle(color: EverforestColors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EverforestColors.bg1,
                foregroundColor: EverforestColors.fg,
              ),
            ),
          ],
        ),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off_rounded,
                color: EverforestColors.grey, size: 40),
            const SizedBox(height: 12),
            Text('No results found for "$query"',
                style:
                    const TextStyle(color: EverforestColors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final t = results[i];
        final alreadyDownloaded = MusicRepository.instance.tracks.value
            .any((track) => track.id == t.id);
        return ListTile(
          leading: _thumbnail(t.thumbnail, 48),
          title: Text(t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: EverforestColors.fg, fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${t.artist}${t.duration > 0 ? ' · ${_fmt(t.duration)}' : ''}',
            style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeartButton(track: t, size: 20),
              const SizedBox(width: 4),
              if (alreadyDownloaded)
                const Icon(Icons.check_circle_rounded,
                    color: EverforestColors.green)
              else if (downloading.contains(t.id))
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: EverforestColors.green),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.download_rounded,
                      color: EverforestColors.green),
                  onPressed: () => onDownload(t),
                ),
              if (onAddToPlaylist != null)
                IconButton(
                  icon: const Icon(Icons.playlist_add_rounded,
                      color: EverforestColors.grey, size: 22),
                  tooltip: 'Add to Playlist',
                  onPressed: () => onAddToPlaylist!(t),
                ),
              if (canPlay)
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded,
                      color: EverforestColors.fg, size: 32),
                  onPressed: () => playbackController.playQueue(
                      results.map(_itemFromTrack).toList(),
                      startIndex: i),
                )
              else
                const Tooltip(
                  message: 'Playback is available in the LifeOS native app',
                  child: Icon(
                    Icons.phonelink_lock_rounded,
                    color: EverforestColors.grey,
                    size: 22,
                  ),
                ),
            ],
          ),
          onTap: canPlay
              ? () => playbackController
                  .playQueue(results.map(_itemFromTrack).toList(), startIndex: i)
              : onWebNotice,
        );
      },
    );
  }
}
