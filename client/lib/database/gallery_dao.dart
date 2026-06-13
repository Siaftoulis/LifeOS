import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'gallery_dao.g.dart';

@DriftAccessor(tables: [MediaAssets, MediaTags])
class GalleryDao extends DatabaseAccessor<AppDatabase> with _$GalleryDaoMixin {
  GalleryDao(AppDatabase db) : super(db);

  Stream<List<MediaAsset>> watchAllAssets() => select(mediaAssets).watch();
  
  Future<int> insertAsset(MediaAssetsCompanion entry) => into(mediaAssets).insert(entry);
  Future<int> insertTag(MediaTagsCompanion entry) => into(mediaTags).insert(entry);
}
