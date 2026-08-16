import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_dsp_native.dart'
    if (dart.library.js_interop) 'audio_dsp_web.dart'
    if (dart.library.html) 'audio_dsp_web.dart';

/// Manages audiophile DSP audio processing, 10-Band EQ, Preamp, Bass/Treble boost, and 3D Spatial Audio.
class AudioDspService {
  AudioDspService._();
  static final AudioDspService instance = AudioDspService._();

  bool _enabled = true;
  double _preamp = 0.0; // -12.0 to +12.0 dB
  double _bassBoost = 0.25; // 0.0 to 1.0
  double _trebleBoost = 0.15; // 0.0 to 1.0
  double _spatial3d = 0.30; // 0.0 to 1.0
  List<double> _bands = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  AndroidEqualizer? _androidEqualizer;
  AudioPlayer? _activePlayer;

  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onDspChanged => _changeController.stream;

  bool get enabled => _enabled;
  double get preamp => _preamp;
  double get bassBoost => _bassBoost;
  double get trebleBoost => _trebleBoost;
  double get spatial3d => _spatial3d;
  List<double> get bands => List.unmodifiable(_bands);

  void attachPlayer(AudioPlayer player) {
    _activePlayer = player;
    _initNativeEffects();
  }

  Future<void> _initNativeEffects() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && _activePlayer != null) {
      try {
        _androidEqualizer ??= AndroidEqualizer();
        await _androidEqualizer?.setEnabled(_enabled);
      } catch (e) {
        debugPrint('AndroidEqualizer init note: $e');
      }
    }
    _applyToNative();
  }

  void updateSettings({
    bool? enabled,
    double? preamp,
    double? bassBoost,
    double? trebleBoost,
    double? spatial3d,
    List<double>? bands,
  }) {
    if (enabled != null) _enabled = enabled;
    if (preamp != null) _preamp = preamp;
    if (bassBoost != null) _bassBoost = bassBoost;
    if (trebleBoost != null) _trebleBoost = trebleBoost;
    if (spatial3d != null) _spatial3d = spatial3d;
    if (bands != null) _bands = List.from(bands);

    _applyToNative();
    _changeController.add(null);
  }

  /// Reapplies current DSP filters to all active native players (e.g. after track changes)
  void reapply() {
    _applyToNative();
  }

  String _buildMpvFilterString() {
    if (!_enabled) return '';
    final filters = <String>[];

    // 1. Preamp Volume
    if (_preamp.abs() > 0.05) {
      filters.add('volume=volume=${_preamp.toStringAsFixed(1)}dB');
    }

    // 2. Bass Boost (centered at 110Hz with 0.6 Q width for punchy warmth)
    if (_bassBoost > 0.01) {
      final bassGainDb = _bassBoost * 18.0; // up to +18 dB
      filters.add('bass=g=${bassGainDb.toStringAsFixed(1)}:f=110:w=0.6');
    }

    // 3. Treble Boost (centered at 8000Hz for crystalline sparkle)
    if (_trebleBoost > 0.01) {
      final trebleGainDb = _trebleBoost * 18.0; // up to +18 dB
      filters.add('treble=g=${trebleGainDb.toStringAsFixed(1)}:f=8000:w=0.6');
    }

    // 4. 3D Spatial Audio / Stereo Expansion (1.0 = standard, up to 3.5 = expansive 3D soundstage)
    if (_spatial3d > 0.01) {
      final m = 1.0 + (_spatial3d * 2.5);
      filters.add('stereotools=slev=${m.toStringAsFixed(2)}');
    }

    // 5. 10-Band Parametric/Graphic Equalizer
    const freqs = [31.25, 62.5, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0];
    for (int i = 0; i < _bands.length && i < freqs.length; i++) {
      final gain = _bands[i];
      if (gain.abs() > 0.1) {
        filters.add('equalizer=f=${freqs[i]}:width_type=o:width=1.0:g=${gain.toStringAsFixed(1)}');
      }
    }

    if (filters.isEmpty) return '';
    return 'lavfi=[${filters.join(',')}]';
  }

  void _applyToNative() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final afString = _buildMpvFilterString();
      NativeAudioDspEngine.applyMpvFilters(afString);
    }

    // Android Equalizer fallback
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && _androidEqualizer != null) {
      _androidEqualizer?.setEnabled(_enabled);
    }
  }
}
