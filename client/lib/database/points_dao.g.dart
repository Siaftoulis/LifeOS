// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_dao.dart';

// ignore_for_file: type=lint
mixin _$PointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SystemUsersTable get systemUsers => attachedDatabase.systemUsers;
  $PointRulesTable get pointRules => attachedDatabase.pointRules;
  $PointsLedgersTable get pointsLedgers => attachedDatabase.pointsLedgers;
  $VouchersTable get vouchers => attachedDatabase.vouchers;
  PointsDaoManager get managers => PointsDaoManager(this);
}

class PointsDaoManager {
  final _$PointsDaoMixin _db;
  PointsDaoManager(this._db);
  $$SystemUsersTableTableManager get systemUsers =>
      $$SystemUsersTableTableManager(_db.attachedDatabase, _db.systemUsers);
  $$PointRulesTableTableManager get pointRules =>
      $$PointRulesTableTableManager(_db.attachedDatabase, _db.pointRules);
  $$PointsLedgersTableTableManager get pointsLedgers =>
      $$PointsLedgersTableTableManager(_db.attachedDatabase, _db.pointsLedgers);
  $$VouchersTableTableManager get vouchers =>
      $$VouchersTableTableManager(_db.attachedDatabase, _db.vouchers);
}
