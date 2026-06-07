import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class RadarVision extends StatelessWidget {
  const RadarVision({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: Stack(
        children: [
          // Wireframe Map Background
          Positioned.fill(
            child: CustomPaint(
              painter: _MapWireframePainter(),
            ),
          ),
          // Camera Feeds
          Positioned(
            top: 20,
            right: 20,
            child: _buildCameraFeed('Front Door', EverforestColors.blue),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildCameraFeed('Backyard', EverforestColors.green),
          ),
          // Center Beacon
          Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EverforestColors.aqua,
                boxShadow: [
                  BoxShadow(
                    color: EverforestColors.aqua.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 4,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFeed(String label, Color accent) {
    return Container(
      width: 140,
      height: 90,
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.5), width: 1),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.videocam_outlined, color: EverforestColors.grey.withOpacity(0.5), size: 32),
          ),
          Positioned(
            top: 6,
            left: 8,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: EverforestColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 10,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapWireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EverforestColors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Draw some random abstract map shapes
    final pathPaint = Paint()
      ..color = EverforestColors.green.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width * 0.8, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.4, size.width * 0.4, size.height * 0.2);
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
