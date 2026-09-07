import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/audio_dsp_service.dart';
import '../../../../theme/app_skin_manager.dart';
import 'equalizer/eq_not_supported_sheet.dart';
import 'equalizer/eq_painters.dart';
import 'equalizer/eq_presets.dart';
import 'equalizer/poweramp_tone_reverb_view.dart';

export 'equalizer/eq_not_supported_sheet.dart';
export 'equalizer/eq_painters.dart';
export 'equalizer/eq_presets.dart';
export 'equalizer/poweramp_tone_reverb_view.dart';

class PowerampEqualizerModal extends StatefulWidget {
  final bool isEmbedded;
  final int initialMode;

  const PowerampEqualizerModal({
    super.key,
    this.isEmbedded = false,
    this.initialMode = 1,
  });

  static void show(BuildContext context, {int initialMode = 1}) {
    final dsp = AudioDspService.instance;
    if (!dsp.isSupportedOnPlatform) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const EqNotSupportedSheet(),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PowerampEqualizerModal(initialMode: initialMode),
    );
  }

  @override
  State<PowerampEqualizerModal> createState() => _PowerampEqualizerModalState();
}

class _PowerampEqualizerModalState extends State<PowerampEqualizerModal> {
  late int _eqMode; // 0 = Sliders EQ, 1 = Tone & Reverb, 2 = Spatial & Limiter
  late bool _eqEnabled;
  late double _preamp;
  late double _bassBoost;
  late double _trebleBoost;
  late double _stereoExpansion;
  late List<double> _bands;
  String _selectedPreset = 'Custom';

  @override
  void initState() {
    super.initState();
    _eqMode = widget.initialMode;
    final dsp = AudioDspService.instance;
    _eqEnabled = dsp.enabled;
    _preamp = dsp.preamp;
    _bassBoost = dsp.bassBoost;
    _trebleBoost = dsp.trebleBoost;
    _stereoExpansion = dsp.spatial3d;
    _bands = List.from(dsp.bands);
    _selectedPreset = _matchPreset(_bands, _preamp, _bassBoost, _trebleBoost);
  }

  String _matchPreset(
      List<double> bands, double preamp, double bass, double treble) {
    for (final p in kEqDefaultPresets) {
      var matches = true;
      for (int i = 0; i < bands.length; i++) {
        if ((p.bands[i] - bands[i]).abs() > 0.15) {
          matches = false;
          break;
        }
      }
      if (matches &&
          (p.preamp - preamp).abs() < 0.3 &&
          (p.bassBoost - bass).abs() < 0.1 &&
          (p.trebleBoost - treble).abs() < 0.1) {
        return p.name;
      }
    }
    return 'Custom';
  }

  void _syncDsp() {
    AudioDspService.instance.updateSettings(
      enabled: _eqEnabled,
      preamp: _preamp,
      bassBoost: _bassBoost,
      trebleBoost: _trebleBoost,
      spatial3d: _stereoExpansion,
      bands: _bands,
    );
  }

  void _applyPreset(EqPreset p) {
    setState(() {
      _selectedPreset = p.name;
      _bands = List.from(p.bands);
      _preamp = p.preamp;
      _bassBoost = p.bassBoost;
      _trebleBoost = p.trebleBoost;
    });
    _syncDsp();
  }

  void _resetEq() {
    setState(() {
      _selectedPreset = 'Flat';
      _bands = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      _preamp = 0.0;
      _bassBoost = 0.0;
      _trebleBoost = 0.0;
      _stereoExpansion = 0.0;
    });
    _syncDsp();
  }

