// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movies_dao.dart';

// ignore_for_file: type=lint
mixin _$MoviesDaoMixin on DatabaseAccessor<AppDatabase> {
  $MoviesTable get movies => attachedDatabase.movies;
  $MovieWatchlistsTable get movieWatchlists => attachedDatabase.movieWatchlists;
  $MovieReviewsTable get movieReviews => attachedDatabase.movieReviews;
  MoviesDaoManager get managers => MoviesDaoManager(this);
}

class MoviesDaoManager {
  final _$MoviesDaoMixin _db;
  MoviesDaoManager(this._db);
  $$MoviesTableTableManager get movies =>
      $$MoviesTableTableManager(_db.attachedDatabase, _db.movies);
  $$MovieWatchlistsTableTableManager get movieWatchlists =>
      $$MovieWatchlistsTableTableManager(
          _db.attachedDatabase, _db.movieWatchlists);
  $$MovieReviewsTableTableManager get movieReviews =>
      $$MovieReviewsTableTableManager(_db.attachedDatabase, _db.movieReviews);
}
