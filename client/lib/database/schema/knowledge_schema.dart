import 'package:drift/drift.dart';

@DataClassName('MarkdownNote')
class MarkdownNotes extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text().customConstraint('NOT NULL UNIQUE')();
  TextColumn get frontmatterJson => text().nullable()();
  IntColumn get lastModified => integer()();
  TextColumn get hash => text()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NotesIndex')
class NotesIndices extends Table {
  TextColumn get id => text().customConstraint('NOT NULL REFERENCES markdown_notes(id) ON DELETE CASCADE')();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  TextColumn get referencesList => text().nullable()(); // COMMA separated links IDs
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Book')
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();
  IntColumn get totalPages => integer().withDefault(const Constant(0))();
  TextColumn get filePath => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Audiobook')
class Audiobooks extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().customConstraint('NOT NULL REFERENCES books(id) ON DELETE CASCADE')();
  TextColumn get filePath => text()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get currentSeconds => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ReadingProgress extends Table {
  TextColumn get bookId => text().customConstraint('NOT NULL REFERENCES books(id) ON DELETE CASCADE')();
  IntColumn get page => integer().withDefault(const Constant(0))();
  IntColumn get seconds => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get syncedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {bookId};
}

@DataClassName('BookHighlight')
class BookHighlights extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().customConstraint('NOT NULL REFERENCES books(id) ON DELETE CASCADE')();
  TextColumn get textContent => text()();
  TextColumn get noteContent => text().nullable()();
  IntColumn get pageNumber => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FlashcardDeck')
class FlashcardDecks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Flashcard')
class Flashcards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().customConstraint('NOT NULL REFERENCES flashcard_decks(id) ON DELETE CASCADE')();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get nextReview => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FlashcardReview')
class FlashcardReviews extends Table {
  TextColumn get id => text()();
  TextColumn get cardId => text().customConstraint('NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE')();
  IntColumn get timestamp => integer()();
  IntColumn get quality => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('KnowledgeTopic')
class KnowledgeTopics extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get category => text()(); // 'TECH', 'SCIENCE', 'PHILOSOPHY', 'HISTORY'
  TextColumn get status => text()(); // 'LEARNING', 'COMPLETED', 'BACKLOG'
  TextColumn get notePath => text().customConstraint('NOT NULL UNIQUE')();
  IntColumn get lastStudied => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('KnowledgeRelationship')
class KnowledgeRelationships extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().customConstraint('NOT NULL REFERENCES knowledge_topics(id) ON DELETE CASCADE')();
  TextColumn get targetId => text().customConstraint('NOT NULL REFERENCES knowledge_topics(id) ON DELETE CASCADE')();
  TextColumn get relationType => text()(); // 'REQUIRES', 'EXPANDS', 'CONTRADICTS'
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Bookmark')
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

