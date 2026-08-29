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
import 'components/music_mini_player.dart';
import 'components/music_search_bar.dart';
import 'lyrics_sync_viewer.dart';
import 'poweramp_now_playing_sheet.dart';
import 'poweramp_queue_sheet.dart';
import 'tabs/all_tracks_sliver.dart';
import 'tabs/artists_and_genres_slivers.dart';
import 'tabs/offline_tracks_sliver.dart';
import 'tabs/smart_mixes_sliver.dart';

export 'components/music_mini_player.dart';
export 'components/music_search_bar.dart';
export 'tabs/all_tracks_sliver.dart';
export 'tabs/artists_and_genres_slivers.dart';
export 'tabs/offline_tracks_sliver.dart';
export 'tabs/smart_mixes_sliver.dart';

class MusicDashboardWidget extends StatefulWidget {
  const MusicDashboardWidget({super.key});

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

  String _currentTitle = 'Nothing playing';
  String _currentArtist = '';
  String _currentAlbum = '';
  String _currentTrackId = '';
  String _currentStreamUrl = '';
  String _currentThumbnail = '';

  final Set<String> _downloading = {};
  final Set<String> _offlineDownloading = {};

  bool get _canPlay => !kIsWeb;
  PlaybackController get _pc => PlaybackController.instance;

