import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/audio_dsp_service.dart';

/// Preset configurations for Poweramp Equalizer
class EqPreset {
  final String name;
  final List<double> bands; // 10 bands from 31Hz to 16kHz (-12.0 to +12.0 dB)
  final double preamp;
  final double bassBoost;
  final double trebleBoost;

  const EqPreset({
    required this.name,
    required this.bands,
    this.preamp = 0.0,
    this.bassBoost = 0.0,
    this.trebleBoost = 0.0,
  });
}

class PowerampEqualizerModal extends StatefulWidget {
  final bool isEmbedded;

  const PowerampEqualizerModal({super.key, this.isEmbedded = false});

  static void show(BuildContext context) {
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

  static const List<String> _bandFrequencies = [
    '31',
    '62',
    '125',
    '250',
    '500',
    '1k',
    '2k',
    '4k',
    '8k',
    '16k',
  ];

  final List<EqPreset> _presets = const [
    EqPreset(
      name: 'Flat',
      bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      preamp: 0.0,
      bassBoost: 0.0,
      trebleBoost: 0.0,
    ),
    EqPreset(
      name: 'Bass Boost / EDM',
      bands: [8.5, 7.0, 5.0, 2.0, 0.0, -1.0, 1.5, 3.0, 5.5, 6.0],
      preamp: -2.0,
      bassBoost: 0.7,
      trebleBoost: 0.2,
    ),
    EqPreset(
      name: 'Rock & Metal',
      bands: [5.0, 3.5, 2.0, 0.5, -1.0, 1.0, 3.0, 5.0, 6.5, 7.0],
      preamp: -1.5,
      bassBoost: 0.4,
      trebleBoost: 0.4,
    ),
    EqPreset(
      name: 'Vocal & Clarity',
      bands: [-2.0, -1.0, 0.5, 2.0, 4.5, 5.0, 4.0, 2.5, 1.0, 0.0],
      preamp: 0.0,
      bassBoost: 0.1,
      trebleBoost: 0.3,
    ),
    EqPreset(
      name: 'Audiophile Reference',
      bands: [1.5, 1.0, 0.5, 0.0, 0.0, 0.5, 1.0, 1.5, 2.0, 2.5],
      preamp: 0.0,
      bassBoost: 0.15,
      trebleBoost: 0.15,
    ),
    EqPreset(
      name: 'Electronic / Club',
      bands: [7.0, 5.5, 3.0, 0.0, -1.5, 2.0, 4.0, 6.0, 7.0, 7.5],
      preamp: -2.0,
      bassBoost: 0.6,
      trebleBoost: 0.5,
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: widget.isEmbedded ? null : size.height * 0.88,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: widget.isEmbedded ? BorderRadius.circular(24) : const BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: _eqEnabled ? EverforestColors.green : EverforestColors.grey,
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
                        _eqEnabled ? '10-Band Studio DSP Active' : 'DSP Bypass Mode',
                        style: TextStyle(
                          color: _eqEnabled ? EverforestColors.green : EverforestColors.grey,
                          fontSize: 11,
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
                  icon: const Icon(Icons.refresh_rounded, color: EverforestColors.grey, size: 20),
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
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final p = _presets[i];
                final isSelected = _selectedPreset == p.name;
                return ChoiceChip(
                  label: Text(p.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) _applyPreset(p);
                  },
                  labelStyle: TextStyle(
                    color: isSelected ? EverforestColors.bg0 : EverforestColors.fg,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  selectedColor: EverforestColors.green,
                  backgroundColor: EverforestColors.bg1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? EverforestColors.green : Colors.white12,
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
                painter: _EqCurvePainter(
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
              opacity: _eqEnabled ? 1.0 : 0.4,
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(widget.isEmbedded ? 0 : 24)),
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
            color: value.abs() > 0.1 ? EverforestColors.green : EverforestColors.grey,
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
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
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
          _bandFrequencies[index],
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
                  painter: _KnobDialPainter(
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

class _EqCurvePainter extends CustomPainter {
  final List<double> bands;
  final bool enabled;

  _EqCurvePainter({required this.bands, required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    final centerY = size.height / 2;
    const maxGain = 12.0;

    final refPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), refPaint);

    final path = Path();
    final step = size.width / (bands.length - 1);

    for (int i = 0; i < bands.length; i++) {
      final x = i * step;
      final gainRatio = (bands[i] / maxGain).clamp(-1.0, 1.0);
      final y = centerY - (gainRatio * (size.height * 0.42));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * step;
        final prevGainRatio = (bands[i - 1] / maxGain).clamp(-1.0, 1.0);
        final prevY = centerY - (prevGainRatio * (size.height * 0.42));
        final cX = (prevX + x) / 2;
        path.cubicTo(cX, prevY, cX, y, x, y);
      }
    }

    final curvePaint = Paint()
      ..color = enabled ? EverforestColors.green : EverforestColors.grey
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = enabled ? EverforestColors.green.withValues(alpha: 0.4) : Colors.transparent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant _EqCurvePainter oldDelegate) {
    return oldDelegate.bands != bands || oldDelegate.enabled != enabled;
  }
}

class _KnobDialPainter extends CustomPainter {
  final double fraction;
  final Color color;

  _KnobDialPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    const startAngle = 0.75 * math.pi;
    const sweepTotal = 1.5 * math.pi;

    final trackPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * fraction,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KnobDialPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.color != color;
  }
}
