import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'cloud_dao.g.dart';

@DriftAccessor(tables: [DeviceBackups, BackupLogs, UploadQuarantines])
class CloudDao extends DatabaseAccessor<AppDatabase> with _$CloudDaoMixin {
  CloudDao(AppDatabase db) : super(db);

  Stream<List<DeviceBackup>> watchAllBackups() => select(deviceBackups).watch();
  Stream<List<BackupLog>> watchLogs(String deviceId) =>
      (select(backupLogs)..where((t) => t.deviceId.equals(deviceId))).watch();
  Stream<List<UploadQuarantine>> watchQuarantine() => select(uploadQuarantines).watch();

  Future<int> insertBackup(DeviceBackupsCompanion entry) => into(deviceBackups).insert(entry);
  Future<int> insertLog(BackupLogsCompanion entry) => into(backupLogs).insert(entry);
  Future<int> insertQuarantine(UploadQuarantinesCompanion entry) => into(uploadQuarantines).insert(entry);
}
