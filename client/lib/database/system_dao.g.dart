// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_dao.dart';

// ignore_for_file: type=lint
mixin _$SystemDaoMixin on DatabaseAccessor<AppDatabase> {
  $SystemSettingsTable get systemSettings => attachedDatabase.systemSettings;
  $UserProfilesTable get userProfiles => attachedDatabase.userProfiles;
  SystemDaoManager get managers => SystemDaoManager(this);
}

class SystemDaoManager {
  final _$SystemDaoMixin _db;
  SystemDaoManager(this._db);
  $$SystemSettingsTableTableManager get systemSettings =>
      $$SystemSettingsTableTableManager(
          _db.attachedDatabase, _db.systemSettings);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db.attachedDatabase, _db.userProfiles);
}
