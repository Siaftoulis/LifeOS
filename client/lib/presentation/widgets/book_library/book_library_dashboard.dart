import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../api_client.dart';
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
    _syncBooksFromBackend();
  }

  Future<void> _syncBooksFromBackend() async {
    final db = AppDatabase.instance;
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/books');
      final List<dynamic> booksList = res as List<dynamic>;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var b in booksList) {
        final bookId = b['id'];
        final existingBook = await db.booksDao.getBookById(bookId);
        
        if (existingBook == null) {
          await db.booksDao.insertBook(BooksCompanion.insert(
            id: bookId, 
            title: b['title'] ?? 'Unknown', 
            author: Value(b['author']),
            currentPage: Value(b['current_page'] ?? 0), 
            totalPages: Value(b['total_pages'] ?? 1),
            filePath: b['file_path'] ?? '', 
            updatedAt: now, 
            isDirty: const Value(0),
          ));
        } else {
           // Optional: Update existing book if needed, omitting for now to not overwrite local reading progress 
        }
      }
    } catch (e) {
      debugPrint('Error syncing books: $e');
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
