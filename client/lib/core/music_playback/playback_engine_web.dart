import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../audio_dsp_service.dart';

/// Web audio engine backed by just_audio_web (HTML5 Audio / Web Audio).
class PlaybackEngine {
  AudioPlayer? _player;
  bool _disposed = false;
  void Function(AudioPlayer)? onPlayerChanged;

  bool get isAvailable => !_disposed;

  AudioPlayer? get player => _player;

  /// Creates the shared web player once and wires events.
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

  Future<void> setUrl(String url) async {
    if (_player == null) await init();
    final p = _player;
    if (p == null) return;
    debugPrint('PlaybackEngine (web) setUrl: $url');
    try {
      await p.setUrl(url);
    } catch (e) {
      debugPrint('PlaybackEngine (web) setUrl error: $e');
      rethrow;
    }
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