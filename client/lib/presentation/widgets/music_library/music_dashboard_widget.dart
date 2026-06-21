import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class MusicDashboardWidget extends StatelessWidget {
  const MusicDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final tracks = [
      {'title': 'Bohemian Rhapsody', 'artist': 'Queen', 'color': EverforestColors.red},
      {'title': 'Stairway to Heaven', 'artist': 'Led Zeppelin', 'color': EverforestColors.yellow},
      {'title': 'Hotel California', 'artist': 'Eagles', 'color': EverforestColors.orange},
      {'title': 'Smells Like Teen Spirit', 'artist': 'Nirvana', 'color': EverforestColors.aqua},
      {'title': 'Imagine', 'artist': 'John Lennon', 'color': EverforestColors.blue},
      {'title': 'Sweet Child O\' Mine', 'artist': 'Guns N\' Roses', 'color': EverforestColors.purple},
      {'title': 'Billie Jean', 'artist': 'Michael Jackson', 'color': EverforestColors.green},
      {'title': 'Hey Jude', 'artist': 'The Beatles', 'color': EverforestColors.cyan},
    ];

    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Music Library', style: TextStyle(color: EverforestColors.fg)),
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return Container(
              decoration: BoxDecoration(
                color: EverforestColors.bg1,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: track['color'] as Color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (track['color'] as Color).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.music_note, size: 40, color: EverforestColors.bg0),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      track['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      track['artist'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: EverforestColors.green,
        child: const Icon(Icons.play_arrow, color: EverforestColors.bg0, size: 32),
      ),
    );
  }
}
