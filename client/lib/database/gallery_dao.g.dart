// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_dao.dart';

// ignore_for_file: type=lint
mixin _$GalleryDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaAssetsTable get mediaAssets => attachedDatabase.mediaAssets;
  $MediaTagsTable get mediaTags => attachedDatabase.mediaTags;
  GalleryDaoManager get managers => GalleryDaoManager(this);
}

class GalleryDaoManager {
  final _$GalleryDaoMixin _db;
  GalleryDaoManager(this._db);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db.attachedDatabase, _db.mediaAssets);
  $$MediaTagsTableTableManager get mediaTags =>
      $$MediaTagsTableTableManager(_db.attachedDatabase, _db.mediaTags);
}
