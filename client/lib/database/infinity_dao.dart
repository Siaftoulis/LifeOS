import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'infinity_dao.g.dart';

@DriftAccessor(tables: [DailyWords, DailyTrivias])
class InfinityDao extends DatabaseAccessor<AppDatabase> with _$InfinityDaoMixin {
  InfinityDao(AppDatabase db) : super(db);

  Stream<List<DailyWord>> watchDailyWords() => (select(dailyWords)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();
  Stream<List<DailyTrivia>> watchDailyTrivias() => (select(dailyTrivias)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();

  Future<int> insertWord(DailyWordsCompanion entry) => into(dailyWords).insert(entry);
  Future<int> insertTrivia(DailyTriviasCompanion entry) => into(dailyTrivias).insert(entry);
}