  String _platformName() {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'Windows (libmpv)';
      case TargetPlatform.android:
        return 'Android (ExoPlayer)';
      case TargetPlatform.linux:
        return 'Linux (libmpv)';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.iOS:
        return 'iOS';
      default:
        return 'Native';
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    return Container(
      decoration: BoxDecoration(
        color: skin.bg0,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(widget.isEmbedded ? 0 : 28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isEmbedded) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],

          // Top Poweramp 3-Mode Selector Bar (Screenshot 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: skin.bg1,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                      onTap: () => setState(() => _eqMode = 0),
                      child: Center(
                        child: Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: _eqMode == 0 ? skin.accent : skin.textMuted,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 22, color: Colors.white10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _eqMode = 1),
                      child: Center(
                        child: Icon(
                          Icons.radio_button_checked_rounded,
                          size: 22,
                          color: _eqMode == 1 ? skin.accent : skin.textMuted,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 22, color: Colors.white10),
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
                      onTap: () => setState(() => _eqMode = 2),
                      child: Center(
                        child: Icon(
                          Icons.surround_sound_rounded,
                          size: 24,
                          color: _eqMode == 2 ? skin.accent : skin.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_eqMode == 1)
            const Expanded(child: PowerampToneReverbView())
          else if (_eqMode == 2)
            Expanded(child: _buildSpatialModeView(skin))
          else ...[
            // Studio Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _eqEnabled
                          ? skin.accent.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.equalizer_rounded,
                      color: _eqEnabled ? skin.accent : skin.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'POWERAMP EQUALIZER',
                          style: TextStyle(
                            color: skin.fg,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${_platformName()} · ${_eqEnabled ? "DSP Active" : "Bypass Mode"}',
                          style: TextStyle(
                            color: _eqEnabled ? skin.green : skin.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _eqEnabled,
                    activeThumbColor: skin.accent,
                    onChanged: (val) {
                      setState(() => _eqEnabled = val);
                      _syncDsp();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        color: skin.textMuted, size: 20),
                    tooltip: 'Reset EQ',
                    onPressed: _resetEq,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Presets Horizontal Selector
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: kEqDefaultPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final p = kEqDefaultPresets[i];
                final isSelected = _selectedPreset == p.name;
                return ChoiceChip(
                  label: Text(p.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) _applyPreset(p);
                  },
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (skin.isDark ? Colors.black : Colors.white)
                        : skin.fg,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  selectedColor: skin.accent,
                  backgroundColor: skin.bg1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? skin.accent : Colors.white12,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Real-time Curve Spectrum Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: skin.bg1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: CustomPaint(
                painter: EqCurvePainter(
                  bands: _bands,
                  enabled: _eqEnabled,
                  curveColor: skin.accent,
                  glowColor: skin.accent.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 10-Band Vertical Sliders Grid
          Expanded(
            child: Opacity(
              opacity:
                  (_eqEnabled && AudioDspService.instance.isSupportedOnPlatform)
                      ? 1.0
                      : 0.4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(10, (index) {
                    return _buildBandColumn(index, skin);
                  }),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Poweramp DSP Tone Knobs
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            decoration: BoxDecoration(
              color: skin.bg1,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(widget.isEmbedded ? 0 : 24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDspRotary(
                  label: 'PREAMP',
                  fraction: ((_preamp + 12.0) / 24.0).clamp(0.0, 1.0),
                  displayValue: '${_preamp >= 0 ? '+' : ''}${_preamp.toStringAsFixed(1)}dB',
                  activeColor: skin.blue,
                  skin: skin,
                  onDelta: _eqEnabled
                      ? (d) {
                          setState(() {
                            _preamp = (_preamp + d * 24.0).clamp(-12.0, 12.0);
                            _preamp = (_preamp * 10).round() / 10.0;
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onIncrement: _eqEnabled
                      ? () {
                          setState(() {
                            _preamp = (_preamp + 0.5).clamp(-12.0, 12.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onDecrement: _eqEnabled
                      ? () {
                          setState(() {
                            _preamp = (_preamp - 0.5).clamp(-12.0, 12.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onReset: _eqEnabled
                      ? () {
                          setState(() {
                            _preamp = 0.0;
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                ),
                _buildDspRotary(
                  label: 'BASS BOOST',
                  fraction: _bassBoost,
                  displayValue: '${(_bassBoost * 100).round()}%',
                  activeColor: skin.yellow,
                  skin: skin,
                  onDelta: _eqEnabled
                      ? (d) {
                          setState(() {
                            _bassBoost = (_bassBoost + d).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onIncrement: _eqEnabled
                      ? () {
                          setState(() {
                            _bassBoost = (_bassBoost + 0.05).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onDecrement: _eqEnabled
                      ? () {
                          setState(() {
                            _bassBoost = (_bassBoost - 0.05).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onReset: _eqEnabled
                      ? () {
                          setState(() {
                            _bassBoost = 0.0;
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                ),
                _buildDspRotary(
                  label: 'TREBLE (HIGHS)',
                  fraction: _trebleBoost,
                  displayValue: '${(_trebleBoost * 100).round()}%',
                  activeColor: skin.aqua,
                  skin: skin,
                  onDelta: _eqEnabled
                      ? (d) {
                          setState(() {
                            _trebleBoost = (_trebleBoost + d).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onIncrement: _eqEnabled
                      ? () {
                          setState(() {
                            _trebleBoost = (_trebleBoost + 0.05).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onDecrement: _eqEnabled
                      ? () {
                          setState(() {
                            _trebleBoost = (_trebleBoost - 0.05).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onReset: _eqEnabled
                      ? () {
                          setState(() {
                            _trebleBoost = 0.0;
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                ),
                _buildDspRotary(
                  label: 'SPATIAL 3D',
                  fraction: _stereoExpansion,
                  displayValue: '${(_stereoExpansion * 100).round()}%',
                  activeColor: skin.purple,
                  skin: skin,
                  onDelta: _eqEnabled
                      ? (d) {
                          setState(() {
                            _stereoExpansion = (_stereoExpansion + d).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onIncrement: _eqEnabled
                      ? () {
                          setState(() {
                            _stereoExpansion = (_stereoExpansion + 0.05).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onDecrement: _eqEnabled
                      ? () {
                          setState(() {
                            _stereoExpansion = (_stereoExpansion - 0.05).clamp(0.0, 1.0);
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                  onReset: _eqEnabled
                      ? () {
                          setState(() {
                            _stereoExpansion = 0.0;
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpatialModeView(AppSkin skin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: skin.bg1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.surround_sound_rounded, color: skin.accent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SPATIAL 3D SOUNDSTAGE',
                            style: TextStyle(
                              color: skin.fg,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Stereo field width & ambient acoustic immersion',
                            style: TextStyle(color: skin.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(_stereoExpansion * 100).round()}%',
                      style: TextStyle(
                        color: skin.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: KnobDialPainter(
                      fraction: _stereoExpansion,
                      color: skin.accent,
                      backgroundColor: skin.isOled ? const Color(0xFF141414) : skin.bg2,
                      showTicks: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    activeTrackColor: skin.accent,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: skin.accent,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _stereoExpansion,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) {
                      setState(() => _stereoExpansion = v);
                      _syncDsp();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: skin.bg1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      Text('BASS BOOST', style: TextStyle(color: skin.fg, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${(_bassBoost * 100).round()}%', style: TextStyle(color: skin.yellow, fontSize: 14, fontWeight: FontWeight.bold)),
                      Slider(
                        value: _bassBoost,
                        activeColor: skin.yellow,
                        inactiveColor: Colors.white12,
                        onChanged: (v) {
                          setState(() => _bassBoost = v);
                          _syncDsp();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: skin.bg1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      Text('TREBLE AIR', style: TextStyle(color: skin.fg, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${(_trebleBoost * 100).round()}%', style: TextStyle(color: skin.aqua, fontSize: 14, fontWeight: FontWeight.bold)),
                      Slider(
                        value: _trebleBoost,
                        activeColor: skin.aqua,
                        inactiveColor: Colors.white12,
                        onChanged: (v) {
                          setState(() => _trebleBoost = v);
                          _syncDsp();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: skin.bg1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: skin.green, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audiophile Limiter & Headroom Guard',
                        style: TextStyle(color: skin.fg, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Active - prevents digital clipping and distortion at high gains',
                        style: TextStyle(color: skin.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBandColumn(int index, AppSkin skin) {
    final value = _bands[index];
    final isBoosted = value.abs() > 0.1;
    return Column(
      children: [
        Text(
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}',
          style: TextStyle(
            color: isBoosted ? skin.accent : skin.textMuted,
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.0,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
                activeTrackColor: skin.accent,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value,
                min: -12.0,
                max: 12.0,
                onChanged: _eqEnabled
                    ? (v) {
                        setState(() {
                          _bands[index] = (v * 10).round() / 10.0;
                          _selectedPreset = 'Custom';
                        });
                        _syncDsp();
                      }
                    : null,
              ),
            ),
          ),
        ),
        Text(
          kEqBandFrequencies[index],
          style: TextStyle(
            color: skin.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDspRotary({
    required String label,
    required double fraction,
    required String displayValue,
    required Color activeColor,
    required AppSkin skin,
    ValueChanged<double>? onDelta,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
    VoidCallback? onReset,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onDoubleTap: onReset,
          onPanUpdate: (details) {
            if (onDelta == null) return;
            final delta = (-details.delta.dy + details.delta.dx) / 100.0;
            onDelta(delta);
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: fraction > 0 ? 0.22 : 0.0),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(56, 56),
                  painter: KnobDialPainter(
                    fraction: fraction,
                    color: activeColor,
                    backgroundColor: skin.bg2,
                    showTicks: true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: skin.bg0.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      color: skin.fg,
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Icon(Icons.remove, size: 13, color: skin.textMuted),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: skin.textMuted,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Icon(Icons.add, size: 13, color: skin.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
