import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'movies_dao.g.dart';

@DriftAccessor(tables: [Movies, MovieWatchlists, MovieReviews])
class MoviesDao extends DatabaseAccessor<AppDatabase> with _$MoviesDaoMixin {
  MoviesDao(AppDatabase db) : super(db);

  Stream<List<Movie>> watchAllMovies() => select(movies).watch();
  Stream<List<MovieWatchlist>> watchWatchlist() => 
      (select(movieWatchlists)..orderBy([(t) => OrderingTerm.desc(t.priority)])).watch();
  Stream<List<MovieReview>> watchReviews() => select(movieReviews).watch();

  Future<int> insertMovie(MoviesCompanion entry) => into(movies).insert(entry);
  Future<int> insertWatchlist(MovieWatchlistsCompanion entry) => into(movieWatchlists).insert(entry);
  Future<int> insertReview(MovieReviewsCompanion entry) => into(movieReviews).insert(entry);
}
