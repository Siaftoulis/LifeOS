// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vm_dao.dart';

// ignore_for_file: type=lint
mixin _$VmDaoMixin on DatabaseAccessor<AppDatabase> {
  $VirtualMachinesTable get virtualMachines => attachedDatabase.virtualMachines;
  $RemoteSessionsTable get remoteSessions => attachedDatabase.remoteSessions;
  VmDaoManager get managers => VmDaoManager(this);
}

class VmDaoManager {
  final _$VmDaoMixin _db;
  VmDaoManager(this._db);
  $$VirtualMachinesTableTableManager get virtualMachines =>
      $$VirtualMachinesTableTableManager(
          _db.attachedDatabase, _db.virtualMachines);
  $$RemoteSessionsTableTableManager get remoteSessions =>
      $$RemoteSessionsTableTableManager(
          _db.attachedDatabase, _db.remoteSessions);
}
