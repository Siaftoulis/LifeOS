import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'points_dao.g.dart';

@DriftAccessor(tables: [SystemUsers, PointRules, PointsLedgers, Vouchers])
class PointsDao extends DatabaseAccessor<AppDatabase> with _$PointsDaoMixin {
  PointsDao(AppDatabase db) : super(db);

  Stream<List<SystemUser>> watchAllUsers() => select(systemUsers).watch();
  Stream<List<PointsLedger>> watchRecentLedger() => (select(pointsLedgers)..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])).watch();
  Stream<List<Voucher>> watchAllVouchers() => select(vouchers).watch();
  Future<SystemUser?> getUserProfile(String id) => (select(systemUsers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertUser(SystemUsersCompanion entry) => into(systemUsers).insert(entry);
  Future<bool> updateUser(SystemUser user) => update(systemUsers).replace(user);
  Future<int> insertLedger(PointsLedgersCompanion entry) => into(pointsLedgers).insert(entry);
  Future<int> insertVoucher(VouchersCompanion entry) => into(vouchers).insert(entry);
}
