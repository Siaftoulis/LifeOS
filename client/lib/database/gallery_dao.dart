import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'gallery_dao.g.dart';

@DriftAccessor(tables: [MediaAssets, MediaTags, CloudAssets])
class GalleryDao extends DatabaseAccessor<AppDatabase> with _$GalleryDaoMixin {
  GalleryDao(AppDatabase db) : super(db);

  Stream<List<MediaAsset>> watchAllAssets() => select(mediaAssets).watch();
  
  Future<int> insertAsset(MediaAssetsCompanion entry) => into(mediaAssets).insert(entry);
  Future<int> insertTag(MediaTagsCompanion entry) => into(mediaTags).insert(entry);
  Future<List<MediaAsset>> getAllAssets() => select(mediaAssets).get();
  Future<int> insertOrUpdateAsset(MediaAssetsCompanion entry) => into(mediaAssets).insertOnConflictUpdate(entry);

  // Cloud assets caching
  Stream<List<CloudAsset>> watchCloudAssets() => select(cloudAssets).watch();
  
  Future<int> insertCloudAsset(CloudAssetsCompanion entry) => into(cloudAssets).insert(entry);
  Future<int> insertOrUpdateCloudAsset(CloudAssetsCompanion entry) => into(cloudAssets).insertOnConflictUpdate(entry);
  Future<List<CloudAsset>> getCloudAssets({int limit = 50, int offset = 0}) => 
      (select(cloudAssets)..orderBy([(t) => OrderingTerm.desc(t.syncedAt)])..limit(limit, offset: offset)).get();
  Future<int> getCloudAssetsCount() {
    return customSelect('SELECT COUNT(*) as c FROM cloud_assets')
        .getSingle()
        .then((row) => row.read<int>('c'));
  }
  Future<void> clearCloudAssets() => delete(cloudAssets).go();
}
