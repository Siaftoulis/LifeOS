import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../api_client.dart';
import '../../database/database.dart';
import 'base_daemon_repository.dart';
import 'models/domain_models.dart';

/// Points balance (`GET /api/v1/points/balance`), polled every 10s.
class PointsRepository extends DaemonRepository {
  static final PointsRepository instance = PointsRepository._();

  PointsRepository._();

  final ValueNotifier<PointsBalance> balance =
      ValueNotifier(const PointsBalance(points: 0, stars: 0));

  @override
  Future<void> load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/points/balance');
      if (res is Map) {
        balance.value = PointsBalance.fromJson(Map<String, dynamic>.from(res));
        await _mirrorLocal(balance.value.points);
      }
    } catch (_) {}
  }

  /// Server truth → local drift mirror (u-admin-1), so widgets that read the
  /// local stream (gating, star panels, voucher panel) follow the daemon.
  /// ponytail: silent fail — offline keeps the last known local value.
  Future<void> _mirrorLocal(int serverPoints) async {
    try {
      final db = AppDatabase.instance;
      final user = await db.pointsDao.getUserProfile('u-admin-1');
      if (user != null && user.currentPoints != serverPoints) {
        await db.pointsDao.updateUser(user.copyWith(
          currentPoints: serverPoints,
          updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          isDirty: 0,
        ));
      }
    } catch (_) {}
  }

  Future<void> refresh() async => load();
}
