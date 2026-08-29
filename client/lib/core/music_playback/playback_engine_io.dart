import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../audio_dsp_service.dart';

/// Native audio engine backed by just_audio.
///
/// - Windows / Linux / macOS: just_audio_media_kit (mpv / AVFoundation)
/// - Android: ExoPlayer with a 10-band EQ AudioPipeline
/// - iOS: just_audio Apple platform
///
/// Music playback is intentionally unavailable on Flutter Web.
class PlaybackEngine {
  AudioPlayer? _player;
  bool _disposed = false;

  bool get isAvailable => !kIsWeb && !_disposed;

  AudioPlayer? get player => _player;

  /// Creates the shared player once, wiring the platform audio pipeline
  /// (Android EQ etc.) and attaching DSP.
  Future<void> init() async {
    if (!isAvailable) return;
    if (_player != null) return;
    _player = AudioPlayer(
      audioPipeline: AudioDspService.instance.buildAudioPipeline(),
      androidApplyAudioAttributes: true,
      handleInterruptions: true,
    );
    AudioDspService.instance.attachPlayer(_player!);
  }

  Future<void> setUrl(String url) async {
    final p = _player;
    if (p == null) return;
    await p.setUrl(url);
    AudioDspService.instance.reapply();
  }

  Future<void> play() async {
    final p = _player;
    if (p == null) return;
    await p.play();
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