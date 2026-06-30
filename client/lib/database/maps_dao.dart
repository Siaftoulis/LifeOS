import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'maps_dao.g.dart';

@DriftAccessor(tables: [Geofences, LocationLogs, Bookmarks])
class MapsDao extends DatabaseAccessor<AppDatabase> with _$MapsDaoMixin {
  MapsDao(AppDatabase db) : super(db);

  Stream<List<Geofence>> watchAllGeofences() => select(geofences).watch();
  Stream<List<LocationLog>> watchRecentLogs() => 
      (select(locationLogs)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])..limit(100)).watch();
  Stream<List<Bookmark>> watchBookmarks() => select(bookmarks).watch();

  Future<int> insertGeofence(GeofencesCompanion entry) => into(geofences).insert(entry);
  Future<int> insertLocationLog(LocationLogsCompanion entry) => into(locationLogs).insert(entry);
  Future<int> insertBookmark(BookmarksCompanion entry) => into(bookmarks).insert(entry);

  Future<int> deleteGeofence(String id) =>
      (delete(geofences)..where((t) => t.id.equals(id))).go();
  Future<int> deleteBookmark(String id) =>
      (delete(bookmarks)..where((t) => t.id.equals(id))).go();

  Future<int> updateGeofenceActive(String id, bool active) =>
      (update(geofences)..where((t) => t.id.equals(id)))
          .write(GeofencesCompanion(isActive: Value(active ? 1 : 0)));
}
