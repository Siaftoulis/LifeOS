import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'books_dao.g.dart';

@DriftAccessor(tables: [Books, Audiobooks, ReadingProgress, BookHighlights])
class BooksDao extends DatabaseAccessor<AppDatabase> with _$BooksDaoMixin {
  BooksDao(AppDatabase db) : super(db);

  Stream<List<Book>> watchAllBooks() => select(books).watch();
  
  Stream<List<Audiobook>> watchAllAudiobooks() => select(audiobooks).watch();
  
  Stream<List<ReadingProgressData>> watchAllReadingProgress() => select(readingProgress).watch();

  Stream<List<BookHighlight>> watchHighlightsForBook(String bookId) => 
      (select(bookHighlights)..where((t) => t.bookId.equals(bookId))).watch();

  Stream<List<BookHighlight>> watchAllHighlights() => select(bookHighlights).watch();

  Future<int> insertBook(BooksCompanion entry) => into(books).insert(entry);
  
  Future<int> insertAudiobook(AudiobooksCompanion entry) => into(audiobooks).insert(entry);
  
  Future<int> insertReadingProgress(ReadingProgressCompanion entry) => 
      into(readingProgress).insertOnConflictUpdate(entry);
  
  Future<int> insertHighlight(BookHighlightsCompanion entry) => into(bookHighlights).insert(entry);

  Future<void> updateBookProgress(String id, int page, int currentEpochMs) async {
    await (update(books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        currentPage: Value(page),
        updatedAt: Value(currentEpochMs),
        isDirty: const Value(1),
      ),
    );
  }

  Future<void> updateAudiobookProgress(String id, int currentSeconds, int currentEpochMs) async {
    await (update(audiobooks)..where((t) => t.id.equals(id))).write(
      AudiobooksCompanion(
        currentSeconds: Value(currentSeconds),
        updatedAt: Value(currentEpochMs),
        isDirty: const Value(1),
      ),
    );
  }
}