  int _libraryTab = 0;
  String? _selectedArtist;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    unawaited(AudioDspService.instance.init());
    unawaited(_pc.ensureInitialized());
    _loadPhoneSongs();
    MusicRepository.instance.refresh();
    MusicRepository.instance.loadOffline();
    MusicRepository.instance.tracks.addListener(_tracksChanged);
    _pc.addListener(_playbackChanged);
    _playbackChanged();
  }

  void _playbackChanged() {
    final item = _pc.currentItem;
    if (!mounted || item == null || item.id == _currentTrackId) return;
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
    final libraryIds =
        MusicRepository.instance.tracks.value.map((t) => t.id).toSet();
    final done = _downloading.intersection(libraryIds);
    if (done.isNotEmpty) {
      setState(() => _downloading.removeAll(done));
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    MusicRepository.instance.tracks.removeListener(_tracksChanged);
    _pc.removeListener(_playbackChanged);
    _searchCtrl.dispose();
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

  void _onSearchChanged(String q) {
    _debounceTimer?.cancel();
    setState(() {
      _query = q;
      if (q.trim().isEmpty) {
        _results = [];
        _isSearching = false;
        _searchError = null;
      }
    });
    if (q.trim().isNotEmpty) {
      _debounceTimer = Timer(
          const Duration(milliseconds: 500), () => _search(q.trim()));
    }
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final results = await MusicRepository.instance.search(q);
      if (mounted && _query.trim() == q) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && _query.trim() == q) {
        setState(() {
          _isSearching = false;
          _searchError = 'Could not fetch search results. Please try again.';
        });
      }
    }
  }

  void _openNowPlaying() {
    if (!_canPlay) {
      _webPlaybackNotice();
      return;
    }
    final player = _pc.player;
    if (player == null) return;
    if (_currentTrackId.isEmpty && _currentTitle == 'Nothing playing') return;
    final isDownloaded = MusicRepository.instance.tracks.value
        .any((t) => t.id == _currentTrackId);
    final isOfflineLocal =
        MusicRepository.instance.isOffline(_currentTrackId);

    PowerampNowPlayingSheet.show(
      context,
      player: player,
      title: _currentTitle,
      artist: _currentArtist,
      album: _currentAlbum,
      trackId: _currentTrackId,
      streamUrl: _currentStreamUrl,
      thumbnailUrl: _currentThumbnail,
      onNext: _pc.next,
      onPrev: _pc.previous,
      onOpenQueue: _openQueue,
      isDownloaded: isDownloaded,
      isOfflineLocal: isOfflineLocal,
      onDownloadOffline: () {
        final track = MusicTrack(
          id: _currentTrackId,
          title: _currentTitle,
          artist: _currentArtist,
          album: _currentAlbum,
          thumbnail: _currentThumbnail,
          duration: player.duration?.inSeconds.toDouble() ?? 0,
        );
        _downloadOffline(track);
      },
      queue: _pc.queue,
      currentIndex: _pc.currentIndex,
      repeat: _pc.repeat,
      shuffle: _pc.shuffle,
      onRepeatChanged: (mode) => _pc.setRepeat(mode),
      onShuffleChanged: (enabled) {
        if (enabled != _pc.shuffle) _pc.toggleShuffle();
      },
      onPlayIndex: (idx) => _pc.playAt(idx),
      onReorder: (oldIdx, newIdx) => _pc.reorder(oldIdx, newIdx),
      onRemove: (idx) {
        _pc.queue.removeAt(idx);
        setState(() {});
      },
      onClearQueue: () {
        _pc.queue.clear();
        setState(() {});
      },
    );
  }

  void _openQueue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PowerampQueueSheet(
        queue: _pc.queue,
        currentIndex: _pc.currentIndex,
        onPlayIndex: (idx) {
          Navigator.pop(context);
          _pc.playAt(idx);
        },
        onReorder: (oldIdx, newIdx) => _pc.reorder(oldIdx, newIdx),
        onRemove: (idx) {
          _pc.queue.removeAt(idx);
          setState(() {});
        },
        onClear: () {
          _pc.queue.clear();
          setState(() {});
        },
      ),
    );
  }

  void _openLyrics() {
    final player = _pc.player;
    if (player == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LyricsSyncViewer(
        title: _currentTitle,
        artist: _currentArtist,
        player: player,
      ),
    );
  }

  void _webPlaybackNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.phonelink_lock_rounded,
                color: EverforestColors.orange, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Music playback, offline caching & DSP equalizer are native-app only. '
                'Open LifeOS on Windows or Android to listen.',
                style: TextStyle(color: EverforestColors.fg),
              ),
            ),
          ],
        ),
        backgroundColor: EverforestColors.bg1,
        duration: Duration(seconds: 4),
      ),
    );
  }

  String _streamUrlFor(String id) {
    final base = ApiClient.instance.baseUrl;
    return '$base/api/v1/music/stream?id=$id';
  }

  Future<void> _playTrackList(List<MusicTrack> list, int index) async {
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
    await _pc.playQueue(queue, startIndex: index);
  }

  void _download(MusicTrack t) {
    setState(() => _downloading.add(t.id));
    MusicRepository.instance.download(t);
    TelemetryReporter.instance
        .track('music', 'track_download_queued', {'track_id': t.id});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${t.title}" to server library...'),
        backgroundColor: EverforestColors.bg1,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadOffline(MusicTrack t) async {
    setState(() => _offlineDownloading.add(t.id));
    try {
      final ok = await MusicRepository.instance.downloadOffline(t);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Saved "${t.title}" to this device for offline play'
              : 'Could not download "${t.title}" for offline play'),
          backgroundColor:
              ok ? EverforestColors.bg1 : EverforestColors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _offlineDownloading.remove(t.id));
    }
  }

  void _confirmDeleteOffline(OfflineMusicTrack o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded,
                color: EverforestColors.red, size: 24),
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

  Map<String, List<MusicTrack>> _groupTracksByGenre(List<MusicTrack> tracks) {
    final Map<String, List<MusicTrack>> genreMap = {
      '🏛️ Greek / Ελληνικά': [],
      '🎸 Rock & Metal': [],
      '✨ Pop & Chart Hits': [],
      '🎤 Hip-Hop & Rap': [],
      '⚡ Electronic & Club': [],
      '🌙 Acoustic & Ballads': [],
      '☕ Chill & Relax': [],
    };

    final greekRegex = RegExp(r'[\u0370-\u03FF]');

    for (final t in tracks) {
      final combined = '${t.title} ${t.artist} ${t.album}'.toLowerCase();

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
        genreMap['🏛️ Greek / Ελληνικά']!.add(t);
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
        genreMap['🎸 Rock & Metal']!.add(t);
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
        genreMap['🎤 Hip-Hop & Rap']!.add(t);
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
        genreMap['⚡ Electronic & Club']!.add(t);
      } else if (combined.contains('acoustic') ||
          combined.contains('ballad') ||
          combined.contains('unplugged') ||
          combined.contains('piano') ||
          combined.contains('slow') ||
          combined.contains('love') ||
          combined.contains('romantic')) {
        genreMap['🌙 Acoustic & Ballads']!.add(t);
      } else if (combined.contains('chill') ||
          combined.contains('lofi') ||
          combined.contains('lo-fi') ||
          combined.contains('ambient') ||
          combined.contains('jazz') ||
          combined.contains('relax') ||
          combined.contains('focus') ||
          combined.contains('blues')) {
        genreMap['☕ Chill & Relax']!.add(t);
      } else {
        genreMap['✨ Pop & Chart Hits']!.add(t);
      }
    }

    genreMap.removeWhere((_, list) => list.isEmpty);
    return genreMap;
  }

  Map<String, List<MusicTrack>> _groupTracksByArtist(List<MusicTrack> tracks) {
    final Map<String, List<MusicTrack>> artistMap = {};
    for (final t in tracks) {
      final name =
          t.artist.trim().isNotEmpty ? t.artist.trim() : 'Various Artists';
      artistMap.putIfAbsent(name, () => []).add(t);
    }
    return artistMap;
  }

  Map<String, SmartMixEntry> _generateSmartMixes(List<MusicTrack> tracks) {
    final quickHits =
        tracks.where((t) => t.duration > 0 && t.duration <= 240).toList();
    final deepEpics = tracks.where((t) => t.duration >= 270).toList();
    final shuffled = List<MusicTrack>.from(tracks)..shuffle();
    final recent = List<MusicTrack>.from(tracks.reversed);

    return {
      '⚡ Quick Hits (<4 min)': (
        desc: 'Fast-paced upbeat energy',
        icon: Icons.bolt_rounded,
        color: EverforestColors.orange,
        list: quickHits.isNotEmpty ? quickHits : tracks.take(10).toList(),
      ),
      '🌌 Deep Sessions (>4.5 min)': (
        desc: 'Extended grooves & atmospheric tracks',
        icon: Icons.all_inclusive_rounded,
        color: EverforestColors.purple,
        list: deepEpics.isNotEmpty ? deepEpics : tracks.toList(),
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
    final tabs = [
      ('All Songs ($trackCount)', Icons.audiotrack_rounded, 0),
      ('Artists ($artistCount)', Icons.person_rounded, 1),
      ('Genres & Styles ($genreCount)', Icons.category_rounded, 2),
      ('Smart Mixes ($mixCount)', Icons.auto_awesome_rounded, 3),
      ('Offline ($offlineCount)', Icons.download_for_offline_rounded, 4),
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
                      : EverforestColors.grey),
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
            if (_libraryTab == 0)
              AllTracksSliver(
                tracks: list,
                offlineDownloading: _offlineDownloading,
                canPlay: _canPlay,
                onDownloadOffline: _downloadOffline,
                onDeleteTrack: _confirmDeleteTrack,
                onPlay: _playTrackList,
                onWebNotice: _webPlaybackNotice,
              )
            else if (_libraryTab == 1)
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
            else if (_libraryTab == 2)
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
            else if (_libraryTab == 3)
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
                child: SizedBox(height: _canPlay ? 130 : 24)),
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
                      )
                    : _buildLibrary(),
              ),
            ],
          ),
          if (_canPlay)
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