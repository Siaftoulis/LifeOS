import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class VoidSlot extends StatelessWidget {
  const VoidSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(24.0),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: EverforestColors.grey.withOpacity(0.5)),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_box_outlined, color: EverforestColors.grey, size: 48),
              SizedBox(height: 16),
              Text(
                'Empty Slot\nReady for Module',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    
    // Top
    for (double i = 0; i < size.width; i += dashWidth + dashSpace) {
      canvas.drawLine(Offset(i, 0), Offset(i + dashWidth, 0), paint);
    }
    // Bottom
    for (double i = 0; i < size.width; i += dashWidth + dashSpace) {
      canvas.drawLine(Offset(i, size.height), Offset(i + dashWidth, size.height), paint);
    }
    // Left
    for (double i = 0; i < size.height; i += dashWidth + dashSpace) {
      canvas.drawLine(Offset(0, i), Offset(0, i + dashWidth), paint);
    }
    // Right
    for (double i = 0; i < size.height; i += dashWidth + dashSpace) {
      canvas.drawLine(Offset(size.width, i), Offset(size.width, i + dashWidth), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
