// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'darkweb_dao.dart';

// ignore_for_file: type=lint
mixin _$DarkWebDaoMixin on DatabaseAccessor<AppDatabase> {
  $TorrentsTable get torrents => attachedDatabase.torrents;
  $TorrentPeersTable get torrentPeers => attachedDatabase.torrentPeers;
  $SharedFilesTable get sharedFiles => attachedDatabase.sharedFiles;
  DarkWebDaoManager get managers => DarkWebDaoManager(this);
}

class DarkWebDaoManager {
  final _$DarkWebDaoMixin _db;
  DarkWebDaoManager(this._db);
  $$TorrentsTableTableManager get torrents =>
      $$TorrentsTableTableManager(_db.attachedDatabase, _db.torrents);
  $$TorrentPeersTableTableManager get torrentPeers =>
      $$TorrentPeersTableTableManager(_db.attachedDatabase, _db.torrentPeers);
  $$SharedFilesTableTableManager get sharedFiles =>
      $$SharedFilesTableTableManager(_db.attachedDatabase, _db.sharedFiles);
}
