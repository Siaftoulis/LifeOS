import 'package:flutter/material.dart';
import '../../../../core/movie_repository.dart';
import '../../../../theme/everforest_colors.dart';

class MovieSearchDialog extends StatefulWidget {
  const MovieSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const MovieSearchDialog(),
    );
  }

  @override
  State<MovieSearchDialog> createState() => _MovieSearchDialogState();
}

class _MovieSearchDialogState extends State<MovieSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _results = [];
  bool _isSearching = false;
  final Set<String> _addingIds = {};

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    final res = await MovieRepository.instance.searchOnline(q);
    if (mounted) {
      setState(() {
        _results = res;
        _isSearching = false;
      });
    }
  }

  Future<void> _addMovie(Movie movie) async {
    setState(() => _addingIds.add(movie.id));
    final ok = await MovieRepository.instance.addMovie(movie);
    if (mounted) {
      setState(() => _addingIds.remove(movie.id));
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${movie.title}" to library'),
            backgroundColor: EverforestColors.bg1,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryMovieTitles = MovieRepository.instance.movies.value
        .map((m) => m.title.toLowerCase())
        .toSet();

    return Dialog(
      backgroundColor: EverforestColors.bg0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Container(
        width: 600,
        height: 620,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: EverforestColors.fg),
                    decoration: InputDecoration(
                      hintText: 'Search movies (TMDb / Vault)...',
                      hintStyle:
                          const TextStyle(color: EverforestColors.grey),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: EverforestColors.green),
                      filled: true,
                      fillColor: EverforestColors.bg1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: EverforestColors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search results list
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: EverforestColors.green),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Type a movie title and press Enter to search TMDb'
                                : 'No movies found matching "${_searchController.text}"',
                            style: const TextStyle(
                                color: EverforestColors.grey, fontSize: 13.5),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: EverforestColors.bg2, height: 1),
                          itemBuilder: (context, i) {
                            final m = _results[i];
                            final isInLibrary = libraryMovieTitles
                                .contains(m.title.toLowerCase());
                            final isAdding = _addingIds.contains(m.id);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: m.posterUrl.isNotEmpty
                                    ? Image.network(
                                        m.posterUrl,
                                        width: 44,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 44,
                                          height: 64,
                                          color: EverforestColors.bg1,
                                          child: const Icon(Icons.movie_rounded,
                                              color: EverforestColors.grey,
                                              size: 20),
                                        ),
                                      )
                                    : Container(
                                        width: 44,
                                        height: 64,
                                        color: EverforestColors.bg1,
                                        child: const Icon(Icons.movie_rounded,
                                            color: EverforestColors.grey,
                                            size: 20),
                                      ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: EverforestColors.fg,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (m.year.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      m.year,
                                      style: const TextStyle(
                                          color: EverforestColors.grey,
                                          fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  if (m.tmdbRating > 0)
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: EverforestColors.yellow,
                                            size: 15),
                                        const SizedBox(width: 4),
                                        Text(
                                          m.tmdbRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: EverforestColors.yellow,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (m.overview.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      m.overview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: EverforestColors.grey,
                                          fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: isInLibrary
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: EverforestColors.green
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_rounded,
                                              color: EverforestColors.green,
                                              size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            'In Library',
                                            style: TextStyle(
                                              color: EverforestColors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      icon: isAdding
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: EverforestColors.bg0,
                                              ),
                                            )
                                          : const Icon(Icons.add_rounded,
                                              size: 16),
                                      label: const Text('Add'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            EverforestColors.green,
                                        foregroundColor: EverforestColors.bg0,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed:
                                          isAdding ? null : () => _addMovie(m),
                                    ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
