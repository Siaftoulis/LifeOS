import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import '../../api_client.dart';
import '../../database/database.dart';
import '../../database/books_dao.dart';
import '../telemetry/telemetry_reporter.dart';

class BookRepository {
  static final BookRepository instance = BookRepository._internal();

  BookRepository._internal();

  BooksDao get _dao => AppDatabase.instance.booksDao;

  /// Sync books from Go host daemon to local Drift SQLite database
  Future<void> syncFromDaemon() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/books');
      if (res is List) {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (var b in res) {
          if (b is! Map) continue;
          final bookId = b['id']?.toString() ?? '';
          if (bookId.isEmpty) continue;

          final existing = await _dao.getBookById(bookId);
          if (existing == null) {
            await _dao.insertBook(BooksCompanion.insert(
              id: bookId,
              title: b['title']?.toString() ?? 'Unknown',
              author: Value(b['author']?.toString()),
              currentPage: Value((b['current_page'] as num?)?.toInt() ?? 0),
              totalPages: Value((b['total_pages'] as num?)?.toInt() ?? 1),
              filePath: b['file_path']?.toString() ?? '',
              updatedAt: now,
              isDirty: const Value(0),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('BookRepository sync error: $e');
    }
  }

  /// Update reading progress locally and push to daemon
  Future<void> updateProgress(
      String bookId, int currentPage, int totalPages) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // 1. Update Drift DB
    await _dao.updateBookProgress(bookId, currentPage, now);

    // 2. Push to Daemon
    try {
      final progressPct =
          totalPages > 0 ? (currentPage / totalPages) * 100 : 0.0;
      await ApiClient.instance.postDaemon('/api/v1/books/progress', {
        'book_id': bookId,
        'current_page': currentPage,
        'total_pages': totalPages,
        'progress_pct': progressPct,
      });
      TelemetryReporter.instance.track('books', 'progress_updated', {
        'book_id': bookId,
        'page': currentPage,
      });
    } catch (e) {
      debugPrint('Book progress daemon push error: $e');
    }
  }

  /// Delete book from local DB and remote daemon
  Future<bool> deleteBook(String bookId) async {
    try {
      await _dao.deleteBook(bookId);
      await ApiClient.instance.deleteDaemon('/api/v1/books/$bookId');
      TelemetryReporter.instance
          .track('books', 'book_deleted', {'book_id': bookId});
      return true;
    } catch (e) {
      debugPrint('Book deletion error: $e');
      return false;
    }
  }

  /// Search online sources (Gutenberg, OpenLibrary, MangaDex, Anna's Archive)
  Future<List<Map<String, dynamic>>> searchSources(String query) async {
    try {
      final res = await ApiClient.instance.postDaemon(
        '/api/v1/books/search',
        {'query': query},
      );
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
    } catch (e) {
      debugPrint('Book source search error: $e');
    }
    return const [];
  }

  /// Trigger download of a book from search sources
  Future<bool> downloadBook(Map<String, dynamic> sourceResult) async {
    try {
      await ApiClient.instance.postDaemon(
        '/api/v1/books/download',
        sourceResult,
      );
      await syncFromDaemon();
      return true;
    } catch (e) {
      debugPrint('Book download error: $e');
      return false;
    }
  }
}
