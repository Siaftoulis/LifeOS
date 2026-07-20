import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/general_engine/engine_repository.dart';
import '../../../../core/general_engine/general_engine_client.dart';

class MusicDashboardWidget extends StatefulWidget {
  const MusicDashboardWidget({super.key});

  @override
  State<MusicDashboardWidget> createState() => _MusicDashboardWidgetState();
}

class _MusicDashboardWidgetState extends State<MusicDashboardWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Music Library', style: TextStyle(color: EverforestColors.fg)),
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
      ),
      body: ValueListenableBuilder<List<GeneralEngineEntity>>(
        valueListenable: EngineRepository.instance.allEntities,
        builder: (context, entities, child) {
          final tracks = EngineRepository.instance.musicTracks;
          if (tracks.isEmpty) {
            return const Center(child: Text('No tracks found', style: TextStyle(color: EverforestColors.grey)));
          }

          return Padding(
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
                final trackEntity = tracks[index];
                final track = trackEntity.payload;
                final colors = [
                  EverforestColors.red,
                  EverforestColors.yellow,
                  EverforestColors.orange,
                  EverforestColors.aqua,
                  EverforestColors.blue,
                  EverforestColors.purple,
                  EverforestColors.green,
                  EverforestColors.cyan,
                ];
                final color = colors[index % colors.length];

                return Container(
                  decoration: BoxDecoration(
                    color: EverforestColors.bg1,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
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
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
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
                          track['title'] as String? ?? 'Unknown Title',
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
                          track['artist'] as String? ?? 'Unknown Artist',
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: EverforestColors.green,
        child: const Icon(Icons.play_arrow, color: EverforestColors.bg0, size: 32),
      ),
    );
  }
}
