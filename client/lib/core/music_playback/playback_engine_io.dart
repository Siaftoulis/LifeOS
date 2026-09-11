import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../audio_dsp_service.dart';

/// Native audio engine backed by just_audio with Dual-Player DJ Crossfading.
///
/// - Windows / Linux / macOS: just_audio_media_kit (mpv / AVFoundation)
/// - Android: ExoPlayer with a 10-band EQ AudioPipeline
/// - iOS: just_audio Apple platform
///
/// Supports studio-grade Equal-Power DJ crossfading and 0ms gapless transitions.
class PlaybackEngine {
  AudioPlayer? _playerA;
  AudioPlayer? _playerB;
  bool _activeIsA = true;
  bool _disposed = false;
  bool _hasEqualizerPipeline = false;

  double _masterVolume = 1.0;
  bool _isCrossfading = false;
  Timer? _crossfadeTimer;

  String? _preloadedUrl;
  String? get preloadedUrl => _preloadedUrl;

  void Function(AudioPlayer)? onPlayerChanged;
  void Function(bool isCrossfading)? onCrossfadeChanged;

  bool get isAvailable => !kIsWeb && !_disposed;
  bool get isCrossfading => _isCrossfading;
  double get masterVolume => _masterVolume;

  AudioPlayer? get activePlayer => _activeIsA ? _playerA : _playerB;
  AudioPlayer? get standbyPlayer => _activeIsA ? _playerB : _playerA;
  AudioPlayer? get player => activePlayer;

  Future<AudioPlayer> _createPlayer({bool withPipeline = true}) async {
    AudioPlayer p;
    try {
      if (withPipeline) {
        p = AudioPlayer(
          audioPipeline: AudioDspService.instance.buildAudioPipeline(),
          androidApplyAudioAttributes: true,
          handleInterruptions: true,
        );
        _hasEqualizerPipeline = true;
      } else {
        p = AudioPlayer(
          androidApplyAudioAttributes: true,
          handleInterruptions: true,
        );
      }
    } catch (e) {
      debugPrint('PlaybackEngine _createPlayer error: $e, falling back to plain player');
      p = AudioPlayer(
        androidApplyAudioAttributes: true,
        handleInterruptions: true,
      );
    }
    return p;
  }

  /// Creates the primary and standby players once, wiring the platform audio pipeline
  /// and attaching DSP.
  Future<void> init({bool withPipeline = true}) async {
    if (!isAvailable) return;
    if (_playerA != null) return;
    _playerA = await _createPlayer(withPipeline: withPipeline);
    _playerB = await _createPlayer(withPipeline: false);
    _activeIsA = true;

    AudioDspService.instance.attachPlayer(_playerA!);
    onPlayerChanged?.call(_playerA!);
  }

  Future<void> _reinitWithoutPipeline() async {
    final oldA = _playerA;
    final oldB = _playerB;
    _playerA = null;
    _playerB = null;
    _cancelCrossfade();

    for (final old in [oldA, oldB]) {
      if (old != null) {
        try {
          await old.stop();
        } catch (_) {}
        try {
          await old.dispose();
        } catch (_) {}
      }
    }
    _hasEqualizerPipeline = false;
    AudioDspService.instance.disableHardwareEq();

    _playerA = await _createPlayer(withPipeline: false);
    _playerB = await _createPlayer(withPipeline: false);
    _activeIsA = true;

    AudioDspService.instance.attachPlayer(_playerA!);
    onPlayerChanged?.call(_playerA!);
  }

  Future<void> _loadSource(AudioPlayer p, String url) async {
    if (url.startsWith('file://')) {
      final filePath = Uri.parse(url).toFilePath();
      await p.setFilePath(filePath);
    } else if (url.startsWith('/') || (url.length > 2 && url[1] == ':')) {
      await p.setFilePath(url);
    } else {
      await p.setUrl(url);
    }
  }

  /// Sets the active track URL on the active player.
  Future<void> setUrl(String url) async {
    if (_playerA == null) await init();
    _cancelCrossfade();
    final p = activePlayer;
    if (p == null) return;
    _preloadedUrl = null;
    p.setVolume(_masterVolume);
    try {
      await _loadSource(p, url);
    } catch (e) {
      debugPrint('PlaybackEngine setUrl error: $e');
      if (_hasEqualizerPipeline) {
        debugPrint('PlaybackEngine: retrying without hardware audio effects pipeline');
        await _reinitWithoutPipeline();
        final fallback = activePlayer;
        if (fallback != null) {
          await _loadSource(fallback, url);
        }
      } else {
        rethrow;
      }
    }
    AudioDspService.instance.reapply();
  }

  /// Preloads an upcoming track on the standby player at volume 0.0
  /// so it is primed for an instant 0ms transition or DJ crossfade.
  Future<void> preloadStandby(String url) async {
    if (_playerA == null) await init();
    final sb = standbyPlayer;
    if (sb == null) return;
    if (_preloadedUrl == url) return; // already loaded!
    try {
      _preloadedUrl = url;
      await sb.setVolume(0.0);
      await _loadSource(sb, url);
    } catch (e) {
      debugPrint('PlaybackEngine preloadStandby note: $e');
    }
  }

