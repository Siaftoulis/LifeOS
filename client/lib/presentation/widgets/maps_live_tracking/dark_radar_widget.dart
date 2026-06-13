import 'package:flutter/material.dart';
import 'dart:math';
import '../../../theme/everforest_colors.dart';

class DarkRadarWidget extends StatefulWidget {
  const DarkRadarWidget({super.key});

  @override
  State<DarkRadarWidget> createState() => _DarkRadarWidgetState();
}

class _DarkRadarWidgetState extends State<DarkRadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => CustomPaint(painter: _RadarPainter(_anim.value)),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  _RadarPainter(this.sweepAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 - 10;

    // Grid circles
    final paintGrid = Paint()..color = EverforestColors.bg2..style = PaintingStyle.stroke..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), paintGrid);
    }
    
    // Crosshairs
    canvas.drawLine(Offset(center.dx, 10), Offset(center.dx, size.height - 10), paintGrid);
    canvas.drawLine(Offset(10, center.dy), Offset(size.width - 10, center.dy), paintGrid);

    // Geofences
    final paintGeofence = Paint()..color = EverforestColors.green.withOpacity(0.3)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + 40, center.dy - 30), 20, paintGeofence);

    // Radar Sweep
    final paintSweep = Paint()
      ..shader = SweepGradient(
        colors: [EverforestColors.cyan.withOpacity(0.0), EverforestColors.cyan.withOpacity(0.5)],
        stops: const [0.0, 1.0],
        transform: GradientRotation(sweepAngle * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;
    
    canvas.drawArc(Rect.fromCircle(center: center, radius: maxRadius), sweepAngle * 2 * pi, pi / 2, true, paintSweep);

    // Target beacons
    final paintTarget = Paint()..color = EverforestColors.red..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - 50, center.dy + 40), 4, paintTarget);
    canvas.drawCircle(Offset(center.dx + 40, center.dy - 30), 4, paintTarget);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.sweepAngle != sweepAngle;
}
