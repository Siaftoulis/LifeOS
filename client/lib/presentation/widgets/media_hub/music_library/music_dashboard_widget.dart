import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../api_client.dart';
import '../../../../core/audio_dsp_service.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../core/music_playback/playback_controller.dart';
import '../../../../core/music_playback/playback_models.dart';
import '../../../../core/telemetry/telemetry_reporter.dart';
import '../../../../database/database.dart' hide MusicTrack;
import '../../../../theme/everforest_colors.dart';
import 'components/download_queue_sheet.dart';
import 'components/music_mini_player.dart';
import 'components/music_search_bar.dart';
import 'components/music_stats_sheet.dart';
import 'lyrics_sync_viewer.dart';
import 'playlists/add_to_playlist_sheet.dart';
import 'poweramp_now_playing_sheet.dart';
import 'poweramp_queue_sheet.dart';
import 'tabs/all_tracks_sliver.dart';
import 'tabs/artists_and_genres_slivers.dart';
import 'tabs/liked_songs_sliver.dart';
import 'tabs/offline_tracks_sliver.dart';
import 'tabs/playlists_tab_sliver.dart';
import 'tabs/smart_mixes_sliver.dart';

export 'components/download_queue_sheet.dart';
export 'components/heart_button.dart';
export 'components/music_mini_player.dart';
export 'components/music_search_bar.dart';
export 'components/music_stats_sheet.dart';
export 'playlists/add_to_playlist_sheet.dart';
export 'playlists/create_playlist_dialog.dart';
export 'playlists/playlist_detail_sheet.dart';
export 'tabs/all_tracks_sliver.dart';
export 'tabs/artists_and_genres_slivers.dart';
export 'tabs/liked_songs_sliver.dart';
export 'tabs/offline_tracks_sliver.dart';
export 'tabs/playlists_tab_sliver.dart';
export 'tabs/smart_mixes_sliver.dart';

class MusicDashboardWidget extends StatefulWidget {
  const MusicDashboardWidget({super.key});

  /// Cache for track genre classification
  static final Map<String, String> _trackGenreCache = {};

  /// Static helper for testing and track-level memoized genre classification.
  static String classifyTrackGenre(MusicTrack t) {
    final cacheKey = '${t.id}:${t.title}:${t.artist}:${t.album}';
    final cached = _trackGenreCache[cacheKey];
    if (cached != null) return cached;

    final combined = '${t.title} ${t.artist} ${t.album}'.toLowerCase();
    final greekRegex = RegExp(r'[\u0370-\u03FF]');

    String genre;
    if (greekRegex.hasMatch(t.title) ||
        greekRegex.hasMatch(t.artist) ||
        combined.contains('parios') ||
        combined.contains('mitropanos') ||
        combined.contains('sfakianakis') ||
        combined.contains('remos') ||
        combined.contains('argiros') ||
        combined.contains('vertis') ||
        combined.contains('pantelidis') ||
        combined.contains('papakonstantinou') ||
        combined.contains('laiko') ||
        combined.contains('zeimbekiko')) {
      genre = '🏛️ Greek / Ελληνικά';
    } else if (combined.contains('rock') ||
        combined.contains('metal') ||
        combined.contains('queen') ||
        combined.contains('metallica') ||
        combined.contains('nirvana') ||
        combined.contains('scorpions') ||
        combined.contains('pink floyd') ||
        combined.contains('guitar') ||
        combined.contains('punk') ||
        combined.contains('linkin park')) {
      genre = '🎸 Rock & Metal';
    } else if (combined.contains('rap') ||
        combined.contains('hip hop') ||
        combined.contains('hip-hop') ||
        combined.contains('trap') ||
        combined.contains('eminem') ||
        combined.contains('drake') ||
        combined.contains('kanye') ||
        combined.contains('tupac') ||
        combined.contains('snoop') ||
        combined.contains('kendrick') ||
        combined.contains('light') ||
        combined.contains('snik') ||
        combined.contains('toquel') ||
        combined.contains('trannos')) {
      genre = '🎤 Hip-Hop & Rap';
    } else if (combined.contains('edm') ||
        combined.contains('house') ||
        combined.contains('dance') ||
        combined.contains('techno') ||
        combined.contains('club') ||
        combined.contains('remix') ||
        combined.contains('tiesto') ||
        combined.contains('guetta') ||
        combined.contains('avicii') ||
        combined.contains('calvin') ||
        combined.contains('garrix')) {
      genre = '⚡ Electronic & Club';
    } else if (combined.contains('acoustic') ||
        combined.contains('ballad') ||
        combined.contains('unplugged') ||
        combined.contains('piano') ||
        combined.contains('slow') ||
        combined.contains('love') ||
        combined.contains('romantic')) {
      genre = '🌙 Acoustic & Ballads';
    } else if (combined.contains('chill') ||
        combined.contains('lofi') ||
        combined.contains('lo-fi') ||
        combined.contains('ambient') ||
        combined.contains('jazz') ||
        combined.contains('relax') ||
        combined.contains('focus') ||
        combined.contains('blues')) {
      genre = '☕ Chill & Relax';
    } else {
      genre = '✨ Pop & Chart Hits';
    }

    _trackGenreCache[cacheKey] = genre;
    return genre;
  }

