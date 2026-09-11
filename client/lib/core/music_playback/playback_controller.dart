import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer, ProcessingState;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_client.dart';
import '../domain_repositories.dart';
import 'playback_engine.dart';
import 'playback_models.dart';

/// Central playback state coordinator managing playlist queues, smart pre-caching,
/// telemetry recording, and studio-grade Dual-Player DJ Crossfade / Gapless transitions.
class PlaybackController extends ChangeNotifier {
  PlaybackController._() {
    _loadPreferences();
  }

  static final PlaybackController instance = PlaybackController._();

  PlaybackQueueState _state = const PlaybackQueueState();
  PlaybackQueueState get state => _state;

  PlaybackItem? get currentItem => _state.current;
  List<PlaybackItem> get queue => _state.queue;
  int get currentIndex => _state.currentIndex;
  PlaybackRepeat get repeat => _state.repeat;
  bool get shuffle => _state.shuffle;

  bool _infiniteRadio = true;
  bool get infiniteRadio => _infiniteRadio;
  int _lookaheadWindow = 3;
  int get lookaheadWindow => _lookaheadWindow;

  // DJ Crossfade and Gapless Transition settings
  bool _crossfadeEnabled = true;
  bool get crossfadeEnabled => _crossfadeEnabled;
  int _crossfadeDuration = 4; // seconds (0 = 0ms gapless, 2..12 = DJ mix)
  int get crossfadeDuration => _crossfadeDuration;
  bool _djTransitions = true; // smooth DJ blend on manual skip
  bool get djTransitions => _djTransitions;
  bool get isCrossfading => playbackEngine.isCrossfading;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _infiniteRadio = prefs.getBool('music_infinite_radio') ?? true;
      _lookaheadWindow = prefs.getInt('music_lookahead_window') ?? 3;
      _crossfadeEnabled = prefs.getBool('music_crossfade_enabled') ?? true;
      _crossfadeDuration = prefs.getInt('music_crossfade_duration') ?? 4;
      _djTransitions = prefs.getBool('music_dj_transitions') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  void setInfiniteRadio(bool enabled) {
    _infiniteRadio = enabled;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setBool('music_infinite_radio', enabled))
        .catchError((_) => false);
  }

  void toggleInfiniteRadio() {
    setInfiniteRadio(!_infiniteRadio);
  }

  void setLookaheadWindow(int count) {
    _lookaheadWindow = count.clamp(1, 5);
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setInt('music_lookahead_window', _lookaheadWindow))
        .catchError((_) => false);
  }

  void setCrossfadeEnabled(bool enabled) {
    _crossfadeEnabled = enabled;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setBool('music_crossfade_enabled', enabled))
        .catchError((_) => false);
  }

  void toggleCrossfade() {
    setCrossfadeEnabled(!_crossfadeEnabled);
  }

  void setCrossfadeDuration(int seconds) {
    _crossfadeDuration = seconds.clamp(0, 15);
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setInt('music_crossfade_duration', _crossfadeDuration))
        .catchError((_) => false);
  }

  void setDjTransitions(bool enabled) {
    _djTransitions = enabled;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setBool('music_dj_transitions', enabled))
        .catchError((_) => false);
  }

  /// True only on platforms with playback support.
  bool get isAvailable => playbackEngine.isAvailable;

  /// The underlying active just_audio player.
  AudioPlayer? get player => playbackEngine.player;

  bool _userWantsPlay = false;
  bool _isLoadingTrack = false;
  Timer? _watchdogTimer;

  StreamSubscription<dynamic>? _processingSub;
  StreamSubscription<dynamic>? _playerStateSub;
  StreamSubscription<dynamic>? _positionSub;
  final Set<String> _precachedTrackIds = {};
  bool _hasPrecachedMidpoint = false;
  bool _hasPrecachedEightyPercent = false;
  bool _hasPreloadedStandby = false;
  bool _isCrossfadingTrack = false;

  String _activeStreamType = 'OPUS';
  String get activeStreamType => _activeStreamType;
  int _activeBitrate = 160000;
  int get activeBitrate => _activeBitrate;
  final Random _rng = Random();

  /// Resolves the stream or file URL for a playback item across environments.
  String _resolvePlaybackUrl(PlaybackItem item) {
    final offline = MusicRepository.instance.offlineFilePath(item.id);
    if (offline != null && offline.isNotEmpty && !kIsWeb) {
      return offline;
    }
    if (kIsWeb) {
      if (item.url.contains('/api/v1/music/')) {
        return item.url.contains('proxy=true')
            ? item.url
            : (item.url.contains('?') ? '${item.url}&proxy=true' : '${item.url}?proxy=true');
      }
      return '${ApiClient.instance.daemonUrl}/api/v1/music/ytstream/stream.m4a?id=${Uri.encodeComponent(item.id)}&proxy=true';
    }
    if (ApiClient.hasInstance) {
      if (item.url.contains('/api/v1/music/')) {
        return item.url.contains('proxy=true')
            ? item.url
            : (item.url.contains('?') ? '${item.url}&proxy=true' : '${item.url}?proxy=true');
      }
      return '${ApiClient.instance.daemonUrl}/api/v1/music/ytstream/stream.m4a?id=${Uri.encodeComponent(item.id)}&proxy=true';
    }
    return item.url;
  }

  /// Eagerly pre-caches a single track on the server host daemon.
  void precacheTrack(String trackId) {
    if (trackId.isEmpty || _precachedTrackIds.contains(trackId)) return;
    try {
      final offline = MusicRepository.instance.offlineFilePath(trackId);
      if (offline != null && offline.isNotEmpty) {
        _precachedTrackIds.add(trackId);
        return;
      }
    } catch (_) {}
    _precachedTrackIds.add(trackId);
    try {
      if (ApiClient.hasInstance) {
        ApiClient.instance
            .getDaemonSlow('/api/v1/music/resolve?id=${Uri.encodeComponent(trackId)}')
            .catchError((_) => null);
      }
    } catch (_) {}
  }

  /// Pre-caches upcoming items in the queue ahead of the current track.
  void precacheUpcoming({int? lookahead}) {
    final effectiveLookahead = lookahead ?? _lookaheadWindow;
    final q = _state.queue;
    final cur = _state.currentIndex;
    if (cur < 0) return;
    for (int step = 1; step <= effectiveLookahead; step++) {
      final targetIdx = cur + step;
      if (targetIdx < q.length) {
        precacheTrack(q[targetIdx].id);
      }
    }
  }

  void _bindPlayerStreams() {
    _processingSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    final p = player;
    if (p == null) return;
    _processingSub = p.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
    _playerStateSub = p.playerStateStream.listen((state) {
      if (state.playing) {
        _isLoadingTrack = false;
        _watchdogTimer?.cancel();
      }
    });
    _positionSub = p.positionStream.listen((pos) {
      final dur = p.duration;
      // Mid-song lookahead: when reaching half duration (or >= 20s for streams without duration)
      if (!_hasPrecachedMidpoint && pos.inSeconds >= 20) {
        if (dur == null || pos.inSeconds >= dur.inSeconds ~/ 2) {
          _hasPrecachedMidpoint = true;
          precacheUpcoming();
          if (_infiniteRadio && _state.currentIndex >= _state.queue.length - (_lookaheadWindow + 1)) {
            _fetchAndAppendRadio();
          }
        }
      }
      // 80% duration pre-fetch on host daemon
      if (!_hasPrecachedEightyPercent && dur != null && dur.inSeconds > 15) {
        if (pos.inSeconds >= (dur.inSeconds * 0.8).toInt()) {
          _hasPrecachedEightyPercent = true;
          final nextIdx = computeNextIndex();
          if (nextIdx != null && nextIdx < _state.queue.length) {
            precacheTrack(_state.queue[nextIdx].id);
          }
        }
      }

      // Standby player lookahead preload (~12-15s ahead of song end or 85%)
      if (!_hasPreloadedStandby && dur != null && dur.inSeconds > 20) {
        final preloadTriggerSec = (dur.inSeconds - _crossfadeDuration - 12).clamp(5, dur.inSeconds);
        if (pos.inSeconds >= preloadTriggerSec) {
          final nextIdx = computeNextIndex();
          if (nextIdx != null && nextIdx < _state.queue.length) {
            _hasPreloadedStandby = true;
            final nextItem = _state.queue[nextIdx];
            final nextUrl = _resolvePlaybackUrl(nextItem);
            playbackEngine.preloadStandby(nextUrl);
          }
        }
      }

      // Pro DJ Crossfade auto-trigger at (Duration - CrossfadeDuration)
      if (!_isCrossfadingTrack &&
          _crossfadeEnabled &&
          _crossfadeDuration > 0 &&
          _state.repeat != PlaybackRepeat.one &&
          dur != null &&
          dur.inSeconds > (_crossfadeDuration + 3)) {
        final crossfadeTriggerSec = dur.inSeconds - _crossfadeDuration;
        if (pos.inSeconds >= crossfadeTriggerSec) {
          final nextIdx = computeNextIndex();
          if (nextIdx != null && nextIdx < _state.queue.length) {
            _isCrossfadingTrack = true;
            _performCrossfadeTransition(nextIdx, Duration(seconds: _crossfadeDuration));
          }
        }
      }
    });
  }

  /// Lazily initializes the engine (called from the music UI initState).
  Future<void> ensureInitialized() async {
    if (!isAvailable) return;
    playbackEngine.onPlayerChanged = (_) {
      _bindPlayerStreams();
      notifyListeners();
    };
    playbackEngine.onCrossfadeChanged = (_) {
      notifyListeners();
    };
    await playbackEngine.init();
    _bindPlayerStreams();
  }

  // ---------------------------------------------------------------- queue

  void setQueue(List<PlaybackItem> items, {int currentIndex = 0}) {
    final safeStart = items.isEmpty ? -1 : currentIndex.clamp(0, items.length - 1);
    _state = _state.copyWith(queue: List.of(items), currentIndex: safeStart);
    notifyListeners();
  }

  Future<void> playQueue(List<PlaybackItem> items, {int startIndex = 0}) async {
    if (!isAvailable || items.isEmpty) return;
    final safeStart = startIndex.clamp(0, items.length - 1);
    _state = _state.copyWith(queue: List.of(items), currentIndex: safeStart);
    notifyListeners();
    await _playAt(safeStart);
  }

  /// Plays a selected track immediately and seeds fresh YouTube Music radio
  /// recommendations into the Up Next queue, discarding stale search lists.
  Future<void> playTrackAndStartRadio(PlaybackItem item) async {
    if (!isAvailable) return;
    setQueue([item], currentIndex: 0);
    await _playAt(0);
    await _fetchAndAppendRadio();
  }

  Future<void> playAt(int i) async {
    if (!isAvailable) return;
    if (i < 0 || i >= _state.queue.length) return;
    _state = _state.copyWith(currentIndex: i);
    notifyListeners();
    await _playAt(i);
  }

  int _playToken = 0;

  Future<void> _playAt(int i) async {
    final token = ++_playToken;
    final item = _state.queue[i];
    _userWantsPlay = true;
    _isLoadingTrack = true;
    _hasPrecachedMidpoint = false;
    _hasPrecachedEightyPercent = false;
    _hasPreloadedStandby = false;
    _isCrossfadingTrack = false;

    final playUrl = _resolvePlaybackUrl(item);

    if (item.url.contains('/offline/') || MusicRepository.instance.isOffline(item.id)) {
      _activeStreamType = 'OFFLINE';
      _activeBitrate = 320000;
    } else {
      _activeStreamType = 'OPUS';
      _activeBitrate = 160000;
    }

    notifyListeners();

    try {
      await playbackEngine.setUrl(playUrl);
      if (token != _playToken) return;

      if (_userWantsPlay) {
        try {
          await playbackEngine.play();
        } catch (e) {
          debugPrint('Music playback play() note: $e');
        }
        _startWatchdog();
        _precacheNext(i);
        _enrichTrackMetadata(item, i);
      }
    } catch (e) {
      debugPrint('Music playback setUrl failed: $e');
      if (token == _playToken) {
        _isLoadingTrack = false;
        notifyListeners();
        if (_userWantsPlay && _state.queue.length > 1 && i < _state.queue.length - 1) {
          debugPrint('Music playback: auto-skipping unavailable track to next item');
          await next();
        }
      }
    }
  }

  /// Concurrently enriches metadata and artwork from Deezer/iTunes in the background.
  Future<void> _enrichTrackMetadata(PlaybackItem item, int i) async {
    if (kIsWeb || !ApiClient.hasInstance) return;
    try {
      final resolveUri =
          '/api/v1/music/resolve?id=${Uri.encodeComponent(item.id)}&title=${Uri.encodeComponent(item.title)}&artist=${Uri.encodeComponent(item.artist)}';
      final res = await ApiClient.instance
          .getDaemon(resolveUri)
          .timeout(const Duration(milliseconds: 3500));
      if (res is Map && _state.currentIndex == i) {
        final st = res['stream_type']?.toString();
        final br = (res['bitrate'] as num?)?.toInt();
        if (st != null && st.isNotEmpty) _activeStreamType = st.toUpperCase();
        if (br != null && br > 0) _activeBitrate = br;

        final enrichedCover = res['cover_art_url']?.toString();
        final enrichedAlbum = res['album']?.toString();
        final enrichedGenre = res['genre']?.toString();
        final enrichedYear = (res['year'] as num?)?.toInt();

        if ((enrichedCover != null && enrichedCover.isNotEmpty) ||
            (enrichedAlbum != null && enrichedAlbum.isNotEmpty && item.album.isEmpty) ||
            (enrichedGenre != null && enrichedGenre.isNotEmpty && item.genre.isEmpty)) {
          final updatedItem = item.copyWith(
            thumbnail: (enrichedCover != null && enrichedCover.isNotEmpty)
                ? enrichedCover
                : item.thumbnail,
            album: (enrichedAlbum != null && enrichedAlbum.isNotEmpty)
                ? enrichedAlbum
                : item.album,
            genre: (enrichedGenre != null && enrichedGenre.isNotEmpty)
                ? enrichedGenre
                : item.genre,
            year: (enrichedYear != null && enrichedYear > 0) ? enrichedYear : item.year,
          );
          final newQ = List<PlaybackItem>.from(_state.queue);
          if (i < newQ.length) {
            newQ[i] = updatedItem;
            _state = _state.copyWith(queue: newQ);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Music resolve note: $e');
    }
  }

  /// Executes an Equal-Power DJ Crossfade transition into the specified queue index.
  Future<void> _performCrossfadeTransition(int nextIdx, Duration duration) async {
    if (nextIdx < 0 || nextIdx >= _state.queue.length) return;
    final nextItem = _state.queue[nextIdx];
    _recordCurrentTrackTelemetry(skipped: false);

    final nextUrl = _resolvePlaybackUrl(nextItem);
    await playbackEngine.preloadStandby(nextUrl);

    await playbackEngine.startCrossfade(
      duration: duration,
      onSwapped: () {
        _state = _state.copyWith(currentIndex: nextIdx);
        _hasPrecachedMidpoint = false;
        _hasPrecachedEightyPercent = false;
        _hasPreloadedStandby = false;
        _isCrossfadingTrack = false;
        _precacheNext(nextIdx);
        _enrichTrackMetadata(nextItem, nextIdx);
        notifyListeners();
      },
    );
  }

  bool _isFetchingRadio = false;

  Future<void> _fetchAndAppendRadio() async {
    if (_isFetchingRadio || _state.queue.isEmpty) return;
    _isFetchingRadio = true;
    try {
      final lastItem = _state.queue.last;
      final recs = await MusicRepository.instance.getRecommendations(
        seedTrackId: lastItem.id,
        artist: lastItem.artist,
        genre: lastItem.genre,
        limit: 10,
      );
      if (recs.isNotEmpty) {
        final existingIds = _state.queue.map((i) => i.id).toSet();
        for (final r in recs) {
          if (!existingIds.contains(r.id)) {
            final streamUrl = r.filePath.isNotEmpty && !kIsWeb
                ? r.filePath
                : '${ApiClient.instance.daemonUrl}/api/v1/music/ytstream/stream.m4a?id=${r.id}&proxy=true';
            addToQueue(PlaybackItem(
              id: r.id,
              url: streamUrl,
              title: r.title,
              artist: r.artist,
              thumbnail: r.thumbnail,
              album: r.album,
              genre: r.genre,
              year: r.year ?? 0,
            ));
          }
        }
        precacheUpcoming();
      }
    } catch (e) {
      debugPrint('Error fetching infinite radio recommendations: $e');
    } finally {
      _isFetchingRadio = false;
    }
  }

  void _precacheNext(int i) {
    precacheUpcoming();
    if (_infiniteRadio && i >= _state.queue.length - (_lookaheadWindow + 1)) {
      _fetchAndAppendRadio();
    }
  }

  Future<void> togglePlayPause() async {
    if (!isAvailable || _state.queue.isEmpty || currentItem == null) return;
    final p = player;
    if (p == null) return;
    if (p.playing) {
      _userWantsPlay = false;
      _isLoadingTrack = false;
      _watchdogTimer?.cancel();
      await playbackEngine.pause();
    } else {
      _userWantsPlay = true;
      try {
        await playbackEngine.play();
      } catch (e) {
        debugPrint('Music playback resume note: $e');
      }
      _startWatchdog();
    }
  }

  int? computeNextIndex() {
    if (_state.queue.isEmpty) return null;
    final q = _state.queue;
    final idx = _state.currentIndex;
    if (_state.shuffle && q.length > 1) {
      int target;
      do {
        target = _rng.nextInt(q.length);
      } while (target == idx);
      return target;
    } else if (idx < q.length - 1) {
      return idx + 1;
    } else if (_state.repeat == PlaybackRepeat.all) {
      return 0;
    }
    return null;
  }

  int? computePreviousIndex() {
    if (_state.queue.isEmpty) return null;
    final q = _state.queue;
    final idx = _state.currentIndex;
    if (_state.shuffle && q.length > 1) {
      return _rng.nextInt(q.length);
    } else if (idx > 0) {
      return idx - 1;
    } else if (_state.repeat == PlaybackRepeat.all) {
      return q.length - 1;
    }
    return 0;
  }

  void _recordCurrentTrackTelemetry({bool skipped = false}) {
    final cur = currentItem;
    final p = player;
    if (cur == null || p == null) return;
    final posMs = p.position.inMilliseconds;
    final durMs = (p.duration ?? Duration.zero).inMilliseconds;
    if (durMs <= 0 && posMs <= 3000) return;

    final compRate = durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : 1.0;
    MusicRepository.instance.recordListening(
      ListeningEvent(
        id: '',
        trackId: cur.id,
        playedAt: DateTime.now().millisecondsSinceEpoch,
        positionMs: posMs,
        durationMs: durMs > 0 ? durMs : null,
        completionRate: compRate,
        skipped: skipped,
        source: 'player',
      ),
      artist: cur.artist,
      genre: cur.genre,
    );
  }

  Future<void> next({bool userInitiated = true}) async {
    if (!isAvailable || _state.queue.isEmpty) return;
    if (userInitiated) {
      _recordCurrentTrackTelemetry(skipped: true);
    }
    int? target = computeNextIndex();

    if (target == null) {
      await _fetchAndAppendRadio();
      if (_state.currentIndex < _state.queue.length - 1) {
        target = _state.currentIndex + 1;
      } else if (_state.queue.length > 1 && _state.repeat == PlaybackRepeat.all) {
        target = 0;
      } else {
        return;
      }
    }

    final isPlaying = player?.playing ?? false;
    if (userInitiated &&
        _djTransitions &&
        _crossfadeEnabled &&
        _crossfadeDuration > 0 &&
        isPlaying) {
      // Pro DJ 1.2s smooth blend on manual skip!
      await _performCrossfadeTransition(target, const Duration(milliseconds: 1200));
    } else {
      await playAt(target);
    }
  }

  Future<void> previous() async {
    if (!isAvailable || _state.queue.isEmpty) return;
    final p = player;
    if (p != null && p.position > const Duration(seconds: 3)) {
      await p.seek(Duration.zero);
      return;
    }
    final target = computePreviousIndex();
    if (target != null) {
      await playAt(target);
    }
  }

  Future<void> seek(Duration position) async {
    await playbackEngine.seek(position);
  }

  Future<void> setMasterVolume(double vol) async {
    await playbackEngine.setMasterVolume(vol);
  }

  Future<void> _onTrackCompleted() async {
    if (!_userWantsPlay) return;
    if (_isCrossfadingTrack) return;
    _recordCurrentTrackTelemetry(skipped: false);

    final p = player;
    if (_state.repeat == PlaybackRepeat.one && p != null) {
      await p.seek(Duration.zero);
      try {
        await p.play();
      } catch (e) {
        debugPrint('Music playback repeat-one note: $e');
      }
      return;
    }

    final target = computeNextIndex();
    if (target != null && _hasPreloadedStandby) {
      // Standby player is preloaded: 0ms gapless transition!
      await _performCrossfadeTransition(target, Duration.zero);
    } else {
      await next(userInitiated: false);
    }
  }

  // ------------------------------------------------------------- controls

  void setRepeat(PlaybackRepeat mode) {
    _state = _state.copyWith(repeat: mode);
    notifyListeners();
    playbackEngine.setRepeatOne(mode == PlaybackRepeat.one);
  }

  void toggleShuffle() {
    _state = _state.copyWith(shuffle: !_state.shuffle);
    notifyListeners();
  }

  void setShuffle(bool enabled) {
    if (_state.shuffle == enabled) return;
    _state = _state.copyWith(shuffle: enabled);
    notifyListeners();
  }

  void removeAt(int index) {
    final q = List<PlaybackItem>.of(_state.queue);
    if (index < 0 || index >= q.length) return;
    final idx = _state.currentIndex;
    q.removeAt(index);
    if (idx == index) {
      _state = _state.copyWith(queue: q, currentIndex: -1);
      _userWantsPlay = false;
      _isLoadingTrack = false;
      _watchdogTimer?.cancel();
      playbackEngine.stop();
    } else if (idx > index) {
      _state = _state.copyWith(queue: q, currentIndex: idx - 1);
    } else {
      _state = _state.copyWith(queue: q);
    }
    notifyListeners();
  }

  void insertNext(PlaybackItem item) {
    final q = List<PlaybackItem>.of(_state.queue);
    final idx = _state.currentIndex;
    if (idx >= 0 && idx < q.length) {
      q.insert(idx + 1, item);
    } else {
      q.add(item);
    }
    _state = _state.copyWith(queue: q);
    notifyListeners();
  }

  void addToQueue(PlaybackItem item) {
    final q = List<PlaybackItem>.of(_state.queue)..add(item);
    _state = _state.copyWith(queue: q);
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    final q = List<PlaybackItem>.of(_state.queue);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = q.removeAt(oldIndex);
    q.insert(newIndex, item);
    final idx = _state.currentIndex;
    int newIdx = idx;
    if (idx == oldIndex) {
      newIdx = newIndex;
    } else if (idx > oldIndex && idx <= newIndex) {
      newIdx = idx - 1;
    } else if (idx < oldIndex && idx >= newIndex) {
      newIdx = idx + 1;
    }
    _state = _state.copyWith(queue: q, currentIndex: newIdx);
    notifyListeners();
  }

  void playIndex(int i) => playAt(i);
  void reorderQueue(int oldIndex, int newIndex) => reorder(oldIndex, newIndex);

  void clearQueue() {
    _userWantsPlay = false;
    _isLoadingTrack = false;
    _watchdogTimer?.cancel();
    _state = const PlaybackQueueState();
    playbackEngine.stop();
    notifyListeners();
  }

  // -------------------------------------------------------------- watchdog

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    int ticks = 0;
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      ticks++;
      if (!_userWantsPlay || !_isLoadingTrack) {
        timer.cancel();
        return;
      }
      final p = player;
      if (p != null && !p.playing) {
        try {
          p.play();
        } catch (e) {
          debugPrint('Music watchdog play note: $e');
        }
      }
      if ((p != null && p.playing && p.position > const Duration(milliseconds: 300)) ||
          ticks > 10) {
        _isLoadingTrack = false;
        timer.cancel();
      }
    });
  }

  /// The current stream URL for the playing item.
  String get currentPlaybackUrl => currentItem?.url ?? '';

  @override
  void dispose() {
    _userWantsPlay = false;
    _isLoadingTrack = false;
    _watchdogTimer?.cancel();
    _processingSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    playbackEngine.dispose();
    super.dispose();
  }
}