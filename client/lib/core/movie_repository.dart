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
        status: json['status']?.toString() ?? '',
        posterUrl: json['poster_url']?.toString() ?? '',
        overview: json['overview']?.toString() ?? '',
        genres: json['genres']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        tmdbRating: (json['tmdb_rating'] as num?)?.toDouble() ?? 0,
      );
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
    } catch (_) {
      // daemon offline: keep last known list
    }
  }

  Future<void> addToWatchlist(String id) async {
    try {
      await ApiClient.instance
          .postDaemon('/api/v1/movies/watchlist', {'movie_id': id});
      await refresh();
      TelemetryReporter.instance.track('movies', 'watchlist_added', {'movie_id': id});
    } catch (_) {}
  }

  Future<void> saveReview(String id, double rating, String comment) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/movies/reviews', {
        'movie_id': id,
        'rating': rating,
        'comment': comment,
      });
      await refresh();
      TelemetryReporter.instance.track('movies', 'review_added', {'movie_id': id});
    } catch (_) {}
  }

  Future<void> setStatus(String id, String status) async {
    try {
      await ApiClient.instance.putDaemon('/api/v1/movies/$id', {
        'status': status,
      });
      await refresh();
      TelemetryReporter.instance.track('movies', 'status_changed', {'movie_id': id});
    } catch (_) {}
  }

  void dispose() {
    _pollTimer?.cancel();
    movies.dispose();
  }
}
