import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../theme/everforest_colors.dart';

class EqCurvePainter extends CustomPainter {
  final List<double> bands;
  final bool enabled;

  EqCurvePainter({required this.bands, required this.enabled});

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
      ..color = enabled
          ? EverforestColors.green.withValues(alpha: 0.4)
          : Colors.transparent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant EqCurvePainter oldDelegate) {
    return oldDelegate.bands != bands || oldDelegate.enabled != enabled;
  }
}

class KnobDialPainter extends CustomPainter {
  final double fraction;
  final Color color;

  KnobDialPainter({required this.fraction, required this.color});

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
  bool shouldRepaint(covariant KnobDialPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.color != color;
  }
}
