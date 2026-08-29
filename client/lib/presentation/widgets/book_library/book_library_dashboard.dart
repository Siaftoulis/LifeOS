import 'package:flutter/material.dart';
import '../../../core/repositories/book_repository.dart';
import '../../../database/database.dart';
import '../../../theme/everforest_colors.dart';
import 'book_card_widget.dart';
import 'highlight_curtain.dart';
import 'search_view.dart';

class BookLibraryDashboard extends StatefulWidget {
  const BookLibraryDashboard({super.key});

  @override
  State<BookLibraryDashboard> createState() => _BookLibraryDashboardState();
}

class _BookLibraryDashboardState extends State<BookLibraryDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _filterController = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    BookRepository.instance.syncFromDaemon();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  List<Book> _filterBooks(
      List<Book> books, List<Audiobook> audiobooks, int tabIndex) {
    var filtered = books;
    if (_searchFilter.isNotEmpty) {
      final query = _searchFilter.toLowerCase();
      filtered = filtered.where((b) {
        return b.title.toLowerCase().contains(query) ||
            (b.author?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    final audioBookIds = audiobooks.map((a) => a.bookId).toSet();

    switch (tabIndex) {
      case 1: // Currently Reading
        return filtered.where((b) {
          final isAudio = audioBookIds.contains(b.id);
          if (isAudio) {
            final a = audiobooks.firstWhere((item) => item.bookId == b.id);
            return a.currentSeconds > 0 &&
                a.durationSeconds > 0 &&
                a.currentSeconds < a.durationSeconds;
          }
          return b.currentPage > 0 && b.currentPage < b.totalPages;
        }).toList();
      case 2: // To Read / Unread
        return filtered.where((b) {
          final isAudio = audioBookIds.contains(b.id);
          if (isAudio) {
            final a = audiobooks.firstWhere((item) => item.bookId == b.id);
            return a.currentSeconds == 0;
          }
          return b.currentPage == 0;
        }).toList();
      case 3: // Finished
        return filtered.where((b) {
          final isAudio = audioBookIds.contains(b.id);
          if (isAudio) {
            final a = audiobooks.firstWhere((item) => item.bookId == b.id);
            return a.durationSeconds > 0 &&
                a.currentSeconds >= a.durationSeconds;
          }
          return b.totalPages > 0 && b.currentPage >= b.totalPages;
        }).toList();
      case 4: // Audiobooks only
        return filtered.where((b) => audioBookIds.contains(b.id)).toList();
      default: // All
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;

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
                color: EverforestColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  color: EverforestColors.green, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reading Vault',
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
            icon: const Icon(Icons.travel_explore_rounded,
                color: EverforestColors.green, size: 24),
            tooltip: 'Online Sources Search',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookSearchView()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.format_quote_rounded,
                color: EverforestColors.yellow, size: 22),
            tooltip: 'Saved Highlights',
            onPressed: () => showDialog(
                context: context, builder: (_) => const HighlightCurtain()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: EverforestColors.grey, size: 22),
            tooltip: 'Sync Books',
            onPressed: () => BookRepository.instance.syncFromDaemon(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // In-Library Search Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _filterController,
                  style:
                      const TextStyle(color: EverforestColors.fg, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Filter your library by title or author...',
                    hintStyle: const TextStyle(
                        color: EverforestColors.grey, fontSize: 13),
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
                  onChanged: (val) =>
                      setState(() => _searchFilter = val.trim()),
                ),
              ),
              const SizedBox(height: 8),

              // Filter Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: EverforestColors.green,
                indicatorWeight: 3,
                isScrollable: true,
                labelColor: EverforestColors.green,
                unselectedLabelColor: EverforestColors.grey,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'All Books'),
                  Tab(text: 'Reading'),
                  Tab(text: 'To Read'),
                  Tab(text: 'Finished'),
                  Tab(text: 'Audiobooks'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Book>>(
        stream: db.booksDao.watchAllBooks(),
        builder: (context, bookSnapshot) {
          if (!bookSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: EverforestColors.green),
            );
          }
          final books = bookSnapshot.data!;

          return StreamBuilder<List<Audiobook>>(
            stream: db.booksDao.watchAllAudiobooks(),
            builder: (context, audioSnapshot) {
              final audiobooks = audioSnapshot.data ?? [];

              return TabBarView(
                controller: _tabController,
                children: List.generate(5, (tabIndex) {
                  final items = _filterBooks(books, audiobooks, tabIndex);

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_stories_outlined,
                              color: EverforestColors.grey, size: 48),
                          const SizedBox(height: 14),
                          Text(
                            _searchFilter.isNotEmpty
                                ? 'No books matching "$_searchFilter"'
                                : 'No books in this shelf',
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('Search Online Sources'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EverforestColors.green,
                              foregroundColor: EverforestColors.bg0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BookSearchView()),
                            ),
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
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          BookCardWidget(book: items[index]),
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
