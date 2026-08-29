import 'package:drift/drift.dart';

@DataClassName('Movie')
class Movies extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get imdbId => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get status => text()(); // 'AVAILABLE', 'DOWNLOADING', 'WATCHED'
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MovieWatchlist')
class MovieWatchlists extends Table {
  TextColumn get id => text()();
  TextColumn get movieId => text().customConstraint('NOT NULL REFERENCES movies(id) ON DELETE CASCADE')();
  IntColumn get addedAt => integer()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MovieReview')
class MovieReviews extends Table {
  TextColumn get id => text()();
  TextColumn get movieId => text().customConstraint('NOT NULL REFERENCES movies(id) ON DELETE CASCADE')();
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  TextColumn get comment => text().nullable()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MusicTrack')
class MusicTracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get lyricsPath => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get ytDlpId => text().nullable()();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  IntColumn get bitrate => integer().nullable()();
  TextColumn get codec => text().nullable()();
  RealColumn get replayGainTrack => real().nullable()();
  RealColumn get replayGainAlbum => real().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  IntColumn get lastPlayedAt => integer().nullable()();
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LikedSong')
class LikedSongs extends Table {
  TextColumn get id => text().customConstraint('NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE')();
  IntColumn get likedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Playlist')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get coverArtUrl => text().nullable()();
  BoolColumn get isSmart => boolean().withDefault(const Constant(false))();
  TextColumn get smartType => text().nullable()();
  TextColumn get smartConfig => text().nullable()();
  IntColumn get trackCount => integer().withDefault(const Constant(0))();
  IntColumn get totalDuration => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistTrack')
class PlaylistTracks extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists(id) ON DELETE CASCADE')();
  TextColumn get trackId => text().customConstraint('NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE')();
  IntColumn get position => integer()();
  IntColumn get addedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id, playlistId, trackId};
}

@DataClassName('DownloadQueueItem')
class DownloadQueue extends Table {
  TextColumn get id => text()();
  TextColumn get trackId => text().customConstraint('NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE')();
  TextColumn get url => text()();
  TextColumn get destinationPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, downloading, completed, failed, cancelled
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  BoolColumn get wifiOnly => boolean().withDefault(const Constant(true))();
  BoolColumn get chargingOnly => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get startedAt => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ListeningEvent')
class ListeningHistory extends Table {
  TextColumn get id => text()();
  TextColumn get trackId => text().customConstraint('NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE')();
  IntColumn get playedAt => integer()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().nullable()();
  RealColumn get completionRate => real().nullable()();
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().nullable()(); // library, playlist:<id>, radio, search, offline
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OfflineMusicTrack')
class OfflineMusicTracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get thumbnail => text().nullable()();
  TextColumn get filePath => text()();
  RealColumn get duration => real().withDefault(const Constant(0.0))();
  IntColumn get downloadedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MediaAsset')
class MediaAssets extends Table {
  TextColumn get id => text()();
  TextColumn get filename => text()();
  TextColumn get filePath => text().customConstraint('NOT NULL UNIQUE')();
  IntColumn get fileSize => integer()();
  TextColumn get fileType => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get captureTime => integer()();
  TextColumn get scanStatus => text().withDefault(const Constant('PENDING'))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MediaTag')
class MediaTags extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text().customConstraint('NOT NULL REFERENCES media_assets(id) ON DELETE CASCADE')();
  TextColumn get tagName => text()();
  TextColumn get tagType => text()();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CloudAsset')
class CloudAssets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get filename => text()();
  TextColumn get type => text()();
  TextColumn get createdAt => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get hash => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get colors => text().withDefault(const Constant('[]'))();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get place => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get streamUrl => text().nullable()();
  IntColumn get syncedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

