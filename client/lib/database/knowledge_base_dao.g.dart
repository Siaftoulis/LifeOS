// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_base_dao.dart';

// ignore_for_file: type=lint
mixin _$KnowledgeBaseDaoMixin on DatabaseAccessor<AppDatabase> {
  $KnowledgeTopicsTable get knowledgeTopics => attachedDatabase.knowledgeTopics;
  $KnowledgeRelationshipsTable get knowledgeRelationships =>
      attachedDatabase.knowledgeRelationships;
  KnowledgeBaseDaoManager get managers => KnowledgeBaseDaoManager(this);
}

class KnowledgeBaseDaoManager {
  final _$KnowledgeBaseDaoMixin _db;
  KnowledgeBaseDaoManager(this._db);
  $$KnowledgeTopicsTableTableManager get knowledgeTopics =>
      $$KnowledgeTopicsTableTableManager(
          _db.attachedDatabase, _db.knowledgeTopics);
  $$KnowledgeRelationshipsTableTableManager get knowledgeRelationships =>
      $$KnowledgeRelationshipsTableTableManager(
          _db.attachedDatabase, _db.knowledgeRelationships);
}
