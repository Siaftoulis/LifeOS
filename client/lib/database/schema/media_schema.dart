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
  IntColumn get trackNumber => integer().nullable()();
  TextColumn get filePath => text()();
  TextColumn get lyricsPath => text().nullable()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Playlist')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistTrack')
class PlaylistTracks extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists(id) ON DELETE CASCADE')();
  TextColumn get trackId => text().customConstraint('NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE')();
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

