import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../theme/everforest_colors.dart';

/// Dynamic Audio-Reactive Spectrogram Painter
class AudioReactiveSpectrogramPainter extends CustomPainter {
  final Duration position;
  final String trackId;
  final bool playing;
  final List<double> peakCaps;
  final List<double> capVelocities;
  final List<double> dspGains;
  final double bassBoost;

  AudioReactiveSpectrogramPainter({
    required this.position,
    required this.trackId,
    required this.playing,
    required this.peakCaps,
    required this.capVelocities,
    required this.dspGains,
    required this.bassBoost,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int barCount = 28;
    final barWidth = size.width / (barCount * 1.55);
    final totalStep = size.width / barCount;
    final bottomY = size.height * 0.88;
    final maxHeight = size.height * 0.75;

    final idSeed = trackId.hashCode.abs();
    final elapsedMs = position.inMilliseconds;
    const beatTempo = 120.0;
    const beatIntervalMs = (60000.0 / beatTempo);
    final beatPhase = (elapsedMs % beatIntervalMs) / beatIntervalMs;
    final beatPulse = math.exp(-beatPhase * 4.0);

    final barPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          EverforestColors.yellow,
          EverforestColors.aqua,
          EverforestColors.green,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final capPaint = Paint()
      ..color = EverforestColors.yellow
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final x = i * totalStep + (barWidth / 2);
      double targetHeight = size.height * 0.05;

      if (playing) {
        final isBass = i < 8;
        final isMid = i >= 8 && i < 19;

        final freqGain = (i < dspGains.length ? dspGains[i] : 0.0) / 12.0;
        final freqMultiplier = (1.0 + freqGain).clamp(0.2, 1.8);

        final noiseOffset = math.sin((elapsedMs * 0.008) + (i * 0.6) + (idSeed % 17));
        final harmonicOffset = math.cos((elapsedMs * 0.015) + (i * 1.2));

        if (isBass) {
          final bassFactor = (1.0 + bassBoost * 0.8);
          targetHeight = maxHeight * (0.25 + 0.65 * beatPulse * bassFactor + 0.15 * noiseOffset);
        } else if (isMid) {
          targetHeight = maxHeight * (0.20 + 0.45 * math.max(0, noiseOffset) + 0.25 * beatPulse * 0.4 + 0.15 * harmonicOffset);
        } else {
          final flutter = math.sin((elapsedMs * 0.025) + (i * 2.1)).abs();
          targetHeight = maxHeight * (0.15 + 0.50 * flutter + 0.20 * math.max(0, harmonicOffset));
        }

        targetHeight = (targetHeight * freqMultiplier).clamp(size.height * 0.06, maxHeight);
      }

      if (targetHeight > peakCaps[i]) {
        peakCaps[i] = targetHeight;
        capVelocities[i] = 0.0;
      } else {
        capVelocities[i] += 0.8;
        peakCaps[i] = (peakCaps[i] - capVelocities[i]).clamp(size.height * 0.05, maxHeight);
      }

      final topY = bottomY - targetHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - (barWidth / 2),
          topY,
          x + (barWidth / 2),
          bottomY,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, barPaint);

      final capTopY = bottomY - peakCaps[i] - 4;
      final capRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - (barWidth / 2),
          capTopY - 2.5,
          x + (barWidth / 2),
          capTopY,
        ),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(capRect, capPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AudioReactiveSpectrogramPainter oldDelegate) {
    return true;
  }
}
