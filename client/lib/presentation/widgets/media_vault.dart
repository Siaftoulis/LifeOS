import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
            padding: const EdgeInsets.all(8.0),
            child: MasonryGridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              itemCount: 20,
              itemBuilder: (context, index) {
                final height = (index % 3 + 1) * 60.0 + 40.0;
                final color = blockColors[index % blockColors.length];
                return Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: EverforestColors.bg1.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EverforestColors.bg2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_outlined, color: EverforestColors.green, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Auto-Sync: Active',
                    style: TextStyle(color: EverforestColors.fg, fontSize: 11, fontWeight: FontWeight.bold),
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
