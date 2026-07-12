// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markdown_dao.dart';

// ignore_for_file: type=lint
mixin _$MarkdownDaoMixin on DatabaseAccessor<AppDatabase> {
  $MarkdownNotesTable get markdownNotes => attachedDatabase.markdownNotes;
  $NotesIndicesTable get notesIndices => attachedDatabase.notesIndices;
  MarkdownDaoManager get managers => MarkdownDaoManager(this);
}

class MarkdownDaoManager {
  final _$MarkdownDaoMixin _db;
  MarkdownDaoManager(this._db);
  $$MarkdownNotesTableTableManager get markdownNotes =>
      $$MarkdownNotesTableTableManager(_db.attachedDatabase, _db.markdownNotes);
  $$NotesIndicesTableTableManager get notesIndices =>
      $$NotesIndicesTableTableManager(_db.attachedDatabase, _db.notesIndices);
}
