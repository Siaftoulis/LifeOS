import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';

/// An interactive audio waveform seekbar inspired by Poweramp v3.
class WaveformSeekbar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final String trackId;
  final double height;
  final Color activeColor;
  final Color inactiveColor;

  const WaveformSeekbar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.trackId,
    this.height = 48,
    this.activeColor = EverforestColors.green,
    this.inactiveColor = const Color(0x33FFFFFF),
  });

  @override
  State<WaveformSeekbar> createState() => _WaveformSeekbarState();
}

class _WaveformSeekbarState extends State<WaveformSeekbar> {
  bool _isDragging = false;
  double _dragFraction = 0.0;
  List<double> _waveformSamples = [];

  @override
  void initState() {
    super.initState();
    _generateWaveform();
  }

  @override
  void didUpdateWidget(covariant WaveformSeekbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackId != widget.trackId) {
      _generateWaveform();
    }
  }

  void _generateWaveform() {
    // Generate deterministic, natural-looking audio waveform peaks from track ID
    final seed = widget.trackId.hashCode;
    final random = math.Random(seed);
    const int barCount = 70;
    final samples = <double>[];

    double prev = 0.4;
    for (int i = 0; i < barCount; i++) {
      // Create organic audio wave flow with gentle variations and energetic peaks
      final noise = (random.nextDouble() - 0.5) * 0.4;
      final wave = math.sin(i / barCount * math.pi * 3) * 0.25;
      double val = (prev * 0.6 + (0.35 + wave + noise) * 0.4).clamp(0.12, 1.0);
      // Intro and outro fade
      if (i < 5) val *= (i + 1) / 6.0;
      if (i > barCount - 6) val *= (barCount - i) / 6.0;
      samples.add(val.clamp(0.1, 1.0));
      prev = val;
    }
    setState(() {
      _waveformSamples = samples;
    });
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _handleSeek(double dx, double width) {
    final fraction = (dx / width).clamp(0.0, 1.0);
    final targetMs = (fraction * widget.duration.inMilliseconds).round();
    widget.onSeek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final currentMs = widget.duration.inMilliseconds > 0
        ? (_isDragging
            ? (_dragFraction * widget.duration.inMilliseconds).round()
            : widget.position.inMilliseconds.clamp(0, widget.duration.inMilliseconds))
        : 0;

    final progressFraction = widget.duration.inMilliseconds > 0
        ? (_isDragging ? _dragFraction : (currentMs / widget.duration.inMilliseconds)).clamp(0.0, 1.0)
        : 0.0;

    final remaining = widget.duration - Duration(milliseconds: currentMs);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                setState(() {
                  _isDragging = true;
                  _dragFraction = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragFraction = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                });
              },
              onHorizontalDragEnd: (details) {
                final targetMs = (_dragFraction * widget.duration.inMilliseconds).round();
                widget.onSeek(Duration(milliseconds: targetMs));
                setState(() => _isDragging = false);
              },
              onTapDown: (details) {
                _handleSeek(details.localPosition.dx, constraints.maxWidth);
              },
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    samples: _waveformSamples,
                    progress: progressFraction,
                    activeColor: widget.activeColor,
                    inactiveColor: widget.inactiveColor,
                    isDragging: _isDragging,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(Duration(milliseconds: currentMs)),
              style: TextStyle(
                color: _isDragging ? widget.activeColor : EverforestColors.grey,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '-${_formatDuration(remaining)}',
              style: const TextStyle(
                color: EverforestColors.grey,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDragging;

  _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final barWidth = (size.width / samples.length) * 0.65;
    final barSpacing = (size.width / samples.length) * 0.35;
    final totalBarStep = barWidth + barSpacing;

    final centerY = size.height / 2;
    final currentProgressX = progress * size.width;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final activeGlowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.35)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < samples.length; i++) {
      final x = i * totalBarStep + (barWidth / 2);
      final height = samples[i] * (size.height * 0.9);
      final top = centerY - (height / 2);
      final bottom = centerY + (height / 2);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - (barWidth / 2), top, x + (barWidth / 2), bottom),
        Radius.circular(barWidth / 2),
      );

      if (x <= currentProgressX) {
        if (isDragging) {
          canvas.drawRRect(rect, activeGlowPaint);
        }
        canvas.drawRRect(rect, activePaint);
      } else {
        canvas.drawRRect(rect, inactivePaint);
      }
    }

    // Draw scrubber playhead indicator
    if (progress > 0) {
      final playheadPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(
        Offset(currentProgressX, centerY),
        isDragging ? 7.0 : 4.5,
        glowPaint,
      );
      canvas.drawCircle(
        Offset(currentProgressX, centerY),
        isDragging ? 5.0 : 3.0,
        playheadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.samples != samples;
  }
}
