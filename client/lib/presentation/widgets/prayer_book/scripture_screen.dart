import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../theme/everforest_colors.dart';
import 'prayer_reader_screen.dart';

class ScriptureScreen extends StatefulWidget {
  const ScriptureScreen({super.key});

  @override
  State<ScriptureScreen> createState() => _ScriptureScreenState();
}

class _ScriptureScreenState extends State<ScriptureScreen> {
  List<BookSummary> _books = [];
  bool _isLoading = true;
  String? _error;
  BookSummary? _selectedBook;
  bool _loadingChapters = false;
  String _searchQuery = '';
  List<ScriptureSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/scripture');

      if (data is Map && data['books'] is List) {
        final books = (data['books'] as List)
            .map((b) => BookSummary.fromJson(b))
            .toList();
        setState(() {
          _books = books;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load Scripture';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error';
        _isLoading = false;
      });
    }
  }

  void _openChapter(BookSummary book, int chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrayerReaderScreen(
          serviceId: 'scripture_${book.number}_$chapter',
          serviceTitle: '${book.nameEnglish} $chapter',
        ),
      ),
    );
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final data = await ApiClient.instance.getDaemon(
        '/api/v1/prayers/scripture/search?q=${Uri.encodeComponent(query)}',
      );

      if (data is Map && data['results'] is List) {
        final results = (data['results'] as List)
            .map((r) => ScriptureSearchResult.fromJson(r))
            .toList();
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _openSearchResult(ScriptureSearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrayerReaderScreen(
          serviceId: 'scripture_${result.bookNumber}_${result.chapter}',
          serviceTitle: '${result.bookGreek} ${result.chapter}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: EverforestColors.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedBook != null ? _selectedBook!.nameGreek : 'Καινή Διαθήκη',
          style: const TextStyle(
            color: EverforestColors.fg,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_selectedBook != null)
            IconButton(
              icon: const Icon(Icons.grid_view, color: EverforestColors.fg),
              onPressed: () => setState(() => _selectedBook = null),
              tooltip: 'All Books',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.yellow))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: EverforestColors.grey),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: EverforestColors.grey)),
                      TextButton(
                        onPressed: _loadBooks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: _selectedBook == null
                          ? _buildBookGrid()
                          : _buildChapterList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (q) {
          setState(() => _searchQuery = q);
          _search(q);
        },
        decoration: InputDecoration(
          hintText: 'Search Scripture...',
          hintStyle: const TextStyle(color: EverforestColors.grey),
          prefixIcon: const Icon(Icons.search, color: EverforestColors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: EverforestColors.grey),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchResults = [];
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: EverforestColors.bg1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
      ),
    );
  }

  Widget _buildBookGrid() {
    if (_searchQuery.length >= 2) {
      return _buildSearchResults();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(BookSummary book) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBook = book);
      },
      child: Container(
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              book.nameEnglish,
              style: const TextStyle(
                color: EverforestColors.fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              book.nameGreek,
              style: const TextStyle(
                color: EverforestColors.grey,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${book.chapterCount} ch · ${book.verseCount} v',
              style: const TextStyle(
                color: EverforestColors.grey,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList() {
    if (_loadingChapters) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.yellow));
    }

    final book = _selectedBook!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          book.nameGreek,
          style: const TextStyle(
            color: EverforestColors.fg,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(book.chapterCount, (index) {
            final chapterNum = index + 1;
            return GestureDetector(
              onTap: () => _openChapter(book, chapterNum),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EverforestColors.bg1,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$chapterNum',
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.yellow));
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: EverforestColors.bg1,
          child: ListTile(
            title: Text(
              '${result.bookEnglish} ${result.chapter}:${result.verse}',
              style: const TextStyle(
                color: EverforestColors.fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              result.snippet,
              style: const TextStyle(
                color: EverforestColors.grey,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _openSearchResult(result),
          ),
        );
      },
    );
  }
}

class BookSummary {
  final int number;
  final String nameGreek;
  final String nameEnglish;
  final int chapterCount;
  final int verseCount;

  BookSummary({
    required this.number,
    required this.nameGreek,
    required this.nameEnglish,
    required this.chapterCount,
    required this.verseCount,
  });

  factory BookSummary.fromJson(Map<String, dynamic> json) {
    return BookSummary(
      number: json['number'] ?? 0,
      nameGreek: json['nameGreek'] ?? '',
      nameEnglish: json['nameEnglish'] ?? '',
      chapterCount: json['chapter_count'] ?? 0,
      verseCount: json['verse_count'] ?? 0,
    );
  }
}

class ScriptureSearchResult {
  final int bookNumber;
  final String bookGreek;
  final String bookEnglish;
  final int chapter;
  final int verse;
  final String snippet;

  ScriptureSearchResult({
    required this.bookNumber,
    required this.bookGreek,
    required this.bookEnglish,
    required this.chapter,
    required this.verse,
    required this.snippet,
  });

  factory ScriptureSearchResult.fromJson(Map<String, dynamic> json) {
    return ScriptureSearchResult(
      bookNumber: json['book_number'] ?? 0,
      bookGreek: json['book_greek'] ?? '',
      bookEnglish: json['book_english'] ?? '',
      chapter: json['chapter'] ?? 0,
      verse: json['verse'] ?? 0,
      snippet: json['snippet'] ?? '',
    );
  }
}
