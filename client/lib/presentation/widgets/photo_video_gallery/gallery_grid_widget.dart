import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class GalleryGridWidget extends StatelessWidget {
  const GalleryGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final media = [
      {'type': 'photo', 'label': 'Mountain View', 'color': EverforestColors.green},
      {'type': 'video', 'label': 'City Lights', 'color': EverforestColors.purple},
      {'type': 'photo', 'label': 'Ocean Waves', 'color': EverforestColors.blue},
      {'type': 'photo', 'label': 'Forest Path', 'color': EverforestColors.aqua},
      {'type': 'video', 'label': 'Concert', 'color': EverforestColors.red},
      {'type': 'photo', 'label': 'Desert Dunes', 'color': EverforestColors.orange},
      {'type': 'photo', 'label': 'Autumn Leaves', 'color': EverforestColors.yellow},
      {'type': 'video', 'label': 'Snowfall', 'color': EverforestColors.cyan},
      {'type': 'photo', 'label': 'Starry Night', 'color': EverforestColors.blue},
      {'type': 'photo', 'label': 'Sunrise', 'color': EverforestColors.red},
      {'type': 'video', 'label': 'Raindrops', 'color': EverforestColors.aqua},
      {'type': 'photo', 'label': 'Cityscape', 'color': EverforestColors.purple},
    ];

    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Gallery', style: TextStyle(color: EverforestColors.fg)),
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: media.length,
        itemBuilder: (context, index) {
          final item = media[index];
          final isVideo = item['type'] == 'video';
          return Container(
            color: item['color'] as Color,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Icon(
                    isVideo ? Icons.videocam : Icons.photo,
                    size: 48,
                    color: EverforestColors.bg0.withOpacity(0.4),
                  ),
                ),
                if (isVideo)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.play_circle_fill, color: EverforestColors.bg0, size: 24),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          EverforestColors.bg0.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: EverforestColors.blue,
        child: const Icon(Icons.add_a_photo, color: EverforestColors.bg0),
      ),
    );
  }
}
