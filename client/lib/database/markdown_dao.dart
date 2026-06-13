import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'markdown_dao.g.dart';

@DriftAccessor(tables: [MarkdownNotes, NotesIndices])
class MarkdownDao extends DatabaseAccessor<AppDatabase> with _$MarkdownDaoMixin {
  MarkdownDao(AppDatabase db) : super(db);

  Stream<List<MarkdownNote>> watchAllNotes() {
    return select(markdownNotes).watch();
  }

  Future<int> insertNote(MarkdownNotesCompanion note) {
    return into(markdownNotes).insert(note);
  }

  Future<bool> updateNote(MarkdownNotesCompanion note) {
    return update(markdownNotes).replace(note);
  }

  Future<void> markDirty(String id) async {
    await (update(markdownNotes)..where((t) => t.id.equals(id))).write(
      const MarkdownNotesCompanion(
        isDirty: Value(1),
      ),
    );
  }
}
