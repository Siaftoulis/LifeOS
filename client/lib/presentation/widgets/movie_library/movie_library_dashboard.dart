import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'vlc_player_screen.dart';
import 'movie_review_editor.dart';

class MovieLibraryDashboard extends StatelessWidget {
  const MovieLibraryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Movie Library', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
              children: const [
                _MovieCard(title: 'Inception', status: 'AVAILABLE', cover: Icons.movie),
                _MovieCard(title: 'Interstellar', status: 'WATCHED', cover: Icons.local_movies),
                _MovieCard(title: 'Dune', status: 'DOWNLOADING', cover: Icons.theaters),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play Mock'),
                style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.bg2),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VLCPlayerScreen())),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.rate_review),
                label: const Text('Review Mock'),
                style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.bg2),
                onPressed: () => showModalBottomSheet(context: context, builder: (_) => const MovieReviewEditor()),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final String title, status;
  final IconData cover;

  const _MovieCard({required this.title, required this.status, required this.cover});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(child: Icon(cover, size: 64, color: EverforestColors.grey)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(status, style: const TextStyle(color: EverforestColors.cyan, fontSize: 12)),
        ],
      ),
    );
  }
}
