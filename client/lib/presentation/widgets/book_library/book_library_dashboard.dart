import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import 'book_card_widget.dart';
import 'highlight_curtain.dart';

class BookLibraryDashboard extends StatefulWidget {
  const BookLibraryDashboard({super.key});

  @override
  State<BookLibraryDashboard> createState() => _BookLibraryDashboardState();
}

class _BookLibraryDashboardState extends State<BookLibraryDashboard> {
  @override
  void initState() {
    super.initState();
    _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    final db = AppDatabase.instance;
    final existing = await db.booksDao.watchAllBooks().first;
    if (existing.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.booksDao.insertBook(BooksCompanion.insert(
        id: 'book-1', title: 'The Pragmatic Programmer', author: const Value('Andrew Hunt'),
        currentPage: const Value(45), totalPages: const Value(320),
        filePath: 'storage/books/pragmatic.epub', updatedAt: now, isDirty: const Value(0),
      ));
      await db.booksDao.insertBook(BooksCompanion.insert(
        id: 'book-2', title: 'Clean Code', author: const Value('Robert C. Martin'),
        currentPage: const Value(120), totalPages: const Value(464),
        filePath: 'storage/books/cleancode.epub', updatedAt: now, isDirty: const Value(0),
      ));
      await db.booksDao.insertAudiobook(AudiobooksCompanion.insert(
        id: 'audio-2', bookId: 'book-2', filePath: 'storage/audiobooks/cleancode.mp3',
        durationSeconds: const Value(36000), currentSeconds: const Value(7200),
        updatedAt: now, isDirty: const Value(0),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Book Library', style: TextStyle(color: EverforestColors.fg)),
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => showDialog(context: context, builder: (_) => const HighlightCurtain()),
          ),
        ],
      ),
      body: StreamBuilder<List<Book>>(
        stream: db.booksDao.watchAllBooks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final books = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) => BookCardWidget(book: books[index]),
          );
        },
      ),
    );
  }
}
