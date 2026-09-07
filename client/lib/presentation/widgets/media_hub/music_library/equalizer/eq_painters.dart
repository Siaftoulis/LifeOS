import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../theme/app_skin_manager.dart';

class EqCurvePainter extends CustomPainter {
  final List<double> bands;
  final bool enabled;
  final Color? curveColor;
  final Color? glowColor;

  EqCurvePainter({
    required this.bands,
    required this.enabled,
    this.curveColor,
    this.glowColor,
  });

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

    final skin = AppSkinManager.currentSkin;
    final activeColor = curveColor ?? skin.accent;
    final activeGlow = glowColor ?? skin.accent.withValues(alpha: 0.4);

    final curvePaint = Paint()
      ..color = enabled ? activeColor : skin.textMuted
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = enabled ? activeGlow : Colors.transparent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant EqCurvePainter oldDelegate) {
    return oldDelegate.bands != bands ||
        oldDelegate.enabled != enabled ||
        oldDelegate.curveColor != curveColor ||
        oldDelegate.glowColor != glowColor;
  }
}

/// Audiophile 3D Brushed Metallic Rotary Dial Painter
class KnobDialPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color? backgroundColor;
  final bool showTicks;

  KnobDialPainter({
    required this.fraction,
    required this.color,
    this.backgroundColor,
    this.showTicks = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.width / 2) - 2;
    final knobRadius = outerRadius * 0.72;

    const startAngle = 0.75 * math.pi; // 135 deg (7:30 o'clock)
    const sweepTotal = 1.5 * math.pi; // 270 deg travel to 405 deg (4:30 o'clock)
    final clampedFraction = fraction.clamp(0.0, 1.0);
    final currentAngle = startAngle + (sweepTotal * clampedFraction);

    // 1. Graduation Tick Marks around perimeter
    if (showTicks) {
      const int tickCount = 21;
      for (int i = 0; i < tickCount; i++) {
        final tickFraction = i / (tickCount - 1);
        final tickAngle = startAngle + (sweepTotal * tickFraction);
        final isPassed = tickFraction <= clampedFraction + 0.01;
        final isCenter = (i == (tickCount - 1) ~/ 2);

        final tickInnerRadius = outerRadius - (isCenter ? 5.5 : 3.5);
        final tickOuterRadius = outerRadius;

        final p1 = Offset(
          center.dx + tickInnerRadius * math.cos(tickAngle),
          center.dy + tickInnerRadius * math.sin(tickAngle),
        );
        final p2 = Offset(
          center.dx + tickOuterRadius * math.cos(tickAngle),
          center.dy + tickOuterRadius * math.sin(tickAngle),
        );

        final tickPaint = Paint()
          ..color = isPassed
              ? color.withValues(alpha: isCenter ? 1.0 : 0.85)
              : Colors.white.withValues(alpha: isCenter ? 0.25 : 0.12)
          ..strokeWidth = isCenter ? 2.0 : (isPassed ? 1.5 : 1.0)
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(p1, p2, tickPaint);
      }
    }

    // 2. Background Track Arc
    final trackRadius = outerRadius - 6;
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: trackRadius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // 3. Active Neon Glow Arc
    if (clampedFraction > 0.005) {
      final activeArcSweep = sweepTotal * clampedFraction;

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;

      final arcRect = Rect.fromCircle(center: center, radius: trackRadius);
      canvas.drawArc(arcRect, startAngle, activeArcSweep, false, glowPaint);
      canvas.drawArc(arcRect, startAngle, activeArcSweep, false, activePaint);
    }

    // 4. 3D Brushed Anodized Metallic Knob Body
    final knobRect = Rect.fromCircle(center: center, radius: knobRadius);

    // Bezel drop shadow
    final bezelShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 1.5), knobRadius, bezelShadowPaint);

    // Metallic body gradient simulating directional lighting
    final knobPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 0.85,
        colors: [
          backgroundColor != null
              ? Color.lerp(backgroundColor, Colors.white, 0.20)!
              : const Color(0xFF2E343E),
          backgroundColor ?? const Color(0xFF1E2228),
          const Color(0xFF0F1115),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(knobRect);

    canvas.drawCircle(center, knobRadius, knobPaint);

    // Brushed inner rim highlight
    final innerRimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, knobRadius - 0.5, innerRimPaint);

    // Inner recessed dish line
    final innerDishPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, knobRadius * 0.76, innerDishPaint);

    // 5. Rotating Illuminated Indicator Notch / Pointer & LED Tip
    final pointerInner = center +
        Offset(
          (knobRadius * 0.38) * math.cos(currentAngle),
          (knobRadius * 0.38) * math.sin(currentAngle),
        );
    final pointerOuter = center +
        Offset(
          (knobRadius - 2.2) * math.cos(currentAngle),
          (knobRadius - 2.2) * math.sin(currentAngle),
        );

    final pointerGlow = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(pointerInner, pointerOuter, pointerGlow);

    final pointerPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pointerInner, pointerOuter, pointerPaint);

    // Illuminated LED bead at the outer pointer notch
    final ledPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pointerOuter, 1.2, ledPaint);
  }

  @override
  bool shouldRepaint(covariant KnobDialPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showTicks != showTicks;
  }
}
