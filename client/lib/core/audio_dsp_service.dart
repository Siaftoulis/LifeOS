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

  // Poweramp 1:1 Tone & Reverb parameters
  bool _reverbEnabled = false;
  double _reverbDamp = 0.41;
  double _reverbFilter = 0.70;
  double _reverbFade = 0.50;
  double _reverbPreDelay = 0.12;
  double _reverbPreDelayMix = 0.43;
  double _reverbSize = 0.24;
  double _reverbMix = 0.56;
  String _reverbPreset = 'Small Room';

  static const Map<String, ({double damp, double filter, double fade, double preDelay, double preDelayMix, double size, double mix})> kReverbPresets = {
    'Small Room': (damp: 0.41, filter: 0.70, fade: 0.50, preDelay: 0.12, preDelayMix: 0.43, size: 0.24, mix: 0.56),
    'Medium Room': (damp: 0.50, filter: 0.65, fade: 0.60, preDelay: 0.20, preDelayMix: 0.50, size: 0.45, mix: 0.50),
    'Large Hall': (damp: 0.35, filter: 0.80, fade: 0.75, preDelay: 0.35, preDelayMix: 0.60, size: 0.75, mix: 0.60),
    'Cathedral': (damp: 0.20, filter: 0.85, fade: 0.90, preDelay: 0.50, preDelayMix: 0.70, size: 0.95, mix: 0.70),
    'Plate': (damp: 0.70, filter: 0.50, fade: 0.40, preDelay: 0.05, preDelayMix: 0.30, size: 0.30, mix: 0.45),
    'Studio': (damp: 0.60, filter: 0.75, fade: 0.35, preDelay: 0.08, preDelayMix: 0.35, size: 0.20, mix: 0.40),
  };

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

  bool get reverbEnabled => _reverbEnabled;
  double get reverbDamp => _reverbDamp;
  double get reverbFilter => _reverbFilter;
  double get reverbFade => _reverbFade;
  double get reverbPreDelay => _reverbPreDelay;
  double get reverbPreDelayMix => _reverbPreDelayMix;
  double get reverbSize => _reverbSize;
  double get reverbMix => _reverbMix;
  String get reverbPreset => _reverbPreset;

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
      _reverbEnabled = (map['rv_en'] as double?)?.round() == 1;
      _reverbDamp = map['rv_damp'] as double? ?? 0.41;
      _reverbFilter = map['rv_filter'] as double? ?? 0.70;
      _reverbFade = map['rv_fade'] as double? ?? 0.50;
      _reverbPreDelay = map['rv_pdel'] as double? ?? 0.12;
      _reverbPreDelayMix = map['rv_pdmix'] as double? ?? 0.43;
      _reverbSize = map['rv_size'] as double? ?? 0.24;
      _reverbMix = map['rv_mix'] as double? ?? 0.56;

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
    bool? reverbEnabled,
    double? reverbDamp,
    double? reverbFilter,
    double? reverbFade,
    double? reverbPreDelay,
    double? reverbPreDelayMix,
    double? reverbSize,
    double? reverbMix,
    String? reverbPreset,
  }) {
    if (enabled != null) _enabled = enabled;
    if (preamp != null) _preamp = preamp;
    if (bassBoost != null) _bassBoost = bassBoost;
    if (trebleBoost != null) _trebleBoost = trebleBoost;
    if (spatial3d != null) _spatial3d = spatial3d;
    if (bands != null) _bands = List.from(bands);

    if (reverbEnabled != null) _reverbEnabled = reverbEnabled;
    if (reverbDamp != null) _reverbDamp = reverbDamp.clamp(0.0, 1.0);
    if (reverbFilter != null) _reverbFilter = reverbFilter.clamp(0.0, 1.0);
    if (reverbFade != null) _reverbFade = reverbFade.clamp(0.0, 1.0);
    if (reverbPreDelay != null) _reverbPreDelay = reverbPreDelay.clamp(0.0, 1.0);
    if (reverbPreDelayMix != null) _reverbPreDelayMix = reverbPreDelayMix.clamp(0.0, 1.0);
    if (reverbSize != null) _reverbSize = reverbSize.clamp(0.0, 1.0);
    if (reverbMix != null) _reverbMix = reverbMix.clamp(0.0, 1.0);
    if (reverbPreset != null) _reverbPreset = reverbPreset;

    _applyToNative();
    _persist();
    _changeController.add(null);
  }

  /// Applies a named reverb preset
  void applyReverbPreset(String name) {
    final p = kReverbPresets[name];
    if (p == null) return;
    updateSettings(
      reverbPreset: name,
      reverbDamp: p.damp,
      reverbFilter: p.filter,
      reverbFade: p.fade,
      reverbPreDelay: p.preDelay,
      reverbPreDelayMix: p.preDelayMix,
      reverbSize: p.size,
      reverbMix: p.mix,
    );
  }

  void setReverbEnabled(bool val) => updateSettings(reverbEnabled: val);

  void resetReverb() => updateSettings(
        reverbEnabled: false,
        reverbDamp: 0.5,
        reverbFilter: 0.5,
        reverbFade: 0.5,
        reverbPreDelay: 0.1,
        reverbPreDelayMix: 0.3,
        reverbSize: 0.5,
        reverbMix: 0.0,
        reverbPreset: 'Default',
      );

  String buildMpvFilterString() => _buildMpvFilterString();

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
        'rv_en=${_reverbEnabled ? 1 : 0}',
        'rv_damp=$_reverbDamp',
        'rv_filter=$_reverbFilter',
        'rv_fade=$_reverbFade',
        'rv_pdel=$_reverbPreDelay',
        'rv_pdmix=$_reverbPreDelayMix',
        'rv_size=$_reverbSize',
        'rv_mix=$_reverbMix',
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

    // 1. Preamp Volume (-12dB to +12dB)
    if (_preamp.abs() > 0.05) {
      filters.add('volume=volume=${_preamp.clamp(-12.0, 12.0).toStringAsFixed(1)}dB');
    }

    // 2. Poweramp-style Bass Boost (centered at 80Hz with 0.7 Q width for deep punchy low-end)
    if (_bassBoost > 0.01) {
      final bassGainDb = _bassBoost * 18.0; // up to +18 dB
      filters.add('bass=g=${bassGainDb.toStringAsFixed(1)}:f=80:w=0.7');
    }

    // 3. Poweramp-style Treble Sparkle (centered at 10000Hz for crystalline presence and air)
    if (_trebleBoost > 0.01) {
      final trebleGainDb = _trebleBoost * 18.0; // up to +18 dB
      filters.add('treble=g=${trebleGainDb.toStringAsFixed(1)}:f=10000:w=0.7');
    }

    // 4. 3D Spatial Audio / Stereo Soundstage expansion
    if (_spatial3d > 0.01) {
      final m = 1.0 + (_spatial3d * 2.5);
      filters.add('stereotools=slev=${m.toStringAsFixed(2)}');
    }

    // 5. 10-Band Parametric/Graphic Equalizer
    const freqs = [31.25, 62.5, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0];
    for (int i = 0; i < _bands.length && i < freqs.length; i++) {
      final gain = _bands[i];
      if (gain.abs() > 0.1) {
        filters.add('equalizer=f=${freqs[i]}:width_type=q:w=1.414:g=${gain.toStringAsFixed(1)}');
      }
    }

    // 6. Poweramp-style Reverb & Spatial Reflections
    if (_reverbEnabled && _reverbMix > 0.01) {
      final room = _reverbSize.clamp(0.05, 1.0).toStringAsFixed(2);
      final damp = _reverbDamp.clamp(0.0, 1.0).toStringAsFixed(2);
      final wet = _reverbMix.clamp(0.05, 1.0).toStringAsFixed(2);
      final dry = (1.0 - (_reverbMix * 0.5)).clamp(0.1, 1.0).toStringAsFixed(2);
      filters.add('freeverb=roomsize=$room:damping=$damp:wet=$wet:dry=$dry');
    }

    // 7. Dynamic Audiophile Limiter / Headroom Guard (eliminates clipping & crackle)
    filters.add('alimiter=limit=0.98:attack=5:release=50');

    if (filters.isEmpty) return '';
    return 'lavfi=[${filters.join(',')}]';
  }

  /// Maps our 10 bands + tone controls onto the Android 5-band hardware EQ
  /// (60/230/910/3600/14000 Hz), integrating Bass & Treble boost and Preamp.
  List<double> _mappedAndroidGains() {
    final bassGain = _bassBoost * 12.0;
    final trebleGain = _trebleBoost * 12.0;

    final pairs = <(double, double)>[
      (_bands[0] + bassGain, _bands[1] + bassGain * 0.8), // → 60 Hz (Sub + Low Bass)
      (_bands[2] + bassGain * 0.4, _bands[3]),            // → 230 Hz (Punchy Bass)
      (_bands[4], _bands[5]),                              // → 910 Hz (Mids)
      (_bands[6], _bands[7] + trebleGain * 0.5),          // → 3.6 kHz (High-mids)
      (_bands[8] + trebleGain * 0.8, _bands[9] + trebleGain), // → 14 kHz (Air/Highs)
    ];
    return pairs
        .map((p) => (p.$1 + p.$2) / 2.0 + _preamp)
        .map((g) => g.clamp(-15.0, 15.0))
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