  /// Executes studio-grade Equal-Power DJ Crossfade:
  /// gainOut = cos(t * pi / 2)
  /// gainIn  = sin(t * pi / 2)
  /// Preserves constant acoustic energy without halfway volume dips.
  Future<void> startCrossfade({
    required Duration duration,
    VoidCallback? onSwapped,
  }) async {
    final outgoing = activePlayer;
    final incoming = standbyPlayer;
    if (outgoing == null || incoming == null || duration.inMilliseconds <= 0) {
      // 0ms Gapless immediate switch
      _cancelCrossfade();
      await outgoing?.stop();
      _activeIsA = !_activeIsA;
      await activePlayer?.setVolume(_masterVolume);
      await activePlayer?.play();
      AudioDspService.instance.attachPlayer(activePlayer!);
      onPlayerChanged?.call(activePlayer!);
      onSwapped?.call();
      return;
    }

    _cancelCrossfade();
    _isCrossfading = true;
    onCrossfadeChanged?.call(true);

    await incoming.setVolume(0.0);
    try {
      await incoming.play();
    } catch (e) {
      debugPrint('PlaybackEngine crossfade start incoming error: $e');
    }

    // Step calculations: 50ms intervals
    const tickMs = 50;
    final totalSteps = (duration.inMilliseconds / tickMs).clamp(4, 300).toInt();
    int currentStep = 0;
    bool hasSwappedActive = false;

    _crossfadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) async {
      currentStep++;
      final t = (currentStep / totalSteps).clamp(0.0, 1.0);

      // Equal-power curve
      final gainOut = math.cos(t * math.pi / 2.0);
      final gainIn = math.sin(t * math.pi / 2.0);

      try {
        await outgoing.setVolume((gainOut * _masterVolume).clamp(0.0, 1.0));
        await incoming.setVolume((gainIn * _masterVolume).clamp(0.0, 1.0));
      } catch (_) {}

      // Swap active player on first tick so Now Playing displays the incoming song
      if (!hasSwappedActive && currentStep >= 1) {
        hasSwappedActive = true;
        _activeIsA = !_activeIsA;
        AudioDspService.instance.attachPlayer(activePlayer!);
        onPlayerChanged?.call(activePlayer!);
        onSwapped?.call();
      }

      if (currentStep >= totalSteps) {
        timer.cancel();
        _isCrossfading = false;
        onCrossfadeChanged?.call(false);
        _preloadedUrl = null;
        try {
          await outgoing.stop();
          await outgoing.setVolume(_masterVolume);
          await incoming.setVolume(_masterVolume);
        } catch (_) {}
      }
    });
  }

  void _cancelCrossfade() {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
    if (_isCrossfading) {
      _isCrossfading = false;
      onCrossfadeChanged?.call(false);
    }
  }

  Future<void> setMasterVolume(double vol) async {
    _masterVolume = vol.clamp(0.0, 1.0);
    if (!_isCrossfading) {
      await activePlayer?.setVolume(_masterVolume);
    }
  }

  Future<void> play() async {
    final p = activePlayer;
    if (p == null) return;
    try {
      await p.play();
    } catch (e) {
      debugPrint('PlaybackEngine play() error: $e');
      if (_hasEqualizerPipeline) {
        debugPrint('PlaybackEngine: play() failed with pipeline, reinitializing');
        await _reinitWithoutPipeline();
        final fallback = activePlayer;
        if (fallback != null) {
          await fallback.play();
          return;
        }
      }
      rethrow;
    }
  }

  Future<void> pause() async {
    _cancelCrossfade();
    await _playerA?.pause();
    await _playerB?.pause();
  }

  Future<void> stop() async {
    _cancelCrossfade();
    _preloadedUrl = null;
    await _playerA?.stop();
    await _playerB?.stop();
    await _playerA?.setVolume(_masterVolume);
    await _playerB?.setVolume(_masterVolume);
  }

  Future<void> seek(Duration position) async {
    if (_isCrossfading) {
      _cancelCrossfade();
      await standbyPlayer?.stop();
      await activePlayer?.setVolume(_masterVolume);
    }
    await activePlayer?.seek(position);
  }

  Future<void> setRepeatOne(bool one) async {
    final p = activePlayer;
    if (p == null) return;
    await p.setLoopMode(one ? LoopMode.one : LoopMode.off);
  }

  void dispose() async {
    _disposed = true;
    _cancelCrossfade();
    final pA = _playerA;
    final pB = _playerB;
    _playerA = null;
    _playerB = null;
    for (final p in [pA, pB]) {
      if (p != null) {
        try {
          await p.stop();
        } catch (_) {}
        try {
          await p.dispose();
        } catch (_) {}
      }
    }
  }
}