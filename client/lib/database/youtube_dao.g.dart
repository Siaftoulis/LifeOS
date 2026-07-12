// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_dao.dart';

// ignore_for_file: type=lint
mixin _$YoutubeDaoMixin on DatabaseAccessor<AppDatabase> {
  $YoutubeSessionsTable get youtubeSessions => attachedDatabase.youtubeSessions;
  $YoutubeDownloadsTable get youtubeDownloads =>
      attachedDatabase.youtubeDownloads;
  YoutubeDaoManager get managers => YoutubeDaoManager(this);
}

class YoutubeDaoManager {
  final _$YoutubeDaoMixin _db;
  YoutubeDaoManager(this._db);
  $$YoutubeSessionsTableTableManager get youtubeSessions =>
      $$YoutubeSessionsTableTableManager(
          _db.attachedDatabase, _db.youtubeSessions);
  $$YoutubeDownloadsTableTableManager get youtubeDownloads =>
      $$YoutubeDownloadsTableTableManager(
          _db.attachedDatabase, _db.youtubeDownloads);
}
