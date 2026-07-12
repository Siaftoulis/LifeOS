// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dao.dart';

// ignore_for_file: type=lint
mixin _$LifeEntitiesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LifeEntitiesTable get lifeEntities => attachedDatabase.lifeEntities;
  LifeEntitiesDaoManager get managers => LifeEntitiesDaoManager(this);
}

class LifeEntitiesDaoManager {
  final _$LifeEntitiesDaoMixin _db;
  LifeEntitiesDaoManager(this._db);
  $$LifeEntitiesTableTableManager get lifeEntities =>
      $$LifeEntitiesTableTableManager(_db.attachedDatabase, _db.lifeEntities);
}
