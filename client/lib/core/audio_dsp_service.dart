import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_dsp_native.dart'
    if (dart.library.js_interop) 'audio_dsp_web.dart'
    if (dart.library.html) 'audio_dsp_web.dart';

/// Manages audiophile DSP audio processing, 10-Band EQ, Preamp, Bass/Treble boost, and 3D Spatial Audio.
///
/// Platform support:
/// - Windows / Linux: mpv `af` filter chain applied to the media_kit player.
/// - Android: `AndroidEqualizer` (5 hardware bands) wired via the just_audio
///   AudioPipeline, gains mapped from our 10-band model.
/// - macOS / iOS: no EQ API in just_audio 0.10.x — settings are kept for
///   when the pipeline supports Darwin effects.
/// - Web: no-op (playback is native-only).
class AudioDspService {
  AudioDspService._();
  static final AudioDspService instance = AudioDspService._();

  static const String _prefsKey = 'music_dsp_settings_v1';

  bool _enabled = true;
  double _preamp = 0.0; // -12.0 to +12.0 dB
  double _bassBoost = 0.25; // 0.0 to 1.0
  double _trebleBoost = 0.15; // 0.0 to 1.0
  double _spatial3d = 0.30; // 0.0 to 1.0
  List<double> _bands = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  AndroidEqualizer? _androidEqualizer;
  AudioPlayer? _activePlayer;
  bool _prefsLoaded = false;
  bool _hardwareEqSupported = true;

  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onDspChanged => _changeController.stream;

  bool get enabled => _enabled;
  double get preamp => _preamp;
  double get bassBoost => _bassBoost;
  double get trebleBoost => _trebleBoost;
  double get spatial3d => _spatial3d;
  List<double> get bands => List.unmodifiable(_bands);

  /// Disables Android hardware EQ if the device sound system rejects it.
  void disableHardwareEq() {
    _hardwareEqSupported = false;
    _androidEqualizer = null;
  }

  /// Whether this platform can actually apply DSP to the audio output.
  bool get isSupportedOnPlatform {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.android:
        return true;
      default:
        return false;
    }
  }

  /// Builds the just_audio [AudioPipeline] for the platform. MUST be called
  /// once before the [AudioPlayer] is constructed so EQ effects attach.
  AudioPipeline buildAudioPipeline() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && _hardwareEqSupported) {
      try {
        _androidEqualizer = AndroidEqualizer();
        return AudioPipeline(androidAudioEffects: [_androidEqualizer!]);
      } catch (e) {
        debugPrint('AudioDspService: AndroidEqualizer unavailable on this device: $e');
        _androidEqualizer = null;
        _hardwareEqSupported = false;
        return AudioPipeline();
      }
    }
    return AudioPipeline();
  }

  /// Loads persisted DSP settings (called once at app start).
  Future<void> init() async {
    if (_prefsLoaded) return;
    _prefsLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final map = Map<String, dynamic>.from(
          (raw.split('|').map((kv) => kv.split('='))).fold<Map<String, dynamic>>(
              {}, (acc, kv) {
        if (kv.length == 2) acc[kv[0]] = double.tryParse(kv[1]);
        return acc;
      }));
      _enabled = (map['enabled'] as double?)?.round() == 1;
      _preamp = map['preamp'] as double? ?? 0.0;
      _bassBoost = map['bass'] as double? ?? 0.25;
      _trebleBoost = map['treble'] as double? ?? 0.15;
      _spatial3d = map['spatial'] as double? ?? 0.30;
      final bands = (map['bands'] as double?) ?? 0.0;
      if (bands > 0 && bands <= 10) {
        _bands.clear();
        for (int i = 0; i < bands.round(); i++) {
          _bands.add(map['b$i'] as double? ?? 0.0);
        }
        while (_bands.length < 10) {
          _bands.add(0.0);
        }
      }
    } catch (e) {
      debugPrint('AudioDspService load error: $e');
    }
  }

  void attachPlayer(AudioPlayer player) {
    _activePlayer = player;
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
    _persist();
    _changeController.add(null);
  }

  /// Reapplies current DSP filters to all active native players (e.g. after track changes)
  void reapply() {
    _applyToNative();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parts = <String>[
        'enabled=${_enabled ? 1 : 0}',
        'preamp=$_preamp',
        'bass=$_bassBoost',
        'treble=$_trebleBoost',
        'spatial=$_spatial3d',
        'bands=${_bands.length}',
      ];
      for (int i = 0; i < _bands.length; i++) {
        parts.add('b$i=${_bands[i]}');
      }
      await prefs.setString(_prefsKey, parts.join('|'));
    } catch (e) {
      debugPrint('AudioDspService persist error: $e');
    }
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

  /// Maps our 10 bands (31–16k) onto the Android 5-band hardware EQ
  /// (60/230/910/3600/14000 Hz), folding the preamp into each gain so boosted
  /// presets don't clip the output stage.
  List<double> _mappedAndroidGains() {
    final pairs = <(double, double)>[
      (_bands[0], _bands[1]), // → 60 Hz
      (_bands[2], _bands[3]), // → 230 Hz
      (_bands[4], _bands[5]), // → 910 Hz
      (_bands[6], _bands[7]), // → 3.6 kHz
      (_bands[8], _bands[9]), // → 14 kHz
    ];
    return pairs
        .map((p) => (p.$1 + p.$2) / 2.0 + _preamp)
        .map((g) => g.clamp(-12.0, 12.0))
        .toList();
  }

  Future<void> _applyAndroidEq() async {
    if (!_hardwareEqSupported) return;
    final eq = _androidEqualizer;
    if (eq == null || _activePlayer == null) return;
    try {
      await eq.setEnabled(_enabled);
      if (!_enabled) return;
      var params = await eq.parameters
          .timeout(const Duration(seconds: 3))
          .catchError((_) => AndroidEqualizerParameters(
                minDecibels: -15,
                maxDecibels: 15,
                bands: const [],
              ));
      final gains = _mappedAndroidGains();
      final minDb = params.minDecibels;
      final maxDb = params.maxDecibels;
      for (int i = 0; i < params.bands.length && i < gains.length; i++) {
        final g = gains[i].clamp(minDb, maxDb);
        await params.bands[i].setGain(g);
      }
    } catch (e) {
      debugPrint('AndroidEqualizer apply note: $e');
    }
  }

  void _applyToNative() {
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        NativeAudioDspEngine.applyMpvFilters(_buildMpvFilterString());
        break;
      case TargetPlatform.android:
        unawaited(_applyAndroidEq());
        break;
      default:
        break; // macOS / iOS / others: no EQ API in just_audio 0.10.x
    }
  }
}