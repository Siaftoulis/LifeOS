import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../audio_dsp_service.dart';

/// Web audio engine backed by just_audio_web (HTML5 Audio / Web Audio) with Dual-Player DJ Crossfade.
class PlaybackEngine {
  AudioPlayer? _playerA;
  AudioPlayer? _playerB;
  bool _activeIsA = true;
  bool _disposed = false;

  double _masterVolume = 1.0;
  bool _isCrossfading = false;
  Timer? _crossfadeTimer;

  String? _preloadedUrl;
  String? get preloadedUrl => _preloadedUrl;

  void Function(AudioPlayer)? onPlayerChanged;
  void Function(bool isCrossfading)? onCrossfadeChanged;

  bool get isAvailable => !_disposed;
  bool get isCrossfading => _isCrossfading;
  double get masterVolume => _masterVolume;

  AudioPlayer? get activePlayer => _activeIsA ? _playerA : _playerB;
  AudioPlayer? get standbyPlayer => _activeIsA ? _playerB : _playerA;
  AudioPlayer? get player => activePlayer;

  /// Creates the primary and standby players once and wires events.
  Future<void> init({bool withPipeline = false}) async {
    if (_disposed) return;
    if (_playerA != null) return;
    try {
      _playerA = AudioPlayer();
      _playerB = AudioPlayer();
    } catch (e) {
      debugPrint('PlaybackEngine (web) init error: $e');
      return;
    }
    _activeIsA = true;
    AudioDspService.instance.attachPlayer(_playerA!);
    onPlayerChanged?.call(_playerA!);
  }

  Future<void> setUrl(String url) async {
    if (_playerA == null) await init();
    _cancelCrossfade();
    final p = activePlayer;
    if (p == null) return;
    _preloadedUrl = null;
    debugPrint('PlaybackEngine (web) setUrl: $url');
    try {
      p.setVolume(_masterVolume);
      await p.setUrl(url);
    } catch (e) {
      debugPrint('PlaybackEngine (web) setUrl error: $e');
      rethrow;
    }
  }

  Future<void> preloadStandby(String url) async {
    if (_playerA == null) await init();
    final sb = standbyPlayer;
    if (sb == null) return;
    if (_preloadedUrl == url) return;
    try {
      _preloadedUrl = url;
      await sb.setVolume(0.0);
      await sb.setUrl(url);
    } catch (e) {
      debugPrint('PlaybackEngine (web) preloadStandby note: $e');
    }
  }

  /// Executes studio-grade Equal-Power DJ Crossfade:
  /// gainOut = cos(t * pi / 2)
  /// gainIn  = sin(t * pi / 2)
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
      debugPrint('PlaybackEngine (web) crossfade start incoming error: $e');
    }

    const tickMs = 50;
    final totalSteps = (duration.inMilliseconds / tickMs).clamp(4, 300).toInt();
    int currentStep = 0;
    bool hasSwappedActive = false;

    _crossfadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) async {
      currentStep++;
      final t = (currentStep / totalSteps).clamp(0.0, 1.0);

      final gainOut = math.cos(t * math.pi / 2.0);
      final gainIn = math.sin(t * math.pi / 2.0);

      try {
        await outgoing.setVolume((gainOut * _masterVolume).clamp(0.0, 1.0));
        await incoming.setVolume((gainIn * _masterVolume).clamp(0.0, 1.0));
      } catch (_) {}

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
      debugPrint('PlaybackEngine (web) play error: $e');
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