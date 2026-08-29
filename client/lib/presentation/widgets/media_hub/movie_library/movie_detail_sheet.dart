import 'package:flutter/material.dart';
import '../../../../core/movie_repository.dart';
import '../../../../theme/everforest_colors.dart';
import 'movie_review_editor.dart';
import 'vlc_player_screen.dart';

class MovieDetailSheet extends StatefulWidget {
  const MovieDetailSheet({
    super.key,
    required this.movie,
  });

  final Movie movie;

  static Future<void> show(BuildContext context, Movie movie) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MovieDetailSheet(movie: movie),
    );
  }

  @override
  State<MovieDetailSheet> createState() => _MovieDetailSheetState();
}

class _MovieDetailSheetState extends State<MovieDetailSheet> {
  late Movie _movie;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
  }

  Future<void> _toggleWatchlist() async {
    final repo = MovieRepository.instance;
    final inList = repo.isInWatchlist(_movie.id);
    if (inList) {
      await repo.removeFromWatchlist(_movie.id);
    } else {
      await repo.addToWatchlist(_movie.id);
    }
    setState(() {});
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    await MovieRepository.instance.setStatus(_movie.id, status);
    setState(() {
      _movie = Movie(
        id: _movie.id,
        title: _movie.title,
        director: _movie.director,
        year: _movie.year,
        status: status,
        imdbId: _movie.imdbId,
        posterUrl: _movie.posterUrl,
        overview: _movie.overview,
        genres: _movie.genres,
        colorHex: _movie.colorHex,
        rating: _movie.rating,
        tmdbRating: _movie.tmdbRating,
      );
      _isUpdating = false;
    });
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Delete Movie?',
            style: TextStyle(color: EverforestColors.fg)),
        content: Text(
          'Are you sure you want to remove "${_movie.title}" from your library?',
          style: const TextStyle(color: EverforestColors.grey),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: EverforestColors.grey)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: EverforestColors.red),
            child: const Text('Delete',
                style: TextStyle(color: EverforestColors.bg0)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await MovieRepository.instance.deleteMovie(_movie.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${_movie.title}" from library'),
            backgroundColor: EverforestColors.bg1,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInWatchlist = MovieRepository.instance.isInWatchlist(_movie.id);
    final genresList = _movie.genres
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          )
        ],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Top Poster & Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 175,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _movie.posterUrl.isNotEmpty
                            ? Image.network(
                                _movie.posterUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: EverforestColors.bg1,
                                  child: const Icon(Icons.movie_rounded,
                                      color: EverforestColors.grey, size: 40),
                                ),
                              )
                            : Container(
                                color: EverforestColors.bg1,
                                child: const Icon(Icons.movie_rounded,
                                    color: EverforestColors.grey, size: 40),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _movie.title,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (_movie.year.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: EverforestColors.bg1,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _movie.year,
                                    style: const TextStyle(
                                      color: EverforestColors.fg,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (_movie.tmdbRating > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: EverforestColors.yellow
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: EverforestColors.yellow
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: EverforestColors.yellow,
                                          size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        _movie.tmdbRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: EverforestColors.yellow,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (_movie.director.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Director: ${_movie.director}',
                              style: const TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Watchlist Toggle
                          OutlinedButton.icon(
                            icon: Icon(
                              isInWatchlist
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_add_outlined,
                              color: isInWatchlist
                                  ? EverforestColors.green
                                  : EverforestColors.fg,
                              size: 18,
                            ),
                            label: Text(
                              isInWatchlist
                                  ? 'In Watchlist'
                                  : 'Add to Watchlist',
                              style: TextStyle(
                                color: isInWatchlist
                                    ? EverforestColors.green
                                    : EverforestColors.fg,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isInWatchlist
                                    ? EverforestColors.green
                                    : Colors.white24,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _toggleWatchlist,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Genres chips
                if (genresList.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genresList.map((g) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: EverforestColors.bg1,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: EverforestColors.green
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          g,
                          style: const TextStyle(
                            color: EverforestColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Status Switcher
                const Text(
                  'STATUS',
                  style: TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip('AVAILABLE', 'Available',
                        Icons.check_circle_outline, EverforestColors.blue),
                    const SizedBox(width: 8),
                    _buildStatusChip('WATCHED', 'Watched',
                        Icons.visibility_rounded, EverforestColors.green),
                    const SizedBox(width: 8),
                    _buildStatusChip('DOWNLOADING', 'Downloading',
                        Icons.downloading_rounded, EverforestColors.yellow),
                  ],
                ),
                const SizedBox(height: 20),

                // Overview
                if (_movie.overview.isNotEmpty) ...[
                  const Text(
                    'SYNOPSIS',
                    style: TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _movie.overview,
                    style: const TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons: Review & Play with VLC
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('Play with VLC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EverforestColors.green,
                          foregroundColor: EverforestColors.bg0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VLCPlayerScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.star_outline_rounded,
                            color: EverforestColors.yellow, size: 20),
                        label: Text(
                          _movie.rating > 0
                              ? '${_movie.rating.toStringAsFixed(1)} ★'
                              : 'Write Review',
                          style: const TextStyle(
                              color: EverforestColors.yellow),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: EverforestColors.yellow
                                  .withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () =>
                            MovieReviewEditor.show(context, _movie),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Delete movie button
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: EverforestColors.red, size: 18),
                    label: const Text('Remove from Library',
                        style: TextStyle(color: EverforestColors.red)),
                    onPressed: _confirmDelete,
                  ),
                ),
              ],
            ),
          ),
          if (_isUpdating)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                      color: EverforestColors.green),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
      String statusKey, String label, IconData icon, Color color) {
    final isSelected = _movie.status.toUpperCase() == statusKey;

    return Expanded(
      child: InkWell(
        onTap: () => _updateStatus(statusKey),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : EverforestColors.bg1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : EverforestColors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : EverforestColors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
