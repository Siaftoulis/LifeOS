import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class MediaVault extends StatelessWidget {
  const MediaVault({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Color> blockColors = [
      EverforestColors.green,
      EverforestColors.blue,
      EverforestColors.orange,
      EverforestColors.purple,
      EverforestColors.aqua,
      EverforestColors.red,
      EverforestColors.yellow,
    ];

    return Container(
      color: EverforestColors.bg0,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                final color = blockColors[index % blockColors.length];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: EverforestColors.grey.withOpacity(0.5), width: 1.5),
                  ),
                  child: Center(
                    child: Icon(Icons.image_outlined, color: color.withOpacity(0.5), size: 24),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: EverforestColors.bg0,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: EverforestColors.blue.withOpacity(0.5), width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_outlined, color: EverforestColors.blue, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Auto-Sync: Active',
                    style: TextStyle(color: EverforestColors.fg, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
