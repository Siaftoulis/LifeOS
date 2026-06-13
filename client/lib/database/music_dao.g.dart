// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_dao.dart';

// ignore_for_file: type=lint
mixin _$MusicDaoMixin on DatabaseAccessor<AppDatabase> {
  $MusicTracksTable get musicTracks => attachedDatabase.musicTracks;
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $PlaylistTracksTable get playlistTracks => attachedDatabase.playlistTracks;
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
}
