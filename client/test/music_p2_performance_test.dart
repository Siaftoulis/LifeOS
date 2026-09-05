import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/repositories/models/music_models.dart';
import 'package:lifeos_client/presentation/widgets/media_hub/music_library/music_dashboard_widget.dart';
import 'package:lifeos_client/presentation/widgets/media_hub/music_library/music_formatters.dart';
import 'package:lifeos_client/presentation/widgets/media_hub/music_library/waveform_seekbar.dart';

void main() {
  group('P2 Music Performance & Polish Tests', () {
    // 1. WAVEFORM CACHE REUSE
    test('waveform cache reuses samples for the same track ID', () {
      final cache = BoundedWaveformCache(maxCapacity: 10);
      const trackId = 'track_starman';
      final samples = [0.1, 0.4, 0.8, 0.5, 0.2];

      expect(cache.get(trackId), isNull);

      cache.put(trackId, samples);

      final cached1 = cache.get(trackId);
      expect(cached1, isNotNull);
      expect(cached1, equals(samples));

      // Multiple reads return the identical cached sample list
      final cached2 = cache.get(trackId);
      expect(cached2, equals(samples));
    });

    // 2. WAVEFORM CACHE BOUNDED BEHAVIOR
    test('waveform cache enforces maxCapacity and LRU eviction', () {
      final cache = BoundedWaveformCache(maxCapacity: 3);

      cache.put('t1', [0.1]);
      cache.put('t2', [0.2]);
      cache.put('t3', [0.3]);
      expect(cache.length, 3);
      expect(cache.containsKey('t1'), isTrue);

      // Access t1 so t2 becomes the least recently used
      final t1 = cache.get('t1');
      expect(t1, equals([0.1]));

      // Inserting 4th track must evict t2
      cache.put('t4', [0.4]);
      expect(cache.length, 3);
      expect(cache.containsKey('t2'), isFalse); // Evicted
      expect(cache.containsKey('t1'), isTrue); // Retained
      expect(cache.containsKey('t3'), isTrue);
      expect(cache.containsKey('t4'), isTrue);

      // Inserting 5th track without accessing t3 should evict t3
      cache.put('t5', [0.5]);
      expect(cache.length, 3);
      expect(cache.containsKey('t3'), isFalse); // Evicted
      expect(cache.containsKey('t5'), isTrue);
    });

    // 3. GENRE CLASSIFICATION MEMOIZATION
    test('genre classification categorizes tracks correctly and memoizes results', () {
      MusicDashboardWidget.clearGenreCache();

      const greekTrack = MusicTrack(
        id: 'gr_1',
        title: 'Όλα Καλά',
        artist: 'Σάκης Ρουβάς',
        album: 'Pop Hits',
        duration: 210,
      );

      const rockTrack = MusicTrack(
        id: 'rk_1',
        title: 'Master of Puppets',
        artist: 'Metallica',
        album: 'Metal',
        duration: 515,
      );

      const hiphopTrack = MusicTrack(
        id: 'hh_1',
        title: 'Lose Yourself',
        artist: 'Eminem',
        album: '8 Mile',
        duration: 326,
      );

      const electronicTrack = MusicTrack(
        id: 'el_1',
        title: 'Levels',
        artist: 'Avicii',
        album: 'Club Anthems',
        duration: 200,
      );

      const acousticTrack = MusicTrack(
        id: 'ac_1',
        title: 'Someone Like You',
        artist: 'Adele',
        album: 'Piano Ballads',
        duration: 285,
      );

      const chillTrack = MusicTrack(
        id: 'ch_1',
        title: 'Sunset Vibes',
        artist: 'Lofi Boy',
        album: 'Relax Beats',
        duration: 180,
      );

      const popTrack = MusicTrack(
        id: 'pp_1',
        title: 'Bad Romance',
        artist: 'Lady Gaga',
        album: 'The Fame',
        duration: 295,
      );

      // Initial classification
      expect(MusicDashboardWidget.classifyTrackGenre(greekTrack), '🏛️ Greek / Ελληνικά');
      expect(MusicDashboardWidget.classifyTrackGenre(rockTrack), '🎸 Rock & Metal');
      expect(MusicDashboardWidget.classifyTrackGenre(hiphopTrack), '🎤 Hip-Hop & Rap');
      expect(MusicDashboardWidget.classifyTrackGenre(electronicTrack), '⚡ Electronic & Club');
      expect(MusicDashboardWidget.classifyTrackGenre(acousticTrack), '🌙 Acoustic & Ballads');
      expect(MusicDashboardWidget.classifyTrackGenre(chillTrack), '☕ Chill & Relax');
      expect(MusicDashboardWidget.classifyTrackGenre(popTrack), '✨ Pop & Chart Hits');

      // Memoized hits return identical genre strings
      expect(MusicDashboardWidget.classifyTrackGenre(greekTrack), '🏛️ Greek / Ελληνικά');
      expect(MusicDashboardWidget.classifyTrackGenre(rockTrack), '🎸 Rock & Metal');
    });

    // 4. DIRECT YOUTUBE URL DETECTION & ROUTING
    test('direct YouTube URL detection recognizes valid single video URLs', () {
      const urls = [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtube.com/watch?v=dQw4w9WgXcQ',
        'http://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        'https://www.youtube.com/v/dQw4w9WgXcQ',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&feature=shared',
        '   https://youtu.be/dQw4w9WgXcQ   ',
      ];

      for (final url in urls) {
        expect(isDirectYouTubeUrl(url), isTrue, reason: 'Failed for: $url');
        expect(extractYouTubeVideoId(url), equals('dQw4w9WgXcQ'), reason: 'Failed ID for: $url');
        expect(categorizeSearchQuery(url), equals(MusicSearchQueryType.directYouTubeUrl));
      }
    });

    // 5. NORMAL TEXT SEARCH PRESERVED
    test('normal text search queries remain categorized as normal queries', () {
      const normalQueries = [
        'David Bowie Starman',
        'Rick Astley Never Gonna Give You Up',
        'rock metal',
        'greek laiko hits',
        '12345',
      ];

      for (final query in normalQueries) {
        expect(isDirectYouTubeUrl(query), isFalse);
        expect(extractYouTubeVideoId(query), isNull);
        expect(categorizeSearchQuery(query), equals(MusicSearchQueryType.normalSearch));
      }
    });

    // 6. INVALID / NON-YOUTUBE URLS REMAIN NORMAL QUERIES
    test('invalid and non-YouTube URLs remain normal queries', () {
      const invalidUrls = [
        'https://example.com/watch?v=dQw4w9WgXcQ',
        'https://spotify.com/track/4cOdK2wGLETKBW3PvgPWqT',
        'https://soundcloud.com/artist/track',
        'https://youtube.com',
        'https://youtube.com/',
        'https://youtu.be/',
        'https://www.youtube.com/playlist?list=PL1234567890',
        'http://',
        'not a url at all',
      ];

      for (final url in invalidUrls) {
        expect(isDirectYouTubeUrl(url), isFalse, reason: 'Should not be direct YouTube: $url');
        expect(extractYouTubeVideoId(url), isNull);
        expect(categorizeSearchQuery(url), equals(MusicSearchQueryType.normalSearch));
      }
    });

    // 7. CONSOLIDATED MUSIC FORMATTERS
    test('common music formatters behave accurately and identically', () {
      expect(sanitizeMusicThumbnailUrl('http://example.com/img.jpg'), 'https://example.com/img.jpg');
      expect(sanitizeMusicThumbnailUrl('https://example.com/img.jpg'), 'https://example.com/img.jpg');
      expect(sanitizeMusicThumbnailUrl(''), '');

      expect(formatTrackDuration(0, allowEmpty: true), '');
      expect(formatTrackDuration(0, allowEmpty: false), '0:00');
      expect(formatTrackDuration(65), '1:05');
      expect(formatTrackDuration(214), '3:34');
      expect(formatTrackDuration(3665), '1:01:05');

      expect(formatDurationSpan(const Duration(seconds: 65)), '01:05');
      expect(formatDurationSpan(const Duration(seconds: 214)), '03:34');
      expect(formatDurationSpan(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(formatDurationSpan(const Duration(seconds: -10)), '00:00');
    });
  });
}
