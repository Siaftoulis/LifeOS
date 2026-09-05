import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer, ProcessingState;
import '../../api_client.dart';
import 'playback_engine.dart';
import 'playback_models.dart';

/// Singleton music playback controller.
///
/// Owns the queue, repeat/shuffle semantics and the single audio engine.
/// On Flutter Web the engine is a no-op: `isAvailable` is false and the UI
/// must show the library without playback affordances.
class PlaybackController extends ChangeNotifier {
  PlaybackController._();
  static final PlaybackController instance = PlaybackController._();

  PlaybackQueueState _state = const PlaybackQueueState();
  PlaybackQueueState get state => _state;

  PlaybackItem? get currentItem => _state.current;
  List<PlaybackItem> get queue => _state.queue;
  int get currentIndex => _state.currentIndex;
  PlaybackRepeat get repeat => _state.repeat;
  bool get shuffle => _state.shuffle;

  /// True only on native platforms (Windows/Linux/macOS/iOS/Android).
  bool get isAvailable => playbackEngine.isAvailable;

  /// The underlying just_audio player (null on web).
  AudioPlayer? get player => playbackEngine.player;

  bool _userWantsPlay = false;
  bool _isLoadingTrack = false;
  Timer? _watchdogTimer;

  StreamSubscription<dynamic>? _processingSub;
  StreamSubscription<dynamic>? _playerStateSub;
  final Random _rng = Random();

  /// Lazily initializes the engine (called from the music UI initState).
  Future<void> ensureInitialized() async {
    if (!isAvailable) return;
    await playbackEngine.init();
    _processingSub ??= player?.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
    _playerStateSub ??= player?.playerStateStream.listen((state) {
      if (state.playing) {
        _isLoadingTrack = false;
        _watchdogTimer?.cancel();
      }
    });
  }

  // ---------------------------------------------------------------- queue

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

  Future<void> _playAt(int i) async {
    final item = _state.queue[i];
    _userWantsPlay = true;
    _isLoadingTrack = true;
    try {
      await playbackEngine.setUrl(item.url);
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
      _userWantsPlay = false;
      _isLoadingTrack = false;
    }
  }

  void _precacheNext(int i) {
    if (i + 1 >= _state.queue.length) return;
    final next = _state.queue[i + 1];
    ApiClient.instance
        .getDaemonSlow('/api/v1/music/resolve?id=${next.id}')
        .catchError((_) => null);
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
    } else {
      return; // at the end, nothing to advance to
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
    playbackEngine.dispose();
    super.dispose();
  }
}