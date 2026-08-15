import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/movie_repository.dart';

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
      body: ValueListenableBuilder<List<Movie>>(
        valueListenable: MovieRepository.instance.movies,
        builder: (context, movies, child) {
          if (movies.isEmpty) {
            return const Center(
              child: Text('No movies found', style: TextStyle(color: EverforestColors.fg)),
            );
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
              itemBuilder: (context, index) =>
                  _MovieCard(movie: movies[index]),
            ),
          );
        },
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    Color movieColor = EverforestColors.bg2;
    if (movie.colorHex.isNotEmpty) {
      try {
        movieColor = Color(int.parse(movie.colorHex));
      } catch (_) {}
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showActions(context),
      child: Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: movie.posterUrl.isNotEmpty
                    ? Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(color: movieColor),
                      )
                    : ColoredBox(
                        color: movieColor,
                        child: const Center(
                          child: Icon(Icons.movie, size: 64, color: EverforestColors.bg0),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EverforestColors.bg0.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  movie.status,
                  style: const TextStyle(
                    color: EverforestColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
                      movie.title,
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
                      '${movie.director} • ${movie.year}'
                      '${movie.tmdbRating > 0 ? '  ★ ${movie.tmdbRating.toStringAsFixed(1)}' : ''}',
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
      ),
    );
  }

  Future<void> _showActions(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg1,
      builder: (_) => _MovieActionsSheet(movie: movie),
    );
  }
}

class _MovieActionsSheet extends StatefulWidget {
  const _MovieActionsSheet({required this.movie});

  final Movie movie;

  @override
  State<_MovieActionsSheet> createState() => _MovieActionsSheetState();
}

class _MovieActionsSheetState extends State<_MovieActionsSheet> {
  static const _statuses = ['AVAILABLE', 'DOWNLOADING', 'WATCHED'];

  late double _rating = widget.movie.rating;
  late String _comment = '';

  @override
  Widget build(BuildContext context) {
    final repo = MovieRepository.instance;
    final movie = widget.movie;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movie.title,
              style: const TextStyle(
                color: EverforestColors.fg,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final s in _statuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        s[0] + s.substring(1).toLowerCase(),
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: movie.status == s,
                      onSelected: (_) => repo.setStatus(movie.id, s),
                      selectedColor: EverforestColors.green.withValues(alpha: 0.35),
                      backgroundColor: EverforestColors.bg2,
                      labelStyle: TextStyle(
                        color: movie.status == s
                            ? EverforestColors.fg
                            : EverforestColors.grey,
                      ),
                      side: const BorderSide(color: EverforestColors.bg2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Rating',
                  style: TextStyle(color: EverforestColors.grey, fontSize: 13),
                ),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: 10,
                    divisions: 20,
                    value: _rating,
                    activeColor: EverforestColors.green,
                    inactiveColor: EverforestColors.bg2,
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                ),
                Text(
                  _rating.toStringAsFixed(1),
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
                ),
              ],
            ),
            TextField(
              style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Review comment…',
                hintStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: EverforestColors.bg2),
                ),
              ),
              onChanged: (v) => _comment = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EverforestColors.fg,
                      side: const BorderSide(color: EverforestColors.bg2),
                    ),
                    icon: const Icon(Icons.playlist_add, size: 16),
                    label: const Text('Watchlist'),
                    onPressed: () => repo.addToWatchlist(movie.id),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: EverforestColors.green.withValues(alpha: 0.35),
                      foregroundColor: EverforestColors.fg,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Save review'),
                    onPressed: () => repo.saveReview(movie.id, _rating, _comment),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
