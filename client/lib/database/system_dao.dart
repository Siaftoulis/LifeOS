import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'system_dao.g.dart';

@DriftAccessor(tables: [SystemSettings, UserProfiles])
class SystemDao extends DatabaseAccessor<AppDatabase> with _$SystemDaoMixin {
  SystemDao(AppDatabase db) : super(db);

  Stream<List<SystemSetting>> watchSettings() => select(systemSettings).watch();
  Stream<List<UserProfile>> watchProfiles() => select(userProfiles).watch();

  Future<int> insertSetting(SystemSettingsCompanion entry) => into(systemSettings).insert(entry);
  Future<int> insertProfile(UserProfilesCompanion entry) => into(userProfiles).insert(entry);
}
