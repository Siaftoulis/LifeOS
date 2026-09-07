import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../theme/app_skin_manager.dart';

/// Supported visualizer display modes
enum AudioVisualizerStyle {
  bars, // Neon Spectrum Columns with Floating Peak Caps
  beam, // Oscilloscope Fluorescent Electron Beam
  halo, // Radial Cyber Frequency Halo
  vu, // Vintage Studio Analog VU Meter
}

/// Dynamic Audio-Reactive Multi-Mode Visualizer Painter
class AudioReactiveSpectrogramPainter extends CustomPainter {
  final Duration position;
  final String trackId;
  final bool playing;
  final List<double> peakCaps;
  final List<double> capVelocities;
  final List<double> dspGains;
  final double bassBoost;
  final AudioVisualizerStyle style;
  final AppSkin? skin;

  AppSkin get _s => skin ?? AppSkinManager.currentSkin;

  AudioReactiveSpectrogramPainter({
    required this.position,
    required this.trackId,
    required this.playing,
    required this.peakCaps,
    required this.capVelocities,
    required this.dspGains,
    required this.bassBoost,
    this.style = AudioVisualizerStyle.bars,
    this.skin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case AudioVisualizerStyle.bars:
        _paintBars(canvas, size);
        break;
      case AudioVisualizerStyle.beam:
        _paintBeam(canvas, size);
        break;
      case AudioVisualizerStyle.halo:
        _paintHalo(canvas, size);
        break;
      case AudioVisualizerStyle.vu:
        _paintVu(canvas, size);
        break;
    }
  }

