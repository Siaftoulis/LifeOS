import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer, ProcessingState;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_client.dart';
import '../domain_repositories.dart';
import 'playback_engine.dart';
import 'playback_models.dart';

/// Singleton music playback controller.
///
/// Owns the queue, repeat/shuffle semantics and the single audio engine.
/// On Flutter Web the engine is a no-op: `isAvailable` is false and the UI
/// must show the library without playback affordances.
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

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _infiniteRadio = prefs.getBool('music_infinite_radio') ?? true;
      _lookaheadWindow = prefs.getInt('music_lookahead_window') ?? 3;
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

  /// True only on native platforms (Windows/Linux/macOS/iOS/Android).
  bool get isAvailable => playbackEngine.isAvailable;

  /// The underlying just_audio player (null on web).
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
  String _activeStreamType = 'OPUS';
  String get activeStreamType => _activeStreamType;
  int _activeBitrate = 160000;
  int get activeBitrate => _activeBitrate;
  final Random _rng = Random();

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
      // 80% duration pre-fetch for gapless stream transitions
      if (!_hasPrecachedEightyPercent && dur != null && dur.inSeconds > 15) {
        if (pos.inSeconds >= (dur.inSeconds * 0.8).toInt()) {
          _hasPrecachedEightyPercent = true;
          final nextIdx = _state.currentIndex + 1;
          if (nextIdx < _state.queue.length) {
            precacheTrack(_state.queue[nextIdx].id);
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

    String playUrl = item.url;
    final offline = MusicRepository.instance.offlineFilePath(item.id);
    if (offline != null && offline.isNotEmpty && !kIsWeb) {
      playUrl = offline;
      _activeStreamType = 'OFFLINE';
      _activeBitrate = 320000;
    } else if (kIsWeb) {
      _activeStreamType = 'OPUS';
      _activeBitrate = 160000;
      if (item.url.contains('/api/v1/music/')) {
        playUrl = item.url.contains('proxy=true')
            ? item.url
            : (item.url.contains('?') ? '${item.url}&proxy=true' : '${item.url}?proxy=true');
      } else {
        playUrl = '${ApiClient.instance.daemonUrl}/api/v1/music/stream/?id=${Uri.encodeComponent(item.id)}&proxy=true';
      }
    } else if (ApiClient.hasInstance) {
      _activeStreamType = 'OPUS';
      _activeBitrate = 160000;
      try {
        final res = await ApiClient.instance
            .getDaemon('/api/v1/music/resolve?id=${Uri.encodeComponent(item.id)}')
            .timeout(const Duration(milliseconds: 3500));
        if (res is Map && token == _playToken) {
          final direct = res['direct_url']?.toString();
          if (direct != null && direct.startsWith('http')) {
            playUrl = direct;
          }
          final st = res['stream_type']?.toString();
          final br = (res['bitrate'] as num?)?.toInt();
          if (st != null && st.isNotEmpty) _activeStreamType = st.toUpperCase();
          if (br != null && br > 0) _activeBitrate = br;
        }
      } catch (e) {
        debugPrint('Music resolve note: $e, using stream endpoint');
      }
    }
    if (token != _playToken) {
      return; // Superseded by a newer skip request
    }
    notifyListeners();

    try {
      await playbackEngine.setUrl(playUrl);
      if (token != _playToken) {
        return; // Superseded by a newer skip request
      }
      if (_userWantsPlay) {
        try {
          await playbackEngine.play();
        } catch (e) {
          debugPrint('Music playback play() note: $e');
        }
        _startWatchdog();
        _precacheNext(i);
      }
    } catch (e) {
      debugPrint('Music playback setUrl failed: $e');
      if (token == _playToken) {
        _isLoadingTrack = false;
        notifyListeners();
        // Auto-skip failing track if user wanted to play and queue has more tracks
        if (_userWantsPlay && _state.queue.length > 1 && i < _state.queue.length - 1) {
          debugPrint('Music playback: auto-skipping unavailable track to next item');
          await next();
        }
      }
    }
  }

  bool _isFetchingRadio = false;

  Future<void> _fetchAndAppendRadio() async {
    if (_isFetchingRadio || _state.queue.isEmpty) return;
    _isFetchingRadio = true;
    try {
      final lastItem = _state.queue.last;
      final recs = await MusicRepository.instance.getRecommendations(
        seedTrackId: lastItem.id,
        limit: 10,
      );
      if (recs.isNotEmpty) {
        final existingIds = _state.queue.map((i) => i.id).toSet();
        for (final r in recs) {
          if (!existingIds.contains(r.id)) {
            final streamUrl = r.filePath.isNotEmpty && !kIsWeb
                ? r.filePath
                : '${ApiClient.instance.daemonUrl}/api/v1/music/ytstream/stream.m4a?id=${r.id}${kIsWeb ? '&proxy=true' : ''}';
            addToQueue(PlaybackItem(
              id: r.id,
              url: streamUrl,
              title: r.title,
              artist: r.artist,
              thumbnail: r.thumbnail,
              album: r.album,
            ));
          }
        }
        // Eagerly pre-cache upcoming radio items immediately
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
      await p.pause();
    } else {
      _userWantsPlay = true;
      try {
        await p.play();
      } catch (e) {
        debugPrint('Music playback resume note: $e');
      }
      _startWatchdog();
    }
  }

  Future<void> next() async {
    if (!isAvailable || _state.queue.isEmpty) return;
    final q = _state.queue;
    final idx = _state.currentIndex;
    int target;

    if (_state.shuffle && q.length > 1) {
      do {
        target = _rng.nextInt(q.length);
      } while (target == idx);
    } else if (idx < q.length - 1) {
      target = idx + 1;
    } else if (_state.repeat == PlaybackRepeat.all) {
      target = 0;
    } else if (q.isNotEmpty) {
      // Auto-fetch recommendations/radio when reaching queue end
      await _fetchAndAppendRadio();
      if (_state.currentIndex < _state.queue.length - 1) {
        target = _state.currentIndex + 1;
      } else if (q.length > 1) {
        target = 0; // Wrap around if no new recommendations could be appended
      } else {
        return;
      }
    } else {
      return;
    }
    await playAt(target);
  }

  Future<void> previous() async {
    if (!isAvailable || _state.queue.isEmpty) return;
    final p = player;
    if (p != null && p.position > const Duration(seconds: 3)) {
      await p.seek(Duration.zero);
      return;
    }
    final q = _state.queue;
    final idx = _state.currentIndex;
    int target;
    if (_state.shuffle && q.length > 1) {
      target = _rng.nextInt(q.length);
    } else if (idx > 0) {
      target = idx - 1;
    } else if (_state.repeat == PlaybackRepeat.all) {
      target = q.length - 1;
    } else {
      target = 0;
    }
    await playAt(target);
  }

  Future<void> seek(Duration position) async {
    await playbackEngine.seek(position);
  }

  Future<void> _onTrackCompleted() async {
    if (!_userWantsPlay) return;
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
    await next();
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
  // Windows media_kit can occasionally drop into a not-playing state right
  // after setUrl; retry play() briefly so startup never gets stuck.

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

  /// The current stream URL for the playing item (for metadata modals).
  String get currentPlaybackUrl => currentItem?.url ?? '';

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