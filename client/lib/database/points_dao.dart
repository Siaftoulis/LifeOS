import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

import 'package:flutter/foundation.dart';
import '../api_client.dart';

part 'points_dao.g.dart';

@DriftAccessor(tables: [SystemUsers, PointRules, PointsLedgers, Vouchers])
class PointsDao extends DatabaseAccessor<AppDatabase> with _$PointsDaoMixin {
  PointsDao(AppDatabase db) : super(db);

  Stream<List<SystemUser>> watchAllUsers() => select(systemUsers).watch();
  Stream<SystemUser?> watchAdminUser() => (select(systemUsers)..where((u) => u.id.equals('u-admin-1'))).watchSingleOrNull();
  Stream<List<PointsLedger>> watchRecentLedger() => (select(pointsLedgers)..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])).watch();
  Stream<List<Voucher>> watchAllVouchers() => select(vouchers).watch();
  Future<SystemUser?> getUserProfile(String id) => (select(systemUsers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertUser(SystemUsersCompanion entry) => into(systemUsers).insert(entry);
  Future<bool> updateUser(SystemUser user) => update(systemUsers).replace(user);
  Future<int> insertLedger(PointsLedgersCompanion entry) => into(pointsLedgers).insert(entry);
  Future<int> insertVoucher(VouchersCompanion entry) => into(vouchers).insert(entry);

  Future<void> awardPoints(int points, String event) async {
    await transaction(() async {
      final users = await watchAllUsers().first;
      if (users.isNotEmpty) {
        final user = users.first;
        final updatedUser = user.copyWith(
          currentPoints: user.currentPoints + points,
          updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          isDirty: 1,
        );
        await updateUser(updatedUser);
        await insertLedger(PointsLedgersCompanion.insert(
          id: 'l-${DateTime.now().millisecondsSinceEpoch}',
          userId: user.id,
          event: event,
          points: points,
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          isDirty: const Value(1),
        ));

        // Async sync to daemon
        try {
          ApiClient.instance.postDaemon('/api/v1/points/ledger', {
            'user_id': user.id,
            'event': event,
            'points': points,
          });
        } catch (e) {
          debugPrint('Daemon points sync deferred: $e');
        }
      }
    });
  }

  Future<bool> redeemVoucher(Voucher voucher) async {
    final users = await watchAllUsers().first;
    if (users.isEmpty) return false;
    final user = users.first;

    if (user.currentPoints < voucher.costPoints) return false;

    await awardPoints(-voucher.costPoints, 'Redeemed Voucher: ${voucher.title}');
    await (update(vouchers)..where((v) => v.id.equals(voucher.id))).write(
      VouchersCompanion(isRedeemed: const Value(1)),
    );

    try {
      await ApiClient.instance.postDaemon('/api/v1/points/vouchers/redeem', {
        'voucher_id': voucher.id,
        'user_id': user.id,
      });
    } catch (_) {}

    return true;
  }
}