  // ------------------------------------------------------------- 1. Bars
  void _paintBars(Canvas canvas, Size size) {
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

    final colorTop = _s.yellow;
    final colorMid = _s.accent;
    final colorBot = _s.green;

    final barPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colorTop, colorMid, colorBot],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final capPaint = Paint()
      ..color = colorTop
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
          targetHeight = maxHeight *
              (0.20 + 0.45 * math.max(0, noiseOffset) + 0.25 * beatPulse * 0.4 + 0.15 * harmonicOffset);
        } else {
          final flutter = math.sin((elapsedMs * 0.025) + (i * 2.1)).abs();
          targetHeight = maxHeight * (0.15 + 0.50 * flutter + 0.20 * math.max(0, harmonicOffset));
        }

        targetHeight = (targetHeight * freqMultiplier).clamp(size.height * 0.06, maxHeight);
      }

      if (i < peakCaps.length && i < capVelocities.length) {
        if (targetHeight > peakCaps[i]) {
          peakCaps[i] = targetHeight;
          capVelocities[i] = 0.0;
        } else {
          capVelocities[i] += 0.8;
          peakCaps[i] = (peakCaps[i] - capVelocities[i]).clamp(size.height * 0.05, maxHeight);
        }
      }

      final topY = bottomY - targetHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - (barWidth / 2), topY, x + (barWidth / 2), bottomY),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, barPaint);

      final currentPeak = (i < peakCaps.length) ? peakCaps[i] : targetHeight;
      final capTopY = bottomY - currentPeak - 4;
      final capRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - (barWidth / 2), capTopY - 2.5, x + (barWidth / 2), capTopY),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(capRect, capPaint);
    }
  }

  // ------------------------------------------------------------- 2. Beam (Oscilloscope)
  void _paintBeam(Canvas canvas, Size size) {
    final centerY = size.height * 0.5;
    final elapsedMs = position.inMilliseconds;
    final accentColor = _s.accent;
    final glowColor = _s.accentSecondary;

    // Reticle Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    for (int y = -2; y <= 2; y++) {
      final lineY = centerY + (y * (size.height * 0.18));
      canvas.drawLine(Offset(10, lineY), Offset(size.width - 10, lineY), gridPaint);
    }
    for (int x = 1; x <= 5; x++) {
      final lineX = (size.width / 6) * x;
      canvas.drawLine(Offset(lineX, 20), Offset(lineX, size.height - 20), gridPaint);
    }

    // Baseline axis
    final centerAxisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), centerAxisPaint);

    if (!playing) {
      // Idle straight neon beam
      final idleGlow = Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      final idleCore = Paint()
        ..color = accentColor
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), idleGlow);
      canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), idleCore);
      return;
    }

    const int steps = 64;
    final stepX = size.width / steps;
    final path = Path();
    final reflectionPath = Path();

    const beatIntervalMs = (60000.0 / 120.0);
    final beatPhase = (elapsedMs % beatIntervalMs) / beatIntervalMs;
    final beatPulse = math.exp(-beatPhase * 4.0);
    final maxAmp = size.height * 0.38 * (1.0 + (bassBoost * 0.6));

    for (int i = 0; i <= steps; i++) {
      final x = i * stepX;
      final t = i / steps;
      final envelope = math.sin(t * math.pi); // Taper at the edges

      final harmonic1 = math.sin((elapsedMs * 0.012) + (i * 0.22));
      final harmonic2 = math.cos((elapsedMs * 0.024) + (i * 0.44)) * 0.45;
      final bassWave = math.sin((elapsedMs * 0.006) + (i * 0.10)) * (beatPulse * 0.8);

      final yOffset = (harmonic1 + harmonic2 + bassWave) * maxAmp * envelope;
      final y = centerY + yOffset;
      final refY = centerY - (yOffset * 0.45);

      if (i == 0) {
        path.moveTo(x, y);
        reflectionPath.moveTo(x, refY);
      } else {
        path.lineTo(x, y);
        reflectionPath.lineTo(x, refY);
      }
    }

    // Outer glow
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.35)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);

    // Reflection
    final refPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(reflectionPath, refPaint);

    // Neon laser beam
    final corePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);

    // Center electron filament
    final filamentPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, filamentPaint);
  }

  // ------------------------------------------------------------- 3. Halo (Radial)
  void _paintHalo(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDimension = math.min(size.width, size.height);
    final innerRadius = minDimension * 0.24;
    final maxRayHeight = minDimension * 0.22;
    final elapsedMs = position.inMilliseconds;

    final accent = _s.accent;
    final secondary = _s.yellow;

    const beatIntervalMs = (60000.0 / 120.0);
    final beatPhase = (elapsedMs % beatIntervalMs) / beatIntervalMs;
    final beatPulse = math.exp(-beatPhase * 4.0);

    // Center pulsating orb
    final pulseScale = 1.0 + (playing ? (beatPulse * 0.08 * (1.0 + bassBoost)) : 0.0);
    final currentInnerRadius = innerRadius * pulseScale;

    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: playing ? 0.35 : 0.15),
          secondary.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: currentInnerRadius));
    canvas.drawCircle(center, currentInnerRadius, centerPaint);

    // Inner bounding ring
    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, currentInnerRadius, ringPaint);

    // 40 Radial audio rays
    const int rayCount = 40;
    final rotationOffset = elapsedMs * 0.0003;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * (2 * math.pi / rayCount)) + rotationOffset;

      double rayHeight = 4.0;
      if (playing) {
        final harmonic = math.sin((elapsedMs * 0.01) + (i * 0.4)).abs();
        final bassReact = (i < 10 || i > 30) ? (beatPulse * (1.0 + bassBoost * 0.8)) : 0.0;
        rayHeight = (maxRayHeight * (0.15 + (harmonic * 0.55) + (bassReact * 0.35)))
            .clamp(4.0, maxRayHeight);
      }

      final startOffset = center + Offset(
        currentInnerRadius * math.cos(angle),
        currentInnerRadius * math.sin(angle),
      );
      final endOffset = center + Offset(
        (currentInnerRadius + rayHeight) * math.cos(angle),
        (currentInnerRadius + rayHeight) * math.sin(angle),
      );

      final rayColor = Color.lerp(accent, secondary, i / rayCount)!;
      final rayPaint = Paint()
        ..color = rayColor
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startOffset, endOffset, rayPaint);

      // Orbiting peak dots
      final dotOffset = center + Offset(
        (currentInnerRadius + rayHeight + 4.0) * math.cos(angle),
        (currentInnerRadius + rayHeight + 4.0) * math.sin(angle),
      );
      final dotPaint = Paint()
        ..color = rayColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotOffset, 1.2, dotPaint);
    }
  }

  // ------------------------------------------------------------- 4. VU Meter
  void _paintVu(Canvas canvas, Size size) {
    final meterWidth = (size.width - 24) / 2;
    final meterHeight = size.height * 0.78;
    final topY = (size.height - meterHeight) / 2;

    _paintSingleVu(canvas, Rect.fromLTWH(8, topY, meterWidth, meterHeight), 'CH 1 • LEFT', isLeft: true);
    _paintSingleVu(canvas, Rect.fromLTWH(16 + meterWidth, topY, meterWidth, meterHeight), 'CH 2 • RIGHT', isLeft: false);
  }

  void _paintSingleVu(Canvas canvas, Rect rect, String label, {required bool isLeft}) {
    final elapsedMs = position.inMilliseconds;
    final accent = _s.accent;

    // Bezel Box
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _s.bg0,
          _s.bg1,
        ],
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Arched Meter Scale
    final pivot = Offset(rect.center.dx, rect.bottom - 12);
    final meterRadius = rect.height * 0.72;
    const minAngle = -math.pi * 0.70;
    const maxAngle = -math.pi * 0.30;
    const angleRange = maxAngle - minAngle;

    final scaleRect = Rect.fromCircle(center: pivot, radius: meterRadius);
    final scalePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(scaleRect, minAngle, angleRange, false, scalePaint);

    // Red Warning Zone (+0dB to +3dB)
    final redZonePaint = Paint()
      ..color = skin?.red ?? const Color(0xFFE67E80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(scaleRect, minAngle + (angleRange * 0.72), angleRange * 0.28, false, redZonePaint);

    // Scale Ticks & Labels
    const ticks = [-20, -10, -7, -5, -3, -1, 0, 1, 2, 3];
    for (int i = 0; i < ticks.length; i++) {
      final t = i / (ticks.length - 1);
      final angle = minAngle + (angleRange * t);
      final isRed = ticks[i] >= 0;

      final p1 = pivot + Offset((meterRadius - 4) * math.cos(angle), (meterRadius - 4) * math.sin(angle));
      final p2 = pivot + Offset(meterRadius * math.cos(angle), meterRadius * math.sin(angle));

      final tickPaint = Paint()
        ..color = isRed
            ? (skin?.red ?? const Color(0xFFE67E80))
            : Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = (ticks[i] == 0) ? 2.0 : 1.0;
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Dynamic Needle Deflection
    const beatIntervalMs = (60000.0 / 120.0);
    final beatPhase = (elapsedMs % beatIntervalMs) / beatIntervalMs;
    final beatPulse = math.exp(-beatPhase * 4.0);

    double fraction = 0.0;
    if (playing) {
      final channelOffset = isLeft ? 0.0 : 0.8;
      final noise = math.sin((elapsedMs * 0.015) + channelOffset).abs();
      fraction = (0.20 + (0.50 * beatPulse * (1.0 + bassBoost * 0.5)) + (0.30 * noise)).clamp(0.05, 0.98);
    }

    final needleAngle = minAngle + (angleRange * fraction);
    final needleEnd = pivot + Offset((meterRadius - 2) * math.cos(needleAngle), (meterRadius - 2) * math.sin(needleAngle));

    // Needle shadow
    final needleShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot + const Offset(1, 1), needleEnd + const Offset(1, 1), needleShadow);

    // Needle line
    final needlePaint = Paint()
      ..color = (fraction > 0.72) ? (skin?.red ?? const Color(0xFFE67E80)) : Colors.white
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, needleEnd, needlePaint);

    // Pivot cap
    final pivotPaint = Paint()
      ..color = _s.bg2
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pivot, 5, pivotPaint);
    final pivotRing = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(pivot, 5, pivotRing);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _s.textMuted,
          fontSize: 8.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(rect.center.dx - (textPainter.width / 2), rect.top + 8));

    // Peak LED
    final isPeak = fraction > 0.72;
    final peakLedColor = isPeak ? _s.red : Colors.white10;
    final ledCenter = Offset(rect.right - 14, rect.top + 14);

    if (isPeak) {
      final ledGlow = Paint()
        ..color = peakLedColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(ledCenter, 3.5, ledGlow);
    }
    final ledCore = Paint()..color = peakLedColor;
    canvas.drawCircle(ledCenter, 2.5, ledCore);
  }

  @override
  bool shouldRepaint(covariant AudioReactiveSpectrogramPainter oldDelegate) {
    return true;
  }
}

