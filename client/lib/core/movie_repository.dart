import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api_client.dart';
import 'telemetry/telemetry_reporter.dart';

/// Canonical movie record as served by `GET /api/v1/movies`.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.director,
    required this.year,
    required this.status,
    this.imdbId = '',
    this.posterUrl = '',
    this.overview = '',
    this.genres = '',
    this.colorHex = '',
    this.rating = 0,
    this.tmdbRating = 0,
  });

  final String id;
  final String imdbId;
  final String title;
  final String director;
  final String year;
  final String colorHex;
  final String status;
  final String posterUrl;
  final String overview;
  final String genres;
  final double rating;
  final double tmdbRating;

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: json['id']?.toString() ?? '',
        imdbId: json['imdb_id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown Title',
        director: json['director']?.toString() ?? '',
        year: json['year']?.toString() ?? '',
        colorHex: json['color']?.toString() ?? '',
        status: json['status']?.toString() ?? 'AVAILABLE',
        posterUrl: json['poster_url']?.toString() ?? '',
        overview: json['overview']?.toString() ?? '',
        genres: json['genres']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        tmdbRating: (json['tmdb_rating'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imdb_id': imdbId,
        'title': title,
        'director': director,
        'year': year,
        'color': colorHex,
        'status': status,
        'poster_url': posterUrl,
        'overview': overview,
        'genres': genres,
        'rating': rating,
        'tmdb_rating': tmdbRating,
      };
}

/// Single client-side source for movies: polls the daemon and pushes writes
/// (watchlist, review, status). Offline: reads fail silently, writes are
/// best-effort — the daemon is the canonical store.
class MovieRepository {
  static final MovieRepository instance = MovieRepository._internal();

  MovieRepository._internal() {
    _startPolling();
  }

  final ValueNotifier<List<Movie>> movies = ValueNotifier(const []);
  final ValueNotifier<Set<String>> watchlistIds = ValueNotifier({});
  Timer? _pollTimer;

  void _startPolling() {
    refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/movies');
      if (res is List) {
        movies.value = res
            .whereType<Map>()
            .map((m) => Movie.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      await _loadWatchlist();
    } catch (_) {
      // daemon offline: keep last known list
    }
  }

  Future<void> _loadWatchlist() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/movies/watchlist');
      if (res is List) {
        watchlistIds.value = res
            .whereType<Map>()
            .map((m) => m['movie_id']?.toString() ?? m['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      }
    } catch (_) {}
  }

  Future<List<Movie>> searchOnline(String query) async {
    try {
      final res = await ApiClient.instance
          .getDaemon('/api/v1/movies/search?q=${Uri.encodeComponent(query)}');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => Movie.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<bool> addMovie(Movie movie) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/movies', movie.toJson());
      await refresh();
      TelemetryReporter.instance
          .track('movies', 'movie_added', {'movie_id': movie.id});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMovie(String id) async {
    try {
      await ApiClient.instance.deleteDaemon('/api/v1/movies/$id');
      await refresh();
      TelemetryReporter.instance
          .track('movies', 'movie_deleted', {'movie_id': id});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> addToWatchlist(String id) async {
    try {
      await ApiClient.instance
          .postDaemon('/api/v1/movies/watchlist', {'movie_id': id});
      watchlistIds.value = {...watchlistIds.value, id};
      await refresh();
      TelemetryReporter.instance
          .track('movies', 'watchlist_added', {'movie_id': id});
    } catch (_) {}
  }

  Future<void> removeFromWatchlist(String id) async {
    try {
      await ApiClient.instance
          .deleteDaemon('/api/v1/movies/watchlist?movie_id=$id');
      watchlistIds.value = watchlistIds.value.where((item) => item != id).toSet();
      await refresh();
      TelemetryReporter.instance
          .track('movies', 'watchlist_removed', {'movie_id': id});
    } catch (_) {}
  }

  bool isInWatchlist(String id) => watchlistIds.value.contains(id);

  Future<void> saveReview(String id, double rating, String comment) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/movies/reviews', {
        'movie_id': id,
        'rating': rating,
        'comment': comment,
      });
      await refresh();
      TelemetryReporter.instance
          .track('movies', 'review_added', {'movie_id': id});
    } catch (_) {}
  }

  Future<void> setStatus(String id, String status) async {
    try {
      await ApiClient.instance.putDaemon('/api/v1/movies/$id', {
        'status': status,
      });
      await refresh();
      TelemetryReporter.instance
          .track('movies', 'status_changed', {'movie_id': id});
    } catch (_) {}
  }

  void dispose() {
    _pollTimer?.cancel();
    movies.dispose();
    watchlistIds.dispose();
  }
}
