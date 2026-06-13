import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'home_screen_dao.g.dart';

@DriftAccessor(tables: [SystemUsers, LocalNotifications])
class HomeScreenDao extends DatabaseAccessor<AppDatabase> with _$HomeScreenDaoMixin {
  HomeScreenDao(AppDatabase db) : super(db);

  Stream<SystemUser?> watchCurrentUser() => select(systemUsers).watchSingleOrNull();
  Stream<List<LocalNotification>> watchUnreadNotifications() =>
      (select(localNotifications)..where((t) => t.readAt.isNull())).watch();

  Future<int> insertUser(SystemUsersCompanion entry) => into(systemUsers).insert(entry);
  Future<int> insertNotification(LocalNotificationsCompanion entry) => into(localNotifications).insert(entry);
}
