import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'home_management_dao.g.dart';

@DriftAccessor(tables: [SmartDevices, EnvironmentLogs, DeviceSchedules])
class HomeManagementDao extends DatabaseAccessor<AppDatabase> with _$HomeManagementDaoMixin {
  HomeManagementDao(AppDatabase db) : super(db);

  Stream<List<SmartDevice>> watchAllDevices() => select(smartDevices).watch();
  Stream<List<EnvironmentLog>> watchLogs(String sensorId) =>
      (select(environmentLogs)..where((t) => t.sensorId.equals(sensorId))).watch();

  Future<int> insertDevice(SmartDevicesCompanion entry) => into(smartDevices).insert(entry);
  Future<int> insertLog(EnvironmentLogsCompanion entry) => into(environmentLogs).insert(entry);
}
