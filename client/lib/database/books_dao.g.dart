// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'books_dao.dart';

// ignore_for_file: type=lint
mixin _$BooksDaoMixin on DatabaseAccessor<AppDatabase> {
  $BooksTable get books => attachedDatabase.books;
  $AudiobooksTable get audiobooks => attachedDatabase.audiobooks;
  $ReadingProgressTable get readingProgress => attachedDatabase.readingProgress;
  $BookHighlightsTable get bookHighlights => attachedDatabase.bookHighlights;
  BooksDaoManager get managers => BooksDaoManager(this);
}

class BooksDaoManager {
  final _$BooksDaoMixin _db;
  BooksDaoManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db.attachedDatabase, _db.books);
  $$AudiobooksTableTableManager get audiobooks =>
      $$AudiobooksTableTableManager(_db.attachedDatabase, _db.audiobooks);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(
          _db.attachedDatabase, _db.readingProgress);
  $$BookHighlightsTableTableManager get bookHighlights =>
      $$BookHighlightsTableTableManager(
          _db.attachedDatabase, _db.bookHighlights);
}
