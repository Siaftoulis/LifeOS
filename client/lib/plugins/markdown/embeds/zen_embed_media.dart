import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';
import '../../../core/movie_repository.dart' as repo;
import '../../../core/domain_repositories.dart' show MusicTrack, MusicRepository;
import '../../../database/database.dart' hide MusicTrack;
import 'zen_embed_models.dart';

/// Fetches one entity from the daemon and renders a metadata card. Shared by
/// the movie and book embeds; data stays server-side, nothing is copied.
class _SingleEntityEmbed extends StatefulWidget {
  const _SingleEntityEmbed({
    required this.ref,
    required this.endpoint,
    required this.notFoundMessage,
    required this.subtitle,
    required this.status,
    this.leading,
    this.meta,
    this.rating,
  });

  final String ref;
  final String endpoint;
  final String notFoundMessage;
  final Widget? Function(Map<String, dynamic> entity)? leading;
  final String Function(Map<String, dynamic> entity) subtitle;
  final String Function(Map<String, dynamic> entity)? meta;
  final dynamic Function(Map<String, dynamic> entity)? rating;
  final String Function(Map<String, dynamic> entity) status;

  @override
  State<_SingleEntityEmbed> createState() => _SingleEntityEmbedState();
}

class _SingleEntityEmbedState extends State<_SingleEntityEmbed> {
  Map<String, dynamic>? _entity;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await ApiClient.instance.getDaemon('${widget.endpoint}/${widget.ref}');
      if (mounted) {
        setState(() => _entity = res is Map ? Map<String, dynamic>.from(res) : null);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Text(
          widget.notFoundMessage,
          style: const TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    final e = _entity;
    if (e == null) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }

    Color color = EverforestColors.bg2;
    try {
      color = Color(int.parse(e['color']));
    } catch (_) {}

    final ratingValue = widget.rating?.call(e);
    final rating =
        (ratingValue is num) ? ratingValue.toDouble() : 0.0;
    final meta = widget.meta?.call(e) ?? '';
    final leading = widget.leading?.call(e);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e['title'] as String? ?? 'Unknown Title',
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating > 0)
                      const Icon(Icons.star, size: 14, color: EverforestColors.yellow),
                    if (rating > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle(e),
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  widget.status(e),
                  style: const TextStyle(
                    color: EverforestColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Books
// ---------------------------------------------------------------------------

class BooksEmbedPreview extends StatelessWidget {
  const BooksEmbedPreview({super.key, this.ref});

  /// Single-book embed reference (book id from the daemon).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SingleBookEmbed(ref: ref!);
    }
    return StreamBuilder<List<Book>>(
      stream: AppDatabase.instance.booksDao.watchAllBooks(),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <Book>[])
            .take(8)
            .map((b) => EmbedCardData(
                  b.title,
                  b.author ?? '',
                  EverforestColors.bg2,
                ))
            .toList();
        return CardStrip(items: items);
      },
    );
  }
}

class _SingleBookEmbed extends StatelessWidget {
  const _SingleBookEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SingleEntityEmbed(
      ref: ref,
      endpoint: '/api/v1/books',
      notFoundMessage: 'Book not found — tap to open the library',
      leading: (b) => Container(
        width: 48,
        height: 68,
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.menu_book_outlined,
          color: EverforestColors.green,
          size: 26,
        ),
      ),
      subtitle: (b) =>
          '${b['author'] ?? ''} • ${b['current_page'] ?? 0}/${b['total_pages'] ?? 0} p.',
      status: (b) {
        final s = b['status']?.toString() ?? '';
        final page = (b['current_page'] is num) ? (b['current_page'] as num).toInt() : 0;
        final total = (b['total_pages'] is num) ? (b['total_pages'] as num).toInt() : 0;
        if (s.isNotEmpty && page > 0 && total > 0) {
          return '$s — page $page of $total';
        }
        return s;
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Movies
// ---------------------------------------------------------------------------

class MoviesEmbedPreview extends StatelessWidget {
  const MoviesEmbedPreview({super.key, this.ref});

  /// Single-movie embed reference (movie id from the daemon).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SingleMovieEmbed(ref: ref!);
    }
    return ValueListenableBuilder<List<repo.Movie>>(
      valueListenable: repo.MovieRepository.instance.movies,
      builder: (context, movies, child) {
        final items = movies
            .take(8)
            .map((m) {
              Color color = EverforestColors.bg2;
              try {
                color = Color(int.parse(m.colorHex));
              } catch (_) {}
              return EmbedCardData(
                m.title,
                '${m.director} • ${m.year}',
                color,
              );
            })
            .toList();
        return CardStrip(items: items);
      },
    );
  }
}

class _SingleMovieEmbed extends StatelessWidget {
  const _SingleMovieEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SingleEntityEmbed(
      ref: ref,
      endpoint: '/api/v1/movies',
      notFoundMessage: 'Movie not found — tap to open the library',
      leading: (m) {
        final posterUrl = m['poster_url'] as String? ?? '';
        if (posterUrl.isEmpty) return null;
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            posterUrl,
            width: 48,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      },
      subtitle: (m) => '${m['director'] ?? ''} • ${m['year'] ?? ''}',
      meta: (m) => m['genres'] as String? ?? '',
      rating: (m) => m['rating'],
      status: (m) => m['status']?.toString() ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Music
// ---------------------------------------------------------------------------

class MusicEmbedPreview extends StatelessWidget {
  const MusicEmbedPreview({super.key, this.ref});

  /// Single-track embed reference (track id from the daemon).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SingleTrackEmbed(ref: ref!);
    }
    return ValueListenableBuilder<List<MusicTrack>>(
      valueListenable: MusicRepository.instance.tracks,
      builder: (context, tracks, child) {
        final items = tracks
            .take(8)
            .map((t) => EmbedCardData(
                  t.title,
                  t.artist,
                  EverforestColors.green.withValues(alpha: 0.35),
                ))
            .toList();
        return CardStrip(items: items);
      },
    );
  }
}

class _SingleTrackEmbed extends StatelessWidget {
  const _SingleTrackEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SingleEntityEmbed(
      ref: ref,
      endpoint: '/api/v1/music/tracks',
      notFoundMessage: 'Track not found — tap to open the library',
      leading: (t) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.music_note_outlined,
          color: EverforestColors.green,
          size: 24,
        ),
      ),
      subtitle: (t) => '${t['artist'] ?? ''} • ${t['album'] ?? ''}',
      status: (t) => (t['album'] as String? ?? '').isNotEmpty ? 'Album track' : '',
    );
  }
}
