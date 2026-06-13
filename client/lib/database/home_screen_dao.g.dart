// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_screen_dao.dart';

// ignore_for_file: type=lint
mixin _$HomeScreenDaoMixin on DatabaseAccessor<AppDatabase> {
  $SystemUsersTable get systemUsers => attachedDatabase.systemUsers;
  $LocalNotificationsTable get localNotifications =>
      attachedDatabase.localNotifications;
  HomeScreenDaoManager get managers => HomeScreenDaoManager(this);
}

class HomeScreenDaoManager {
  final _$HomeScreenDaoMixin _db;
  HomeScreenDaoManager(this._db);
  $$SystemUsersTableTableManager get systemUsers =>
      $$SystemUsersTableTableManager(_db.attachedDatabase, _db.systemUsers);
  $$LocalNotificationsTableTableManager get localNotifications =>
      $$LocalNotificationsTableTableManager(
          _db.attachedDatabase, _db.localNotifications);
}
