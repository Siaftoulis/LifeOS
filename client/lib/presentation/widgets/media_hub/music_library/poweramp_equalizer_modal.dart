import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/audio_dsp_service.dart';
import '../../../../theme/everforest_colors.dart';
import 'equalizer/eq_not_supported_sheet.dart';
import 'equalizer/eq_painters.dart';
import 'equalizer/eq_presets.dart';

export 'equalizer/eq_not_supported_sheet.dart';
export 'equalizer/eq_painters.dart';
export 'equalizer/eq_presets.dart';

class PowerampEqualizerModal extends StatefulWidget {
  final bool isEmbedded;

  const PowerampEqualizerModal({super.key, this.isEmbedded = false});

  static void show(BuildContext context) {
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
      builder: (_) => const PowerampEqualizerModal(),
    );
  }

  @override
  State<PowerampEqualizerModal> createState() => _PowerampEqualizerModalState();
}

class _PowerampEqualizerModalState extends State<PowerampEqualizerModal> {
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
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: widget.isEmbedded ? null : size.height * 0.88,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: widget.isEmbedded
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: widget.isEmbedded
            ? null
            : const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 40,
                  offset: Offset(0, -10),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isEmbedded) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 48,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 12),
          ],

          // Header: Title, EQ Power Switch, Reset
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _eqEnabled
                        ? EverforestColors.green.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.equalizer_rounded,
                    color: _eqEnabled
                        ? EverforestColors.green
                        : EverforestColors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GRAPHIC EQUALIZER',
                        style: TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _eqEnabled
                            ? '10-Band Studio DSP Active'
                            : 'DSP Bypass Mode',
                        style: TextStyle(
                          color: _eqEnabled
                              ? EverforestColors.green
                              : EverforestColors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AudioDspService.instance.isSupportedOnPlatform
                            ? 'Platform: ${_platformName()} · DSP Active'
                            : 'Platform: ${_platformName()} · EQ Not Supported',
                        style: TextStyle(
                          color: AudioDspService.instance.isSupportedOnPlatform
                              ? EverforestColors.green
                              : EverforestColors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _eqEnabled,
                  activeThumbColor: EverforestColors.green,
                  onChanged: (val) {
                    setState(() => _eqEnabled = val);
                    _syncDsp();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: EverforestColors.grey, size: 20),
                  tooltip: 'Reset EQ',
                  onPressed: _resetEq,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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
                    color:
                        isSelected ? EverforestColors.bg0 : EverforestColors.fg,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  selectedColor: EverforestColors.green,
                  backgroundColor: EverforestColors.bg1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color:
                          isSelected ? EverforestColors.green : Colors.white12,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Real-time Curve Spectrum Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: EverforestColors.bg1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: CustomPaint(
                painter: EqCurvePainter(
                  bands: _bands,
                  enabled: _eqEnabled,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

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
                    return _buildBandColumn(index);
                  }),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bottom DSP Knobs: Bass Boost, Treble Boost, Stereo Spatializer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: BoxDecoration(
              color: EverforestColors.bg1,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(widget.isEmbedded ? 0 : 24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDspRotary(
                  label: 'BASS BOOST',
                  value: _bassBoost,
                  activeColor: EverforestColors.yellow,
                  onChanged: _eqEnabled
                      ? (v) {
                          setState(() {
                            _bassBoost = v;
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                ),
                _buildDspRotary(
                  label: 'TREBLE BOOST',
                  value: _trebleBoost,
                  activeColor: EverforestColors.aqua,
                  onChanged: _eqEnabled
                      ? (v) {
                          setState(() {
                            _trebleBoost = v;
                            _selectedPreset = 'Custom';
                          });
                          _syncDsp();
                        }
                      : null,
                ),
                _buildDspRotary(
                  label: 'SPATIAL 3D',
                  value: _stereoExpansion,
                  activeColor: EverforestColors.purple,
                  onChanged: _eqEnabled
                      ? (v) {
                          setState(() {
                            _stereoExpansion = v;
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
      ),
    );
  }

  Widget _buildBandColumn(int index) {
    final value = _bands[index];
    return Column(
      children: [
        Text(
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}',
          style: TextStyle(
            color: value.abs() > 0.1
                ? EverforestColors.green
                : EverforestColors.grey,
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
                    const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: EverforestColors.green,
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
          style: const TextStyle(
            color: EverforestColors.grey,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDspRotary({
    required String label,
    required double value,
    required Color activeColor,
    ValueChanged<double>? onChanged,
  }) {
    final pct = (value * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onVerticalDragUpdate: (details) {
            if (onChanged == null) return;
            final delta = -details.primaryDelta! / 100.0;
            final newVal = (value + delta).clamp(0.0, 1.0);
            onChanged(newVal);
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: EverforestColors.bg0,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: value > 0 ? 0.25 : 0.0),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(52, 52),
                  painter: KnobDialPainter(
                    fraction: value,
                    color: activeColor,
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: EverforestColors.grey,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
