import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'flashcards_dao.g.dart';

@DriftAccessor(tables: [FlashcardDecks, Flashcards, FlashcardReviews])
class FlashcardsDao extends DatabaseAccessor<AppDatabase> with _$FlashcardsDaoMixin {
  FlashcardsDao(AppDatabase db) : super(db);

  Stream<List<FlashcardDeck>> watchAllDecks() => select(flashcardDecks).watch();
  Stream<List<Flashcard>> watchCards(String deckId) =>
      (select(flashcards)..where((t) => t.deckId.equals(deckId))).watch();

  Future<int> insertDeck(FlashcardDecksCompanion entry) => into(flashcardDecks).insert(entry);
  Future<int> insertCard(FlashcardsCompanion entry) => into(flashcards).insert(entry);
}
