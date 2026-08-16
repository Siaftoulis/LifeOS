import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../api_client.dart';
import '../../../../core/telemetry/telemetry_reporter.dart';
import 'lyrics_sync_viewer.dart';
import 'poweramp_now_playing_sheet.dart';
import 'poweramp_queue_sheet.dart';
import '../../../../core/audio_dsp_service.dart';

class MusicDashboardWidget extends StatefulWidget {
  const MusicDashboardWidget({super.key});

  @override
  State<MusicDashboardWidget> createState() => _MusicDashboardWidgetState();
}

class _MusicDashboardWidgetState extends State<MusicDashboardWidget> {
  final AudioPlayer _player = AudioPlayer();
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

  final List<({String id, String url, String title, String artist, String thumbnail, String album})> _queue = [];
  int _queueIndex = -1;
  final Set<String> _downloading = {};
  Timer? _playbackWatchdogTimer;

  // Track playback state intent to prevent aggressive watchdog unpausing
  bool _userWantsPlay = false;
  bool _isLoadingTrack = false;

  // Library Navigation: 0 = All Tracks, 1 = Artists, 2 = Genres & Styles, 3 = Smart Mixes
  int _libraryTab = 0;
  String? _selectedArtist;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    AudioDspService.instance.attachPlayer(_player);
    _loadPhoneSongs();
    MusicRepository.instance.refresh();

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed &&
          _queue.length > 1 &&
          _queueIndex < _queue.length - 1) {
        _playNext();
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready &&
          !state.playing &&
          _userWantsPlay &&
          _isLoadingTrack &&
          _currentTrackId.isNotEmpty &&
          _player.position < const Duration(milliseconds: 500)) {
        _player.play();
      }
      if (state.playing) {
        _isLoadingTrack = false;
        _playbackWatchdogTimer?.cancel();
      }
    });

    MusicRepository.instance.tracks.addListener(_tracksChanged);
  }

  void _tracksChanged() {
    final libraryIds =
        MusicRepository.instance.tracks.value.map((t) => t.id).toSet();
    final done = _downloading.intersection(libraryIds);
    if (done.isNotEmpty) {
      setState(() => _downloading.removeAll(done));
    }
  }

  void _startPlaybackWatchdog() {
    _playbackWatchdogTimer?.cancel();
    int ticks = 0;
    _playbackWatchdogTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      ticks++;
      if (!mounted || !_userWantsPlay || !_isLoadingTrack) {
        timer.cancel();
        return;
      }
      if (!_player.playing) {
        _player.play();
      }
      if ((_player.playing && _player.position > const Duration(milliseconds: 300)) || ticks > 10) {
        _isLoadingTrack = false;
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _userWantsPlay = false;
    _isLoadingTrack = false;
    _playbackWatchdogTimer?.cancel();
    _debounceTimer?.cancel();
    MusicRepository.instance.tracks.removeListener(_tracksChanged);
    _searchCtrl.dispose();
    _player.stop();
    _player.dispose();
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
      _debounceTimer = Timer(const Duration(milliseconds: 500), () => _search(q.trim()));
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
        for (final t in results.take(2)) {
          _precacheTrack(t.id);
        }
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

  void _precacheTrack(String id) {
    if (id.isEmpty) return;
    ApiClient.instance
        .getDaemonSlow('/api/v1/music/resolve?id=$id')
        .catchError((_) => null);
  }

  void _openNowPlaying() {
    if (_currentTrackId.isEmpty && _currentTitle == 'Nothing playing') return;
    final isDownloaded = MusicRepository.instance.tracks.value.any((t) => t.id == _currentTrackId);

    PowerampNowPlayingSheet.show(
      context,
      player: _player,
      title: _currentTitle,
      artist: _currentArtist,
      album: _currentAlbum,
      trackId: _currentTrackId,
      streamUrl: _currentStreamUrl,
      thumbnailUrl: _currentThumbnail,
      onNext: _playNext,
      onPrev: _playPrev,
      onOpenQueue: _openQueue,
      isDownloaded: isDownloaded,
      queue: _queue,
      currentIndex: _queueIndex,
      onPlayIndex: (idx) => _playAt(idx),
      onReorder: (oldIdx, newIdx) {
        setState(() {
          if (oldIdx < newIdx) newIdx -= 1;
          final item = _queue.removeAt(oldIdx);
          _queue.insert(newIdx, item);
          if (_queueIndex == oldIdx) {
            _queueIndex = newIdx;
          } else if (_queueIndex > oldIdx && _queueIndex <= newIdx) {
            _queueIndex -= 1;
          } else if (_queueIndex < oldIdx && _queueIndex >= newIdx) {
            _queueIndex += 1;
          }
        });
      },
      onRemove: (idx) {
        setState(() {
          _queue.removeAt(idx);
          if (_queueIndex == idx) {
            if (_queue.isNotEmpty) {
              _playAt(idx.clamp(0, _queue.length - 1));
            }
          } else if (_queueIndex > idx) {
            _queueIndex -= 1;
          }
        });
      },
      onClearQueue: () {
        setState(() {
          _queue.clear();
          _queueIndex = -1;
        });
      },
      onDownload: () {
        final track = MusicTrack(
          id: _currentTrackId,
          title: _currentTitle,
          artist: _currentArtist,
          album: _currentAlbum,
          thumbnail: _currentThumbnail,
          duration: _player.duration?.inSeconds.toDouble() ?? 0,
        );
        _download(track);
      },
      onDelete: () {
        final match = MusicRepository.instance.tracks.value
            .where((t) => t.id == _currentTrackId)
            .firstOrNull;
        if (match != null) {
          _confirmDeleteTrack(match);
        }
      },
    );
  }

  void _openQueue() {
    PowerampQueueSheet.show(
      context,
      queue: _queue,
      currentIndex: _queueIndex,
      onPlayIndex: (idx) => _playAt(idx),
      onReorder: (oldIdx, newIdx) {
        setState(() {
          if (oldIdx < newIdx) newIdx -= 1;
          final item = _queue.removeAt(oldIdx);
          _queue.insert(newIdx, item);
          if (_queueIndex == oldIdx) {
            _queueIndex = newIdx;
          } else if (_queueIndex > oldIdx && _queueIndex <= newIdx) {
            _queueIndex -= 1;
          } else if (_queueIndex < oldIdx && _queueIndex >= newIdx) {
            _queueIndex += 1;
          }
        });
      },
      onRemove: (idx) {
        setState(() {
          _queue.removeAt(idx);
          if (_queueIndex == idx) {
            if (_queue.isNotEmpty) {
              _playAt(idx.clamp(0, _queue.length - 1));
            }
          } else if (_queueIndex > idx) {
            _queueIndex -= 1;
          }
        });
      },
      onClear: () {
        setState(() {
          _queue.clear();
          _queueIndex = -1;
        });
      },
    );
  }

  void _openLyrics() {
    if (_currentTitle == 'Nothing playing') return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LyricsSyncViewer(
        title: _currentTitle,
        artist: _currentArtist,
        player: _player,
      ),
    );
  }

  Future<void> _playAt(int i) async {
    if (i < 0 || i >= _queue.length) return;
    _userWantsPlay = true;
    _isLoadingTrack = true;
    _queueIndex = i;
    final item = _queue[i];
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

    if (i + 1 < _queue.length) {
      _precacheTrack(_queue[i + 1].id);
    }

    try {
      String playUrl = item.url;
      if (item.url.contains('ytstream') ||
          item.url.contains('/api/v1/music/ytstream/') ||
          (!item.url.startsWith('file:') &&
              !item.url.startsWith('http://') &&
              !item.url.startsWith('https://'))) {
        try {
          final res = await ApiClient.instance
              .getDaemonSlow('/api/v1/music/resolve?id=${item.id}');
          if (res is Map &&
              res['url'] != null &&
              (res['url'] as String).isNotEmpty) {
            playUrl = res['url'] as String;
          }
        } catch (resolveErr) {
          debugPrint('Resolve stream URL fallback: $resolveErr');
        }
      }

      debugPrint('Music player playing url: $playUrl');
      await _player.setUrl(playUrl);
      if (_userWantsPlay) {
        await _player.play();
        _startPlaybackWatchdog();
        // Reapply audiophile EQ and DSP filters to newly loaded audio stream
        Future.delayed(const Duration(milliseconds: 150), () {
          AudioDspService.instance.reapply();
        });
      }
    } catch (e) {
      debugPrint('Music playback failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play "${item.title}"'),
            backgroundColor: EverforestColors.red,
          ),
        );
      }
    }
  }

  Future<void> _playQueueAt(
      List<({String id, String url, String title, String artist, String thumbnail, String album})> items,
      int i) async {
    _queue
      ..clear()
      ..addAll(items);
    await _playAt(i);
  }

  Future<void> _playNext() async {
    if (_queueIndex < _queue.length - 1) await _playAt(_queueIndex + 1);
  }

  Future<void> _playPrev() async {
    if (_queueIndex > 0) await _playAt(_queueIndex - 1);
  }

  void _togglePlayPause() {
    if (_player.playing) {
      _userWantsPlay = false;
      _isLoadingTrack = false;
      _playbackWatchdogTimer?.cancel();
      _player.pause();
    } else {
      _userWantsPlay = true;
      _player.play();
    }
  }

  void _download(MusicTrack t) {
    setState(() => _downloading.add(t.id));
    MusicRepository.instance.download(t);

    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_downloading.contains(t.id)) {
        timer.cancel();
        return;
      }
      MusicRepository.instance.refresh();
      if (timer.tick > 30) {
        timer.cancel();
        if (mounted && _downloading.remove(t.id)) setState(() {});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${t.title}" (+5 stars when done)...'),
        backgroundColor: EverforestColors.bg1,
      ),
    );
  }

  void _confirmDeleteTrack(MusicTrack t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: EverforestColors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Song', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Delete "${t.title}" from your downloaded library and disk?',
          style: const TextStyle(color: EverforestColors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
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
                    content: Text(ok ? 'Deleted "${t.title}" from library' : 'Could not delete "${t.title}"'),
                    backgroundColor: ok ? EverforestColors.bg1 : EverforestColors.red,
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

  // --- Smart Playlists Engine ---
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

      if (greekRegex.hasMatch(t.title) || greekRegex.hasMatch(t.artist) ||
          combined.contains('parios') || combined.contains('mitropanos') ||
          combined.contains('sfakianakis') || combined.contains('remos') ||
          combined.contains('argiros') || combined.contains('vertis') ||
          combined.contains('pantelidis') || combined.contains('papakonstantinou') ||
          combined.contains('laiko') || combined.contains('zeimbekiko')) {
        genreMap['🏛️ Greek / Ελληνικά']!.add(t);
      } else if (combined.contains('rock') || combined.contains('metal') ||
          combined.contains('queen') || combined.contains('metallica') ||
          combined.contains('nirvana') || combined.contains('scorpions') ||
          combined.contains('pink floyd') || combined.contains('guitar') ||
          combined.contains('punk') || combined.contains('linkin park')) {
        genreMap['🎸 Rock & Metal']!.add(t);
      } else if (combined.contains('rap') || combined.contains('hip hop') ||
          combined.contains('hip-hop') || combined.contains('trap') ||
          combined.contains('eminem') || combined.contains('drake') ||
          combined.contains('kanye') || combined.contains('tupac') ||
          combined.contains('snoop') || combined.contains('kendrick') ||
          combined.contains('light') || combined.contains('snik') ||
          combined.contains('toquel') || combined.contains('trannos')) {
        genreMap['🎤 Hip-Hop & Rap']!.add(t);
      } else if (combined.contains('edm') || combined.contains('house') ||
          combined.contains('dance') || combined.contains('techno') ||
          combined.contains('club') || combined.contains('remix') ||
          combined.contains('tiesto') || combined.contains('guetta') ||
          combined.contains('avicii') || combined.contains('calvin') ||
          combined.contains('garrix')) {
        genreMap['⚡ Electronic & Club']!.add(t);
      } else if (combined.contains('acoustic') || combined.contains('ballad') ||
          combined.contains('unplugged') || combined.contains('piano') ||
          combined.contains('slow') || combined.contains('love') ||
          combined.contains('romantic')) {
        genreMap['🌙 Acoustic & Ballads']!.add(t);
      } else if (combined.contains('chill') || combined.contains('lofi') ||
          combined.contains('lo-fi') || combined.contains('ambient') ||
          combined.contains('jazz') || combined.contains('relax') ||
          combined.contains('focus') || combined.contains('blues')) {
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
      final name = t.artist.trim().isNotEmpty ? t.artist.trim() : 'Various Artists';
      artistMap.putIfAbsent(name, () => []).add(t);
    }
    return artistMap;
  }

  Map<String, ({String desc, IconData icon, Color color, List<MusicTrack> list})> _generateSmartMixes(List<MusicTrack> tracks) {
    final quickHits = tracks.where((t) => t.duration > 0 && t.duration <= 240).toList();
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

  String _fmt(double sec) {
    final m = (sec / 60).floor();
    final s = (sec % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
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
              _buildSearchBar(),
              Expanded(
                child: searching ? _buildResults() : _buildLibrary(),
              ),
            ],
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 18,
            child: _buildPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        onSubmitted: (val) {
          _debounceTimer?.cancel();
          _search(val.trim());
        },
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search YouTube Music...',
          hintStyle: const TextStyle(color: EverforestColors.grey),
          prefixIcon: const Icon(Icons.search, color: EverforestColors.green),
          suffixIcon: _isSearching
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
              : _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: EverforestColors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
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

  Widget _buildResults() {
    if (_isSearching) {
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
    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: EverforestColors.red, size: 40),
            const SizedBox(height: 12),
            Text(_searchError!, style: const TextStyle(color: EverforestColors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _search(_query.trim()),
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
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off_rounded, color: EverforestColors.grey, size: 40),
            const SizedBox(height: 12),
            Text('No results found for "$_query"', style: const TextStyle(color: EverforestColors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final t = _results[i];
        final alreadyDownloaded = MusicRepository
            .instance.tracks.value
            .any((track) => track.id == t.id);
        return ListTile(
          leading: _thumbnail(t.thumbnail, 48),
          title: Text(t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${t.artist}${t.duration > 0 ? ' · ${_fmt(t.duration)}' : ''}',
            style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alreadyDownloaded)
                const Icon(Icons.check_circle_rounded, color: EverforestColors.green)
              else if (_downloading.contains(t.id))
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
                  icon: const Icon(Icons.download_rounded, color: EverforestColors.green),
                  onPressed: () => _download(t),
                ),
              IconButton(
                icon: const Icon(Icons.play_circle_fill_rounded,
                    color: EverforestColors.fg, size: 32),
                onPressed: () => _playQueueAt(
                    _results
                        .map((r) => (
                              id: r.id,
                              url:
                                  '${ApiClient.instance.daemonUrl}/api/v1/music/ytstream/stream.m4a?id=${r.id}',
                              title: r.title,
                              artist: r.artist,
                              thumbnail: r.thumbnail,
                              album: r.album,
                            ))
                        .toList(),
                    i),
              ),
            ],
          ),
          onTap: () => _playQueueAt(
              _results
                  .map((r) => (
                        id: r.id,
                        url: '${ApiClient.instance.daemonUrl}/api/v1/music/ytstream/stream.m4a?id=${r.id}',
                        title: r.title,
                        artist: r.artist,
                        thumbnail: r.thumbnail,
                        album: r.album,
                      ))
                  .toList(),
              i),
        );
      },
    );
  }

  Widget _buildLibrary() {
    return ValueListenableBuilder<List<MusicTrack>>(
      valueListenable: MusicRepository.instance.tracks,
      builder: (context, tracks, _) {
        final downloaded =
            tracks.where((t) => t.album.isNotEmpty || t.duration > 0).toList();
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
                  _buildLibraryHeader(list.length, artistGroups.length, genreGroups.length),
                  _buildLibraryTabs(list.length, artistGroups.length, genreGroups.length, smartMixes.length),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_libraryTab == 0)
              _buildAllTracksSliver(list)
            else if (_libraryTab == 1)
              _buildArtistsSliver(artistGroups, list)
            else if (_libraryTab == 2)
              _buildGenresSliver(genreGroups, list)
            else
              _buildSmartMixesSliver(smartMixes, list),

            if (!kIsWeb && Platform.isAndroid && _phoneSongs.isNotEmpty)
              _buildPhoneSongsSliver(),

            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        );
      },
    );
  }

  Widget _buildLibraryHeader(int trackCount, int artistCount, int genreCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          const Icon(Icons.library_music_rounded, color: EverforestColors.green, size: 24),
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
            icon: const Icon(Icons.refresh_rounded, color: EverforestColors.grey, size: 20),
            tooltip: 'Refresh Library',
            onPressed: () => MusicRepository.instance.refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTabs(int trackCount, int artistCount, int genreCount, int mixCount) {
    final tabs = [
      ('All Songs ($trackCount)', Icons.audiotrack_rounded, 0),
      ('Artists ($artistCount)', Icons.person_rounded, 1),
      ('Genres & Styles ($genreCount)', Icons.category_rounded, 2),
      ('Smart Mixes ($mixCount)', Icons.auto_awesome_rounded, 3),
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
              avatar: Icon(t.$2, size: 16, color: isSelected ? EverforestColors.bg0 : EverforestColors.grey),
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
                color: isSelected ? EverforestColors.bg0 : EverforestColors.fg,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Sliver Views for Tabs ---

  Widget _buildAllTracksSliver(List<MusicTrack> list) {
    if (list.isEmpty) {
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
          final t = list[i];
          return _buildTrackTile(t, list, i);
        },
        childCount: list.length,
      ),
    );
  }

  Widget _buildArtistsSliver(Map<String, List<MusicTrack>> artistGroups, List<MusicTrack> allTracks) {
    if (artistGroups.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    if (_selectedArtist != null && artistGroups.containsKey(_selectedArtist)) {
      final artistTracks = artistGroups[_selectedArtist]!;
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: EverforestColors.fg),
                    onPressed: () => setState(() => _selectedArtist = null),
                  ),
                  Text(
                    _selectedArtist!,
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _playTrackList(artistTracks, 0),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EverforestColors.green,
                      foregroundColor: EverforestColors.bg0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildTrackTile(artistTracks[i], artistTracks, i),
              childCount: artistTracks.length,
            ),
          ),
        ],
      );
    }

    final artists = artistGroups.keys.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final artist = artists[i];
          final tracks = artistGroups[artist]!;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: EverforestColors.bg2,
              child: const Icon(Icons.person_rounded, color: EverforestColors.aqua),
            ),
            title: Text(
              artist,
              style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              '${tracks.length} song${tracks.length > 1 ? 's' : ''}',
              style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, color: EverforestColors.green, size: 34),
              tooltip: 'Play $artist',
              onPressed: () => _playTrackList(tracks, 0),
            ),
            onTap: () => setState(() => _selectedArtist = artist),
          );
        },
        childCount: artists.length,
      ),
    );
  }

  Widget _buildGenresSliver(Map<String, List<MusicTrack>> genreGroups, List<MusicTrack> allTracks) {
    if (genreGroups.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    if (_selectedGenre != null && genreGroups.containsKey(_selectedGenre)) {
      final genreTracks = genreGroups[_selectedGenre]!;
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: EverforestColors.fg),
                    onPressed: () => setState(() => _selectedGenre = null),
                  ),
                  Text(
                    _selectedGenre!,
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _playTrackList(genreTracks, 0),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Play Genre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EverforestColors.green,
                      foregroundColor: EverforestColors.bg0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildTrackTile(genreTracks[i], genreTracks, i),
              childCount: genreTracks.length,
            ),
          ),
        ],
      );
    }

    final genres = genreGroups.keys.toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisExtent: 100,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final genre = genres[i];
            final tracks = genreGroups[genre]!;
            return InkWell(
              onTap: () => setState(() => _selectedGenre = genre),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: EverforestColors.bg1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            genre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tracks.length} tracks',
                            style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded, color: EverforestColors.green, size: 34),
                      tooltip: 'Play Mix',
                      onPressed: () => _playTrackList(tracks, 0),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: genres.length,
        ),
      ),
    );
  }

  Widget _buildSmartMixesSliver(
      Map<String, ({String desc, IconData icon, Color color, List<MusicTrack> list})> smartMixes,
      List<MusicTrack> allTracks) {
    final keys = smartMixes.keys.toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisExtent: 110,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final key = keys[i];
            final mix = smartMixes[key]!;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: EverforestColors.bg1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mix.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: mix.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(mix.icon, color: mix.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EverforestColors.fg,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${mix.list.length} tracks · ${mix.desc}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: EverforestColors.grey, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_circle_fill_rounded, color: mix.color, size: 34),
                    tooltip: 'Play Mix',
                    onPressed: () => _playTrackList(mix.list, 0),
                  ),
                ],
              ),
            );
          },
          childCount: keys.length,
        ),
      ),
    );
  }

  Widget _buildPhoneSongsSliver() {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _sectionTitle('On This Phone'),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final s = _phoneSongs[i];
              return ListTile(
                leading: const Icon(Icons.music_note_rounded, color: EverforestColors.blue, size: 40),
                title: Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${s.artist} · ${_fmt((s.duration ?? 0).toDouble())}',
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: EverforestColors.fg, size: 32),
                  onPressed: () => _playQueueAt(
                      _phoneSongs
                          .map((x) => (
                                id: x.uri ?? x.id.toString(),
                                url: x.uri ?? '',
                                title: x.title,
                                artist: x.artist ?? '',
                                thumbnail: '',
                                album: x.album ?? '',
                              ))
                          .toList(),
                      i),
                ),
                onTap: () => _playQueueAt(
                    _phoneSongs
                        .map((x) => (
                              id: x.uri ?? x.id.toString(),
                              url: x.uri ?? '',
                              title: x.title,
                              artist: x.artist ?? '',
                              thumbnail: '',
                              album: x.album ?? '',
                            ))
                        .toList(),
                    i),
              );
            },
            childCount: _phoneSongs.length,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(MusicTrack t, List<MusicTrack> currentList, int index) {
    return ListTile(
      leading: _thumbnail(t.thumbnail, 48),
      title: Text(t.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${t.artist}${t.album.isNotEmpty ? ' · ${t.album}' : ''}${t.duration > 0 ? ' · ${_fmt(t.duration)}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: EverforestColors.grey, size: 20),
            tooltip: 'Delete Song',
            onPressed: () => _confirmDeleteTrack(t),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill_rounded, color: EverforestColors.fg, size: 32),
            onPressed: () => _playTrackList(currentList, index),
          ),
        ],
      ),
      onTap: () => _playTrackList(currentList, index),
    );
  }

  void _playTrackList(List<MusicTrack> list, int index) {
    _playQueueAt(
      list
          .map((x) => (
                id: x.id,
                url: '${ApiClient.instance.daemonUrl}/api/v1/music/stream/stream.m4a?id=${x.id}',
                title: x.title,
                artist: x.artist,
                thumbnail: x.thumbnail,
                album: x.album,
              ))
          .toList(),
      index,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: EverforestColors.fg,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _thumbnail(String url, double size) {
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note_rounded, color: EverforestColors.blue),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: EverforestColors.bg1,
                child: const Icon(Icons.music_note_rounded,
                    color: EverforestColors.blue),
              )),
    );
  }

  /// Poweramp v3 Mini-Player Dock
  Widget _buildPlayer() {
    return GestureDetector(
      onTap: _openNowPlaying,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -150) {
          _openNowPlaying();
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            _playNext();
          } else if (details.primaryVelocity! > 200) {
            _playPrev();
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: EverforestColors.bg1.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                )
              ],
            ),
            child: StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing = state?.playing ?? false;
                final loading = state?.processingState == ProcessingState.loading ||
                    state?.processingState == ProcessingState.buffering;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Micro-Progress Bar
                    StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = _player.duration ?? Duration.zero;
                        final progress = (dur.inMilliseconds > 0)
                            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 2.5,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(EverforestColors.green),
                          ),
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          // Track Artwork with Glow
                          Hero(
                            tag: 'now_playing_artwork_${_currentTrackId.isEmpty ? "empty" : _currentTrackId}',
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: EverforestColors.green.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: _currentThumbnail.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _currentThumbnail,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildMiniPlaceholder(),
                                      ),
                                    )
                                  : _buildMiniPlaceholder(),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title and Artist with Audiophile Quality Tag
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: EverforestColors.fg,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: EverforestColors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DSP 32-BIT',
                                        style: TextStyle(
                                          color: EverforestColors.green,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _currentArtist.isNotEmpty ? _currentArtist : 'LifeOS Audio',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: EverforestColors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Lyrics Quick Action
                          IconButton(
                            icon: const Icon(Icons.lyrics_rounded),
                            color: EverforestColors.grey,
                            iconSize: 22,
                            tooltip: 'Live Lyrics',
                            onPressed: _openLyrics,
                          ),

                          // Play / Pause Button with Reactive Feedback
                          IconButton(
                            iconSize: 38,
                            tooltip: playing ? 'Pause' : 'Play',
                            icon: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: EverforestColors.green,
                                    ),
                                  )
                                : Icon(
                                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: EverforestColors.fg,
                                    size: 32,
                                  ),
                            onPressed: loading ? null : _togglePlayPause,
                          ),

                          // Skip Next Button
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: EverforestColors.fg,
                            iconSize: 28,
                            tooltip: 'Next Track',
                            onPressed: _playNext,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        color: EverforestColors.bg2,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Icon(
        Icons.graphic_eq_rounded,
        color: EverforestColors.green,
        size: 26,
      ),
    );
  }
}