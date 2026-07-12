// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_dao.dart';

// ignore_for_file: type=lint
mixin _$CloudDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeviceBackupsTable get deviceBackups => attachedDatabase.deviceBackups;
  $BackupLogsTable get backupLogs => attachedDatabase.backupLogs;
  $UploadQuarantinesTable get uploadQuarantines =>
      attachedDatabase.uploadQuarantines;
  CloudDaoManager get managers => CloudDaoManager(this);
}

class CloudDaoManager {
  final _$CloudDaoMixin _db;
  CloudDaoManager(this._db);
  $$DeviceBackupsTableTableManager get deviceBackups =>
      $$DeviceBackupsTableTableManager(_db.attachedDatabase, _db.deviceBackups);
  $$BackupLogsTableTableManager get backupLogs =>
      $$BackupLogsTableTableManager(_db.attachedDatabase, _db.backupLogs);
  $$UploadQuarantinesTableTableManager get uploadQuarantines =>
      $$UploadQuarantinesTableTableManager(
          _db.attachedDatabase, _db.uploadQuarantines);
}
