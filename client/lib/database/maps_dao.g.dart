// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maps_dao.dart';

// ignore_for_file: type=lint
mixin _$MapsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GeofencesTable get geofences => attachedDatabase.geofences;
  $LocationLogsTable get locationLogs => attachedDatabase.locationLogs;
  $BookmarksTable get bookmarks => attachedDatabase.bookmarks;
  MapsDaoManager get managers => MapsDaoManager(this);
}

class MapsDaoManager {
  final _$MapsDaoMixin _db;
  MapsDaoManager(this._db);
  $$GeofencesTableTableManager get geofences =>
      $$GeofencesTableTableManager(_db.attachedDatabase, _db.geofences);
  $$LocationLogsTableTableManager get locationLogs =>
      $$LocationLogsTableTableManager(_db.attachedDatabase, _db.locationLogs);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db.attachedDatabase, _db.bookmarks);
}
