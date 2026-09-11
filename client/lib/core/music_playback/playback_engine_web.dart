import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../audio_dsp_service.dart';

/// Web audio engine backed by a single, ultra-responsive just_audio_web player.
///
/// Prevents concurrent HTML5 audio element buffer collisions, eliminating ghost
/// audio replay, needle-sticking, and sluggish transport controls in web browsers.
class PlaybackEngine {
  AudioPlayer? _player;
  bool _disposed = false;
  double _masterVolume = 1.0;

  void Function(AudioPlayer)? onPlayerChanged;
  void Function(bool isCrossfading)? onCrossfadeChanged;

  bool get isAvailable => !_disposed;
  bool get isCrossfading => false;
  double get masterVolume => _masterVolume;
  AudioPlayer? get player => _player;

  /// Lazily creates the single dedicated web player instance.
  Future<void> init({bool withPipeline = false}) async {
    if (_disposed) return;
    if (_player != null) return;
    try {
      _player = AudioPlayer();
    } catch (e) {
      debugPrint('PlaybackEngine (web) init error: $e');
      return;
    }
    AudioDspService.instance.attachPlayer(_player!);
    onPlayerChanged?.call(_player!);
  }

  /// Immediately silences any active stream and binds the new stream URL.
  Future<void> setUrl(String url) async {
    if (_player == null) await init();
    final p = _player;
    if (p == null) return;

    // Hard stop any ongoing playback to guarantee no buffer collision in browser
    try {
      await p.stop();
    } catch (_) {}

    debugPrint('PlaybackEngine (web) setUrl: $url');
    try {
      await p.setVolume(_masterVolume);
      await p.setUrl(url);
    } catch (e) {
      debugPrint('PlaybackEngine (web) setUrl error: $e');
      rethrow;
    }
  }

  Future<void> preloadStandby(String url) async {
    // No-op on web to prevent dual HTML5 audio element lockups
  }

  Future<void> startCrossfade({
    required Duration duration,
    VoidCallback? onSwapped,
  }) async {
    onSwapped?.call();
  }

  Future<void> setMasterVolume(double vol) async {
    _masterVolume = vol.clamp(0.0, 1.0);
    await _player?.setVolume(_masterVolume);
  }

  Future<void> play() async {
    final p = _player;
    if (p == null) return;
    try {
      await p.play();
    } catch (e) {
      debugPrint('PlaybackEngine (web) play error: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    final p = _player;
    if (p == null) return;
    await p.pause();
  }

  Future<void> stop() async {
    final p = _player;
    if (p == null) return;
    await p.stop();
  }

  Future<void> seek(Duration position) async {
    final p = _player;
    if (p == null) return;
    await p.seek(position);
  }

  Future<void> setRepeatOne(bool one) async {
    final p = _player;
    if (p == null) return;
    await p.setLoopMode(one ? LoopMode.one : LoopMode.off);
  }

  void dispose() async {
    _disposed = true;
    final p = _player;
    _player = null;
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