  static void clearGenreCache() {
    _trackGenreCache.clear();
  }

  @override
  State<MusicDashboardWidget> createState() => _MusicDashboardWidgetState();
}

class _MusicDashboardWidgetState extends State<MusicDashboardWidget> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final TextEditingController _searchCtrl = TextEditingController();

  List<MusicTrack> _results = [];
  List<SongModel> _phoneSongs = [];
  String _query = '';
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounceTimer;

  String _currentTitle = '';
  String _currentArtist = '';
  String _currentAlbum = '';
  String _currentTrackId = '';
  String _currentStreamUrl = '';
  String _currentThumbnail = '';

  final Set<String> _downloading = {};
  final Set<String> _offlineDownloading = {};

  bool get _canPlay => !kIsWeb;
  bool get _hasActivePlayback =>
      _canPlay && _currentTrackId.isNotEmpty && _pc.currentItem != null;
  PlaybackController get _pc => PlaybackController.instance;

  int _libraryTab = 0;
  String? _selectedArtist;
  String? _selectedGenre;
  String _localTrackFilter = '';
  TrackSortOption _trackSortOption = TrackSortOption.titleAsc;
  final TextEditingController _localFilterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(AudioDspService.instance.init());
    unawaited(_pc.ensureInitialized());
    _loadPhoneSongs();
    MusicRepository.instance.refresh();
    MusicRepository.instance.loadOffline();
    MusicRepository.instance.tracks.addListener(_tracksChanged);
    MusicRepository.instance.downloadQueue.addListener(_downloadQueueChanged);
    _pc.addListener(_playbackChanged);
    _playbackChanged();
  }

  void _playbackChanged() {
    final item = _pc.currentItem;
    if (!mounted) return;
    if (item == null) {
      if (_currentTrackId.isNotEmpty) {
        setState(() {
          _currentTrackId = '';
          _currentStreamUrl = '';
          _currentTitle = '';
          _currentArtist = '';
          _currentAlbum = '';
          _currentThumbnail = '';
        });
      }
      return;
    }
    if (item.id == _currentTrackId) return;
    setState(() {
      _currentTrackId = item.id;
      _currentStreamUrl = item.url;
      _currentTitle = item.title;
      _currentArtist = item.artist;
      _currentAlbum = item.album;
      _currentThumbnail = item.thumbnail;
    });
    TelemetryReporter.instance
        .track('music', 'track_streamed', {'track_id': item.id});
  }

  void _tracksChanged() {
    _lastGroupedTracks = null;
    _cachedGenreGroups = null;
    final libraryIds =
        MusicRepository.instance.tracks.value.map((t) => t.id).toSet();
    final done = _downloading.intersection(libraryIds);
    if (done.isNotEmpty) {
      setState(() => _downloading.removeAll(done));
    }
  }

  void _downloadQueueChanged() {
    if (!mounted) return;
    final queue = MusicRepository.instance.downloadQueue.value;
    final finishedOrFailed = queue
        .where((q) {
          final s = q.status.toUpperCase();
          return s == 'COMPLETED' || s == 'FAILED' || s == 'CANCELLED';
        })
        .map((q) => q.trackId)
        .toSet();

    if (_downloading.any(finishedOrFailed.contains)) {
      setState(() {
        _downloading.removeWhere(finishedOrFailed.contains);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    MusicRepository.instance.tracks.removeListener(_tracksChanged);
    MusicRepository.instance.downloadQueue.removeListener(_downloadQueueChanged);
    _pc.removeListener(_playbackChanged);
    _searchCtrl.dispose();
    _localFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPhoneSongs() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _audioQuery.checkAndRequest();
      final songs = await _audioQuery.querySongs(sortType: SongSortType.TITLE);
      if (mounted) setState(() => _phoneSongs = songs);
    } catch (_) {}
  }

  void _onSearchChanged(String val) {
    setState(() => _query = val);
    _debounceTimer?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _search(val.trim());
    });
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final res = await ApiClient.instance.getDaemon(
        '/api/v1/music/search?q=${Uri.encodeComponent(q)}',
      );
      if (res is List && mounted) {
        setState(() {
          _results = res
              .whereType<Map>()
              .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          _isSearching = false;
        });
      } else if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Search failed. Is the host daemon running?';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _download(MusicTrack track) async {
    setState(() => _downloading.add(track.id));
    try {
      await MusicRepository.instance.download(track);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading "${track.title}" to server library...'),
            backgroundColor: EverforestColors.bg1,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloading.remove(track.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: EverforestColors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadOffline(MusicTrack track) async {
    setState(() => _offlineDownloading.add(track.id));
    try {
      await MusicRepository.instance.downloadOffline(track);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${track.title}" for offline playback'),
            backgroundColor: EverforestColors.bg1,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offline download failed: $e'),
            backgroundColor: EverforestColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _offlineDownloading.remove(track.id));
      }
    }
  }

  String _streamUrlFor(String trackId) {
    return '${ApiClient.instance.daemonUrl}/api/v1/music/stream/?id=$trackId';
  }

  void _playTrackList(List<MusicTrack> list, int startIndex) {
    if (!_canPlay) {
      _webPlaybackNotice();
      return;
    }
    final queue = list
        .map((t) => PlaybackItem(
              id: t.id,
              url: _streamUrlFor(t.id),
              title: t.title,
              artist: t.artist,
              thumbnail: t.thumbnail,
              album: t.album,
            ))
        .toList();
    _pc.playQueue(queue, startIndex: startIndex);
  }

  void _webPlaybackNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Music playback is available in the LifeOS Android and Windows native apps.',
        ),
        backgroundColor: EverforestColors.bg1,
      ),
    );
  }

  void _openNowPlaying() {
    if (!_canPlay || _pc.player == null) {
      _webPlaybackNotice();
      return;
    }
    final curTrack = MusicRepository.instance.tracks.value.firstWhere(
      (t) => t.id == _currentTrackId,
      orElse: () => MusicTrack(
        id: _currentTrackId,
        title: _currentTitle,
        artist: _currentArtist,
        album: _currentAlbum,
        thumbnail: _currentThumbnail,
        duration: 0,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PowerampNowPlayingSheet(
        player: _pc.player!,
        title: _currentTitle,
        artist: _currentArtist,
        album: _currentAlbum,
        trackId: _currentTrackId,
        streamUrl: _currentStreamUrl,
        thumbnailUrl: _currentThumbnail,
        isDownloaded: MusicRepository.instance.tracks.value
            .any((t) => t.id == _currentTrackId),
        isOfflineLocal: MusicRepository.instance.isOffline(_currentTrackId),
        queue: _pc.queue,
        currentIndex: _pc.currentIndex,
        onNext: _pc.next,
        onPrev: _pc.previous,
        onDownload: () => _download(curTrack),
        onDownloadOffline: () => _downloadOffline(curTrack),
        onDelete: () => _confirmDeleteTrack(curTrack),
        onOpenQueue: _openQueueSheet,
        onPlayIndex: _pc.playIndex,
        onRemove: _pc.removeAt,
        onClearQueue: _pc.clearQueue,
        onReorder: _pc.reorderQueue,
        repeat: _pc.repeat,
        shuffle: _pc.shuffle,
        onRepeatChanged: (mode) => _pc.setRepeat(mode),
        onShuffleChanged: (mode) => _pc.setShuffle(mode),
      ),
    );
  }

  void _openQueueSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PowerampQueueSheet(
        queue: _pc.queue,
        currentIndex: _pc.currentIndex,
        onPlayIndex: _pc.playIndex,
        onRemove: _pc.removeAt,
        onClear: _pc.clearQueue,
        onReorder: _pc.reorderQueue,
      ),
    );
  }

  void _openLyrics() {
    if (!_canPlay || _pc.player == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: EverforestColors.bg0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
            Expanded(
              child: LyricsSyncViewer(
                title: _currentTitle,
                artist: _currentArtist,
                player: _pc.player!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOffline(OfflineMusicTrack o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Row(
          children: [
            Icon(Icons.phonelink_erase_rounded,
                color: EverforestColors.yellow, size: 24),
            SizedBox(width: 8),
            Text('Remove from Device',
                style: TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Remove "${o.title}" from this device? The song stays in your server library.',
          style: const TextStyle(color: EverforestColors.grey, fontSize: 14),
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
              side: const BorderSide(color: EverforestColors.red, width: 1),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await MusicRepository.instance.deleteOffline(o.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${o.title}" from this device'),
                    backgroundColor: EverforestColors.bg1,
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTrack(MusicTrack t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded,
                color: EverforestColors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Song',
                style: TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Delete "${t.title}" from your downloaded library and disk?',
          style: const TextStyle(color: EverforestColors.grey, fontSize: 14),
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
              side: const BorderSide(color: EverforestColors.red, width: 1),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await MusicRepository.instance.deleteTrack(t.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Deleted "${t.title}" from library'
                        : 'Could not delete "${t.title}"'),
                    backgroundColor:
                        ok ? EverforestColors.bg1 : EverforestColors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addToPlaylist(MusicTrack track) {
    AddToPlaylistSheet.show(context, track);
  }

  // Memoized genre groups for library tracks
  List<MusicTrack>? _lastGroupedTracks;
  Map<String, List<MusicTrack>>? _cachedGenreGroups;

  bool _areTrackListsIdentical(List<MusicTrack> a, List<MusicTrack>? b) {
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i]) && a[i] != b[i]) return false;
    }
    return true;
  }

  Map<String, List<MusicTrack>> _groupTracksByGenre(List<MusicTrack> tracks) {
    if (_cachedGenreGroups != null &&
        _areTrackListsIdentical(tracks, _lastGroupedTracks)) {
      return _cachedGenreGroups!;
    }

    final Map<String, List<MusicTrack>> genreMap = {
      '🏛️ Greek / Ελληνικά': [],
      '🎸 Rock & Metal': [],
      '✨ Pop & Chart Hits': [],
      '🎤 Hip-Hop & Rap': [],
      '⚡ Electronic & Club': [],
      '🌙 Acoustic & Ballads': [],
      '☕ Chill & Relax': [],
    };

    for (final t in tracks) {
      final genre = MusicDashboardWidget.classifyTrackGenre(t);
      genreMap[genre]?.add(t);
    }

    genreMap.removeWhere((_, list) => list.isEmpty);
    _lastGroupedTracks = List<MusicTrack>.unmodifiable(tracks);
    _cachedGenreGroups = genreMap;
    return genreMap;
  }

  Map<String, List<MusicTrack>> _groupTracksByArtist(List<MusicTrack> tracks) {
    final Map<String, List<MusicTrack>> artistMap = {};
    for (final t in tracks) {
      final key = t.artist.trim().isNotEmpty ? t.artist.trim() : 'Unknown Artist';
      artistMap.putIfAbsent(key, () => []).add(t);
    }
    return artistMap;
  }

  Map<String, ({String desc, IconData icon, Color color, List<MusicTrack> list})>
      _generateSmartMixes(List<MusicTrack> tracks) {
    final quick = tracks.where((t) => t.duration > 0 && t.duration <= 210).toList();
    final deep = tracks.where((t) => t.duration > 300).toList();
    final shuffled = List<MusicTrack>.from(tracks)..shuffle();
    final recent = tracks.reversed.take(30).toList();

    return {
      '⚡ Quick Hits': (
        desc: 'Upbeat tracks under 3.5 minutes',
        icon: Icons.bolt_rounded,
        color: EverforestColors.yellow,
        list: quick,
      ),
      '🧘 Deep Sessions': (
        desc: 'Extended tracks & deep sessions',
        icon: Icons.headphones_rounded,
        color: EverforestColors.purple,
        list: deep,
      ),
      '🎲 Discovery Shuffle': (
        desc: 'Dynamic random library mix',
        icon: Icons.shuffle_rounded,
        color: EverforestColors.blue,
        list: shuffled,
      ),
      '📥 Recent Downloads': (
        desc: 'Newest additions to your vault',
        icon: Icons.history_rounded,
        color: EverforestColors.green,
        list: recent,
      ),
    };
  }

  Widget _buildLibraryTabs(
      int trackCount, int artistCount, int genreCount, int mixCount) {
    final offlineCount =
        MusicRepository.instance.offlineTracks.value.length;
    final likedCount = MusicRepository.instance.likedTracks.value.length;
    final playlistCount = MusicRepository.instance.playlists.value.length;

    final tabs = [
      ('All Songs ($trackCount)', Icons.audiotrack_rounded, 0),
      ('Liked ($likedCount)', Icons.favorite_rounded, 1),
      ('Playlists ($playlistCount)', Icons.queue_music_rounded, 2),
      ('Artists ($artistCount)', Icons.person_rounded, 3),
      ('Genres & Styles ($genreCount)', Icons.category_rounded, 4),
      ('Smart Mixes ($mixCount)', Icons.auto_awesome_rounded, 5),
      ('Offline ($offlineCount)', Icons.download_for_offline_rounded, 6),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _libraryTab == t.$3;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(t.$2,
                  size: 16,
                  color: isSelected
                      ? EverforestColors.bg0
                      : (t.$3 == 1
                          ? EverforestColors.red
                          : EverforestColors.grey)),
              label: Text(t.$1),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _libraryTab = t.$3;
                  _selectedArtist = null;
                  _selectedGenre = null;
                });
              },
              selectedColor: EverforestColors.green,
              backgroundColor: EverforestColors.bg1,
              labelStyle: TextStyle(
                color: isSelected
                    ? EverforestColors.bg0
                    : EverforestColors.fg,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLibrary() {
    return ValueListenableBuilder<List<MusicTrack>>(
      valueListenable: MusicRepository.instance.tracks,
      builder: (context, tracks, _) {
        final downloaded = tracks
            .where((t) => t.album.isNotEmpty || t.duration > 0)
            .toList();
        final list = downloaded.isNotEmpty ? downloaded : tracks;

        final artistGroups = _groupTracksByArtist(list);
        final genreGroups = _groupTracksByGenre(list);
        final smartMixes = _generateSmartMixes(list);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.library_music_rounded,
                            color: EverforestColors.green, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'Music Vault',
                          style: TextStyle(
                            color: EverforestColors.fg,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.insights_rounded,
                              color: EverforestColors.purple, size: 22),
                          tooltip: 'Listening Analytics',
                          onPressed: () => MusicStatsSheet.show(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download_rounded,
                              color: EverforestColors.aqua, size: 22),
                          tooltip: 'Download Manager',
                          onPressed: () => DownloadQueueSheet.show(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: EverforestColors.grey, size: 20),
                          tooltip: 'Refresh Library',
                          onPressed: () =>
                              MusicRepository.instance.refresh(),
                        ),
                      ],
                    ),
                  ),
                  _buildLibraryTabs(list.length, artistGroups.length,
                      genreGroups.length, smartMixes.length),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_libraryTab == 0) ...[
              SliverToBoxAdapter(
                child: AllTracksFilterBar(
                  controller: _localFilterCtrl,
                  sortOption: _trackSortOption,
                  onQueryChanged: (q) => setState(() => _localTrackFilter = q),
                  onSortOptionChanged: (opt) =>
                      setState(() => _trackSortOption = opt),
                  totalCount: list.length,
                  filteredCount: filterAndSortTracks(list,
                          query: _localTrackFilter,
                          sortOption: _trackSortOption)
                      .length,
                  onClearQuery: () {
                    _localFilterCtrl.clear();
                    setState(() => _localTrackFilter = '');
                  },
                ),
              ),
              AllTracksSliver(
                tracks: filterAndSortTracks(list,
                    query: _localTrackFilter, sortOption: _trackSortOption),
                offlineDownloading: _offlineDownloading,
                canPlay: _canPlay,
                onDownloadOffline: _downloadOffline,
                onDeleteTrack: _confirmDeleteTrack,
                onPlay: _playTrackList,
                onWebNotice: _webPlaybackNotice,
                onAddToPlaylist: _addToPlaylist,
                emptyMessage: _localTrackFilter.trim().isNotEmpty
                    ? 'No tracks match "$_localTrackFilter".\nTry clearing or adjusting your search.'
                    : null,
              ),
            ]
            else if (_libraryTab == 1)
              LikedSongsSliver(
                canPlay: _canPlay,
                offlineDownloading: _offlineDownloading,
                onDownloadOffline: _downloadOffline,
                onDeleteTrack: _confirmDeleteTrack,
                onPlayTrackList: _playTrackList,
                onWebNotice: _webPlaybackNotice,
                onAddToPlaylist: _addToPlaylist,
              )
            else if (_libraryTab == 2)
              PlaylistsTabSliver(
                canPlay: _canPlay,
                playbackController: _pc,
                onWebNotice: _webPlaybackNotice,
                streamUrlFor: _streamUrlFor,
              )
            else if (_libraryTab == 3)
              ArtistsSliver(
                artistGroups: artistGroups,
                selectedArtist: _selectedArtist,
                canPlay: _canPlay,
                offlineDownloading: _offlineDownloading,
                onSelectArtist: (artist) =>
                    setState(() => _selectedArtist = artist),
                onClearArtist: () =>
                    setState(() => _selectedArtist = null),
                onPlayTrackList: _playTrackList,
                onDownloadOffline: _downloadOffline,
                onDeleteTrack: _confirmDeleteTrack,
                onWebNotice: _webPlaybackNotice,
              )
            else if (_libraryTab == 4)
              GenresSliver(
                genreGroups: genreGroups,
                selectedGenre: _selectedGenre,
                canPlay: _canPlay,
                offlineDownloading: _offlineDownloading,
                onSelectGenre: (genre) =>
                    setState(() => _selectedGenre = genre),
                onClearGenre: () =>
                    setState(() => _selectedGenre = null),
                onPlayTrackList: _playTrackList,
                onDownloadOffline: _downloadOffline,
                onDeleteTrack: _confirmDeleteTrack,
                onWebNotice: _webPlaybackNotice,
              )
            else if (_libraryTab == 5)
              SmartMixesSliver(
                smartMixes: smartMixes,
                canPlay: _canPlay,
                onPlayTrackList: _playTrackList,
              )
            else
              OfflineTracksSliver(
                currentTrackId: _currentTrackId,
                canPlay: _canPlay,
                playbackController: _pc,
                onDeleteOffline: _confirmDeleteOffline,
                onWebNotice: _webPlaybackNotice,
                streamUrlFor: _streamUrlFor,
              ),
            if (!kIsWeb && Platform.isAndroid && _phoneSongs.isNotEmpty)
              PhoneSongsSliver(
                phoneSongs: _phoneSongs,
                playbackController: _pc,
              ),
            SliverToBoxAdapter(
                child: SizedBox(height: _hasActivePlayback ? 130 : 24)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      body: Stack(
        children: [
          Column(
            children: [
              MusicSearchBar(
                controller: _searchCtrl,
                isSearching: _isSearching,
                query: _query,
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  _debounceTimer?.cancel();
                  _search(val.trim());
                },
                onClear: () {
                  _searchCtrl.clear();
                  _onSearchChanged('');
                },
              ),
              Expanded(
                child: searching
                    ? MusicSearchResults(
                        isSearching: _isSearching,
                        searchError: _searchError,
                        query: _query,
                        results: _results,
                        downloading: _downloading,
                        canPlay: _canPlay,
                        playbackController: _pc,
                        onRetry: () => _search(_query.trim()),
                        onDownload: _download,
                        onWebNotice: _webPlaybackNotice,
                        onAddToPlaylist: _addToPlaylist,
                      )
                    : _buildLibrary(),
              ),
            ],
          ),
          if (_hasActivePlayback)
            Positioned(
              left: 14,
              right: 14,
              bottom: 18,
              child: MusicMiniPlayer(
                playbackController: _pc,
                currentTrackId: _currentTrackId,
                currentTitle: _currentTitle,
                currentArtist: _currentArtist,
                currentThumbnail: _currentThumbnail,
                onTap: _openNowPlaying,
                onOpenLyrics: _openLyrics,
              ),
            ),
        ],
      ),
    );
  }
}