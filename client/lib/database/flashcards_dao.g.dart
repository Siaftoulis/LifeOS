// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcards_dao.dart';

// ignore_for_file: type=lint
mixin _$FlashcardsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FlashcardDecksTable get flashcardDecks => attachedDatabase.flashcardDecks;
  $FlashcardsTable get flashcards => attachedDatabase.flashcards;
  $FlashcardReviewsTable get flashcardReviews =>
      attachedDatabase.flashcardReviews;
  FlashcardsDaoManager get managers => FlashcardsDaoManager(this);
}

class FlashcardsDaoManager {
  final _$FlashcardsDaoMixin _db;
  FlashcardsDaoManager(this._db);
  $$FlashcardDecksTableTableManager get flashcardDecks =>
      $$FlashcardDecksTableTableManager(
          _db.attachedDatabase, _db.flashcardDecks);
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db.attachedDatabase, _db.flashcards);
  $$FlashcardReviewsTableTableManager get flashcardReviews =>
      $$FlashcardReviewsTableTableManager(
          _db.attachedDatabase, _db.flashcardReviews);
}
