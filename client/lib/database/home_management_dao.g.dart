// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_management_dao.dart';

// ignore_for_file: type=lint
mixin _$HomeManagementDaoMixin on DatabaseAccessor<AppDatabase> {
  $SmartDevicesTable get smartDevices => attachedDatabase.smartDevices;
  $EnvironmentLogsTable get environmentLogs => attachedDatabase.environmentLogs;
  $DeviceSchedulesTable get deviceSchedules => attachedDatabase.deviceSchedules;
  HomeManagementDaoManager get managers => HomeManagementDaoManager(this);
}

class HomeManagementDaoManager {
  final _$HomeManagementDaoMixin _db;
  HomeManagementDaoManager(this._db);
  $$SmartDevicesTableTableManager get smartDevices =>
      $$SmartDevicesTableTableManager(_db.attachedDatabase, _db.smartDevices);
  $$EnvironmentLogsTableTableManager get environmentLogs =>
      $$EnvironmentLogsTableTableManager(
          _db.attachedDatabase, _db.environmentLogs);
  $$DeviceSchedulesTableTableManager get deviceSchedules =>
      $$DeviceSchedulesTableTableManager(
          _db.attachedDatabase, _db.deviceSchedules);
}
