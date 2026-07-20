import 'package:drift/drift.dart';

@DataClassName('SmartDevice')
class SmartDevices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'LIGHT', 'SWITCH', 'THERMOSTAT', 'APPLIANCE'
  TextColumn get state => text()(); // 'ON', 'OFF', 'UNKNOWN'
  TextColumn get room => text().nullable()();
  IntColumn get lastUpdated => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EnvironmentLog')
class EnvironmentLogs extends Table {
  TextColumn get id => text()();
  TextColumn get sensorId => text()();
  RealColumn get temperature => real().nullable()();
  RealColumn get humidity => real().nullable()();
  IntColumn get timestamp => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DeviceSchedule')
class DeviceSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text().customConstraint('NOT NULL REFERENCES smart_devices(id) ON DELETE CASCADE')();
  TextColumn get action => text()(); // 'TURN_ON', 'TURN_OFF'
  TextColumn get cronExpression => text()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Geofence')
class Geofences extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radius => real()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocationLog')
class LocationLogs extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get velocity => real().nullable()();
  RealColumn get altitude => real().nullable()();
  IntColumn get timestamp => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VirtualMachine')
class VirtualMachines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get state => text()();
  IntColumn get cpuLimit => integer().withDefault(const Constant(1))();
  IntColumn get ramLimit => integer().withDefault(const Constant(512))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

