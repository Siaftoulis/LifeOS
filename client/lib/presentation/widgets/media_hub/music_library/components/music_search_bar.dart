import 'package:flutter/material.dart';
import '../../../../../api_client.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../core/music_playback/playback_models.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../music_formatters.dart';
import 'heart_button.dart';

enum MusicSearchQueryType {
  directYouTubeUrl,
  normalSearch,
}

/// Checks whether an input string is clearly a direct YouTube video URL.
bool isDirectYouTubeUrl(String input) {
  return extractYouTubeVideoId(input) != null;
}

/// Extracts an 11-character YouTube video ID from supported URL forms:
/// - https://www.youtube.com/watch?v=...
/// - https://youtube.com/watch?v=...
/// - https://youtu.be/...
/// - https://m.youtube.com/watch?v=...
/// - https://music.youtube.com/watch?v=...
/// - https://www.youtube.com/shorts/...
/// - https://www.youtube.com/embed/...
/// - https://www.youtube.com/v/...
String? extractYouTubeVideoId(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final toParse =
      (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
          ? trimmed
          : 'https://$trimmed';

  final uri = Uri.tryParse(toParse);
  if (uri == null || uri.host.isEmpty) return null;

  final host = uri.host.toLowerCase();
  final isYouTubeHost = host == 'youtube.com' ||
      host.endsWith('.youtube.com') ||
      host == 'youtu.be' ||
      host.endsWith('.youtu.be');

  if (!isYouTubeHost) return null;

  // 1. youtu.be/<id>
  if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final id = pathSegments.first.trim();
      if (_isValidYouTubeId(id)) return id;
    }
    return null;
  }

  // 2. youtube.com/watch?v=<id>
  if (uri.path == '/watch' || uri.path == '/watch/') {
    final v = uri.queryParameters['v']?.trim();
    if (v != null && _isValidYouTubeId(v)) return v;
    return null;
  }

  // 3. youtube.com/shorts/<id>, /embed/<id>, /v/<id>
  final segments = uri.pathSegments;
  if (segments.length >= 2) {
    final first = segments[0].toLowerCase();
    if (first == 'shorts' || first == 'embed' || first == 'v') {
      final id = segments[1].trim();
      if (_isValidYouTubeId(id)) return id;
    }
  }

  return null;
}

bool _isValidYouTubeId(String id) {
  if (id.length != 11) return false;
  final validRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  return validRegex.hasMatch(id);
}

