// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_dao.dart';

// ignore_for_file: type=lint
mixin _$MusicDaoMixin on DatabaseAccessor<AppDatabase> {
  $MusicTracksTable get musicTracks => attachedDatabase.musicTracks;
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $PlaylistTracksTable get playlistTracks => attachedDatabase.playlistTracks;
  $OfflineMusicTracksTable get offlineMusicTracks =>
      attachedDatabase.offlineMusicTracks;
  $LikedSongsTable get likedSongs => attachedDatabase.likedSongs;
  $DownloadQueueTable get downloadQueue => attachedDatabase.downloadQueue;
  $ListeningHistoryTable get listeningHistory =>
      attachedDatabase.listeningHistory;
  MusicDaoManager get managers => MusicDaoManager(this);
}

class MusicDaoManager {
  final _$MusicDaoMixin _db;
  MusicDaoManager(this._db);
  $$MusicTracksTableTableManager get musicTracks =>
      $$MusicTracksTableTableManager(_db.attachedDatabase, _db.musicTracks);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(
          _db.attachedDatabase, _db.playlistTracks);
  $$OfflineMusicTracksTableTableManager get offlineMusicTracks =>
      $$OfflineMusicTracksTableTableManager(
          _db.attachedDatabase, _db.offlineMusicTracks);
  $$LikedSongsTableTableManager get likedSongs =>
      $$LikedSongsTableTableManager(_db.attachedDatabase, _db.likedSongs);
  $$DownloadQueueTableTableManager get downloadQueue =>
      $$DownloadQueueTableTableManager(_db.attachedDatabase, _db.downloadQueue);
  $$ListeningHistoryTableTableManager get listeningHistory =>
      $$ListeningHistoryTableTableManager(
          _db.attachedDatabase, _db.listeningHistory);
}
