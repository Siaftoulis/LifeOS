import 'package:flutter/material.dart';
import '../../../../core/movie_repository.dart';
import '../../../../theme/everforest_colors.dart';
import 'movie_detail_sheet.dart';
import 'movie_search_dialog.dart';

class MovieLibraryDashboard extends StatefulWidget {
  const MovieLibraryDashboard({super.key});

  @override
  State<MovieLibraryDashboard> createState() => _MovieLibraryDashboardState();
}

class _MovieLibraryDashboardState extends State<MovieLibraryDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _filterController = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  List<Movie> _filterList(List<Movie> list, int tabIndex) {
    var filtered = list;
    if (_searchFilter.isNotEmpty) {
      filtered = filtered.where((m) {
        final query = _searchFilter.toLowerCase();
        return m.title.toLowerCase().contains(query) ||
            m.director.toLowerCase().contains(query) ||
            m.genres.toLowerCase().contains(query);
      }).toList();
    }

    switch (tabIndex) {
      case 1: // Watchlist
        final watchlistIds = MovieRepository.instance.watchlistIds.value;
        return filtered.where((m) => watchlistIds.contains(m.id)).toList();
      case 2: // Watched
        return filtered
            .where((m) => m.status.toUpperCase() == 'WATCHED')
            .toList();
      case 3: // Available
        return filtered
            .where((m) => m.status.toUpperCase() == 'AVAILABLE')
            .toList();
      default: // All
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EverforestColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.movie_filter_rounded,
                  color: EverforestColors.purple, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cinema Vault',
              style: TextStyle(
                color: EverforestColors.fg,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: EverforestColors.green, size: 24),
            tooltip: 'Search & Add from TMDb',
            onPressed: () => MovieSearchDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: EverforestColors.grey, size: 22),
            tooltip: 'Refresh Movies',
            onPressed: () => MovieRepository.instance.refresh(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Local Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _filterController,
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Filter your library by title, director, genre...',
                    hintStyle:
                        const TextStyle(color: EverforestColors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.filter_list_rounded,
                        color: EverforestColors.grey, size: 18),
                    suffixIcon: _searchFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: EverforestColors.grey, size: 18),
                            onPressed: () {
                              _filterController.clear();
                              setState(() => _searchFilter = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: EverforestColors.bg1,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchFilter = val.trim()),
                ),
              ),
              const SizedBox(height: 8),

              // Segmented Filter Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: EverforestColors.purple,
                indicatorWeight: 3,
                labelColor: EverforestColors.purple,
                unselectedLabelColor: EverforestColors.grey,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Watchlist'),
                  Tab(text: 'Watched'),
                  Tab(text: 'Available'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder<List<Movie>>(
        valueListenable: MovieRepository.instance.movies,
        builder: (context, movies, _) {
          return ValueListenableBuilder<Set<String>>(
            valueListenable: MovieRepository.instance.watchlistIds,
            builder: (context, _, __) {
              return TabBarView(
                controller: _tabController,
                children: List.generate(4, (tabIndex) {
                  final items = _filterList(movies, tabIndex);

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.movie_outlined,
                              color: EverforestColors.grey, size: 48),
                          const SizedBox(height: 14),
                          Text(
                            _searchFilter.isNotEmpty
                                ? 'No movies matching "$_searchFilter"'
                                : 'No movies in this list',
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Search & Add from TMDb'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EverforestColors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => MovieSearchDialog.show(context),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _MovieCard(movie: items[index]),
                    ),
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});

  final Movie movie;

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WATCHED':
        return EverforestColors.green;
      case 'DOWNLOADING':
        return EverforestColors.yellow;
      case 'AVAILABLE':
      default:
        return EverforestColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(movie.status);
    final isInWatchlist = MovieRepository.instance.isInWatchlist(movie.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => MovieDetailSheet.show(context, movie),
      child: Container(
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster with Overlays
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  movie.posterUrl.isNotEmpty
                      ? Image.network(
                          movie.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: EverforestColors.bg2,
                            child: const Center(
                              child: Icon(Icons.movie_rounded,
                                  size: 48, color: EverforestColors.grey),
                            ),
                          ),
                        )
                      : Container(
                          color: EverforestColors.bg2,
                          child: const Center(
                            child: Icon(Icons.movie_rounded,
                                size: 48, color: EverforestColors.grey),
                          ),
                        ),

                  // Rating Badge
                  if (movie.tmdbRating > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: EverforestColors.yellow
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: EverforestColors.yellow, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              movie.tmdbRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: EverforestColors.yellow,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Watchlist Bookmark Icon
                  if (isInWatchlist)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.bookmark_rounded,
                            color: EverforestColors.green, size: 16),
                      ),
                    ),
                ],
              ),
            ),

            // Card Footer info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: EverforestColors.fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        movie.year.isNotEmpty ? movie.year : 'Movie',
                        style: const TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 11.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          movie.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
