import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/general_engine/engine_repository.dart';
import '../../../../core/general_engine/general_engine_client.dart';

class MovieLibraryDashboard extends StatelessWidget {
  const MovieLibraryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Movie Library', style: TextStyle(color: EverforestColors.fg)),
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
      ),
      body: ValueListenableBuilder<List<GeneralEngineEntity>>(
        valueListenable: EngineRepository.instance.allEntities,
        builder: (context, entities, child) {
          final movies = EngineRepository.instance.movies;
          if (movies.isEmpty) {
            return const Center(child: Text('No movies found', style: TextStyle(color: EverforestColors.fg)));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movieEntity = movies[index];
                final movie = movieEntity.payload;
                Color movieColor = EverforestColors.bg2;
                if (movie['color'] != null) {
                  try {
                    movieColor = Color(int.parse(movie['color']));
                  } catch (_) {}
                }

                return Container(
                  decoration: BoxDecoration(
                    color: EverforestColors.bg2,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: movieColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.movie, size: 64, color: EverforestColors.bg0),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                EverforestColors.bg0.withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie['title'] as String? ?? 'Unknown Title',
                                style: const TextStyle(
                                  color: EverforestColors.fg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${movie['director'] ?? ''} • ${movie['year'] ?? ''}',
                                style: const TextStyle(
                                  color: EverforestColors.grey,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
    );
  }
}
