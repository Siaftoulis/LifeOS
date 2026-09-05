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
  bool _hasEqualizerPipeline = false;
  void Function(AudioPlayer)? onPlayerChanged;

  bool get isAvailable => !kIsWeb && !_disposed;

  AudioPlayer? get player => _player;

  /// Creates the shared player once, wiring the platform audio pipeline
  /// (Android EQ etc.) and attaching DSP.
  Future<void> init({bool withPipeline = true}) async {
    if (!isAvailable) return;
    if (_player != null) return;
    try {
      if (withPipeline) {
        _player = AudioPlayer(
          audioPipeline: AudioDspService.instance.buildAudioPipeline(),
          androidApplyAudioAttributes: true,
          handleInterruptions: true,
        );
        _hasEqualizerPipeline = true;
      } else {
        _player = AudioPlayer(
          androidApplyAudioAttributes: true,
          handleInterruptions: true,
        );
        _hasEqualizerPipeline = false;
      }
    } catch (e) {
      debugPrint('PlaybackEngine init error: $e, falling back to plain player');
      _player = AudioPlayer(
        androidApplyAudioAttributes: true,
        handleInterruptions: true,
      );
      _hasEqualizerPipeline = false;
    }
    AudioDspService.instance.attachPlayer(_player!);
    onPlayerChanged?.call(_player!);
  }

  Future<void> _reinitWithoutPipeline() async {
    final old = _player;
    _player = null;
    if (old != null) {
      try {
        await old.stop();
      } catch (_) {}
      try {
        await old.dispose();
      } catch (_) {}
    }
    _hasEqualizerPipeline = false;
    AudioDspService.instance.disableHardwareEq();
    _player = AudioPlayer(
      androidApplyAudioAttributes: true,
      handleInterruptions: true,
    );
    AudioDspService.instance.attachPlayer(_player!);
    onPlayerChanged?.call(_player!);
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

  Future<void> setUrl(String url) async {
    if (_player == null) await init();
    final p = _player;
    if (p == null) return;
    try {
      await _loadSource(p, url);
    } catch (e) {
      debugPrint('PlaybackEngine setUrl error: $e');
      if (_hasEqualizerPipeline) {
        debugPrint('PlaybackEngine: retrying without hardware audio effects pipeline for device compatibility');
        await _reinitWithoutPipeline();
        final fallbackPlayer = _player;
        if (fallbackPlayer != null) {
          await _loadSource(fallbackPlayer, url);
        }
      } else {
        rethrow;
      }
    }
    AudioDspService.instance.reapply();
  }

  Future<void> play() async {
    final p = _player;
    if (p == null) return;
    try {
      await p.play();
    } catch (e) {
      debugPrint('PlaybackEngine play() error: $e');
      if (_hasEqualizerPipeline) {
        debugPrint('PlaybackEngine: play() failed with pipeline, reinitializing without pipeline');
        await _reinitWithoutPipeline();
        final fallback = _player;
        if (fallback != null) {
          await fallback.play();
          return;
        }
      }
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