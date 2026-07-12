// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'infinity_dao.dart';

// ignore_for_file: type=lint
mixin _$InfinityDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyWordsTable get dailyWords => attachedDatabase.dailyWords;
  $DailyTriviasTable get dailyTrivias => attachedDatabase.dailyTrivias;
  InfinityDaoManager get managers => InfinityDaoManager(this);
}

class InfinityDaoManager {
  final _$InfinityDaoMixin _db;
  InfinityDaoManager(this._db);
  $$DailyWordsTableTableManager get dailyWords =>
      $$DailyWordsTableTableManager(_db.attachedDatabase, _db.dailyWords);
  $$DailyTriviasTableTableManager get dailyTrivias =>
      $$DailyTriviasTableTableManager(_db.attachedDatabase, _db.dailyTrivias);
}
