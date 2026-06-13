import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'knowledge_base_dao.g.dart';

@DriftAccessor(tables: [KnowledgeTopics, KnowledgeRelationships])
class KnowledgeBaseDao extends DatabaseAccessor<AppDatabase> with _$KnowledgeBaseDaoMixin {
  KnowledgeBaseDao(AppDatabase db) : super(db);

  Stream<List<KnowledgeTopic>> watchAllTopics() => select(knowledgeTopics).watch();
  Stream<List<KnowledgeRelationship>> watchRelationships(String topicId) =>
      (select(knowledgeRelationships)..where((t) => t.sourceId.equals(topicId) | t.targetId.equals(topicId))).watch();

  Future<int> insertTopic(KnowledgeTopicsCompanion entry) => into(knowledgeTopics).insert(entry);
  Future<int> insertRelationship(KnowledgeRelationshipsCompanion entry) => into(knowledgeRelationships).insert(entry);
}
