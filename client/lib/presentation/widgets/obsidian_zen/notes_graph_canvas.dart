import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class NotesGraphCanvas extends StatelessWidget {
  const NotesGraphCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600, height: 600,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(600, 600),
            painter: _GraphPainter(),
          ),
          const Positioned(top: 24, left: 24, child: Text('Knowledge Graph (Phase 1 Stub)', style: TextStyle(color: EverforestColors.fg, fontSize: 18))),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()..color = EverforestColors.bg2..strokeWidth = 2;
    final paintNode = Paint()..color = EverforestColors.purple;

    final center = Offset(size.width / 2, size.height / 2);
    final p1 = Offset(center.dx - 100, center.dy - 100);
    final p2 = Offset(center.dx + 150, center.dy - 50);
    final p3 = Offset(center.dx - 50, center.dy + 150);

    canvas.drawLine(center, p1, paintLine);
    canvas.drawLine(center, p2, paintLine);
    canvas.drawLine(center, p3, paintLine);
    canvas.drawLine(p1, p3, paintLine);

    canvas.drawCircle(center, 20, paintNode);
    canvas.drawCircle(p1, 15, paintNode);
    canvas.drawCircle(p2, 10, paintNode);
    canvas.drawCircle(p3, 25, paintNode);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
