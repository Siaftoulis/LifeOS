import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class MovieLibraryDashboard extends StatelessWidget {
  const MovieLibraryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = [
      {'title': 'Inception', 'director': 'Christopher Nolan', 'year': '2010', 'color': EverforestColors.purple},
      {'title': 'The Matrix', 'director': 'The Wachowskis', 'year': '1999', 'color': EverforestColors.green},
      {'title': 'Interstellar', 'director': 'Christopher Nolan', 'year': '2014', 'color': EverforestColors.blue},
      {'title': 'Pulp Fiction', 'director': 'Quentin Tarantino', 'year': '1994', 'color': EverforestColors.red},
      {'title': 'The Godfather', 'director': 'Francis Ford Coppola', 'year': '1972', 'color': EverforestColors.orange},
      {'title': 'The Dark Knight', 'director': 'Christopher Nolan', 'year': '2008', 'color': EverforestColors.yellow},
      {'title': 'Fight Club', 'director': 'David Fincher', 'year': '1999', 'color': EverforestColors.cyan},
      {'title': 'Forrest Gump', 'director': 'Robert Zemeckis', 'year': '1994', 'color': EverforestColors.aqua},
    ];

    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Movie Library', style: TextStyle(color: EverforestColors.fg)),
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
      ),
      body: Padding(
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
            final movie = movies[index];
            return Container(
              decoration: BoxDecoration(
                color: EverforestColors.bg2,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
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
                        color: movie['color'] as Color,
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
                            EverforestColors.bg0.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie['title'] as String,
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
                            '${movie['director']} • ${movie['year']}',
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
      ),
    );
  }
}