/// Categorizes a search query into either direct YouTube URL or normal query.
MusicSearchQueryType categorizeSearchQuery(String input) {
  if (isDirectYouTubeUrl(input)) {
    return MusicSearchQueryType.directYouTubeUrl;
  }
  return MusicSearchQueryType.normalSearch;
}

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
    final skin = context.skin;
    final isUrl = isDirectYouTubeUrl(query);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: skin.fg, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search or paste YouTube URL...',
          hintStyle: TextStyle(color: skin.textMuted),
          prefixIcon: Icon(
            isUrl ? Icons.link_rounded : Icons.search,
            color: isUrl ? skin.aqua : skin.accent,
          ),
          suffixIcon: isSearching
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: skin.accent,
                    ),
                  ),
                )
              : query.isEmpty
                  ? null
                  : IconButton(
                      icon:
                          Icon(Icons.clear, color: skin.textMuted),
                      onPressed: onClear,
                    ),
          filled: true,
          fillColor: skin.bg1,
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

  Widget _thumbnail(String url, double size, AppSkin skin) {
    final secureUrl = sanitizeMusicThumbnailUrl(url);
    if (secureUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: skin.bg1,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            Icon(Icons.music_note_rounded, color: skin.blue),
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
                color: skin.bg1,
                child: Icon(Icons.music_note_rounded,
                    color: skin.blue),
              )),
    );
  }

  PlaybackItem _itemFromTrack(MusicTrack t) {
    final offline = MusicRepository.instance.offlineFilePath(t.id);
    final url = (offline != null && offline.isNotEmpty)
        ? offline
        : '${ApiClient.instance.daemonUrl}/api/v1/music/stream/?id=${t.id}';
    return PlaybackItem(
      id: t.id,
      url: url,
      title: t.title,
      artist: t.artist,
      thumbnail: t.thumbnail,
      album: t.album,
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    if (isSearching) {
      final isUrl = isDirectYouTubeUrl(query);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: skin.accent),
            const SizedBox(height: 16),
            Text(
              isUrl
                  ? 'Resolving YouTube link...'
                  : 'Searching YouTube Music...',
              style: TextStyle(
                color: skin.fg,
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
            Icon(Icons.error_outline_rounded,
                color: skin.red, size: 40),
            const SizedBox(height: 12),
            Text(searchError!,
                style:
                    TextStyle(color: skin.textMuted, fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: skin.bg1,
                foregroundColor: skin.fg,
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
            Icon(Icons.music_off_rounded,
                color: skin.textMuted, size: 40),
            const SizedBox(height: 12),
            Text('No results found for "$query"',
                style:
                    TextStyle(color: skin.textMuted, fontSize: 15)),
          ],
        ),
      );
    }
    final isWide = MediaQuery.of(context).size.width >= 720;
    return ValueListenableBuilder<List<DownloadQueueItem>>(
      valueListenable: MusicRepository.instance.downloadQueue,
      builder: (context, queue, _) {
        final activeQueueIds = queue
            .where((q) =>
                q.status.toUpperCase() == 'PENDING' ||
                q.status.toUpperCase() == 'DOWNLOADING')
            .map((q) => q.trackId)
            .toSet();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final t = results[i];
            final alreadyDownloaded = MusicRepository.instance.tracks.value
                .any((track) => track.id == t.id);
            final isItemDownloading =
                activeQueueIds.contains(t.id) || downloading.contains(t.id);

            return MouseRegion(
              onEnter: (_) => playbackController.precacheTrack(t.id),
              child: ListTile(
                leading: _thumbnail(t.thumbnail, 48, skin),
              title: Text(t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: skin.fg, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${t.artist}${t.duration > 0 ? ' · ${formatTrackDuration(t.duration)}' : ''}',
                style:
                    TextStyle(color: skin.textMuted, fontSize: 13),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeartButton(track: t, size: 20),
                  const SizedBox(width: 4),
                  if (alreadyDownloaded)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.check_circle_rounded,
                          color: skin.accent, size: 20),
                    )
                  else if (isItemDownloading)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: skin.accent),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.download_rounded,
                          color: skin.accent),
                      tooltip: 'Download to Library',
                      onPressed: () => onDownload(t),
                    ),
                  if (onAddToPlaylist != null)
                    IconButton(
                      icon: Icon(Icons.playlist_add_rounded,
                          color: skin.textMuted, size: 22),
                      tooltip: 'Add to Playlist',
                      onPressed: () => onAddToPlaylist!(t),
                    ),
                  if (isWide) ...[
                    if (canPlay)
                      IconButton(
                        icon: Icon(Icons.play_circle_fill_rounded,
                            color: skin.fg, size: 30),
                        tooltip: 'Play',
                        onPressed: () => playbackController.playQueue(
                            results.map(_itemFromTrack).toList(),
                            startIndex: i),
                      )
                    else
                      Tooltip(
                        message:
                            'Playback is available in the LifeOS native app',
                        child: Icon(
                          Icons.phonelink_lock_rounded,
                          color: skin.textMuted,
                          size: 20,
                        ),
                      ),
                  ],
                ],
              ),
              onTap: canPlay
                  ? () => playbackController
                      .playQueue(results.map(_itemFromTrack).toList(), startIndex: i)
                  : onWebNotice,
            ),
          );
          },
        );
      },
    );
  }
}
