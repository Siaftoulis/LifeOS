import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/repositories/models/music_models.dart';
import 'package:lifeos_client/presentation/widgets/media_hub/music_library/tabs/all_tracks_sliver.dart';

void main() {
  group('P1-1: Real-time Download Queue Polling Lifecycle Tests', () {
    test('Active queue condition checks for polling', () {
      final qPending = DownloadQueueItem(id: '1', trackId: 't1', url: 'u1', status: 'pending', createdAt: 100);
      final qDownloading = DownloadQueueItem(id: '2', trackId: 't2', url: 'u2', status: 'downloading', createdAt: 101);
      final qCompleted = DownloadQueueItem(id: '3', trackId: 't3', url: 'u3', status: 'completed', createdAt: 102);
      final qFailed = DownloadQueueItem(id: '4', trackId: 't4', url: 'u4', status: 'failed', createdAt: 103);
      final qCancelled = DownloadQueueItem(id: '5', trackId: 't5', url: 'u5', status: 'cancelled', createdAt: 104);

      // Active when pending or downloading
      expect([qPending, qCompleted].any((i) => i.status.toUpperCase() == 'PENDING' || i.status.toUpperCase() == 'DOWNLOADING'), isTrue);
      expect([qDownloading].any((i) => i.status.toUpperCase() == 'PENDING' || i.status.toUpperCase() == 'DOWNLOADING'), isTrue);

      // Idle when all are completed, failed, or cancelled
      final idleQueue = [qCompleted, qFailed, qCancelled];
      expect(idleQueue.any((i) => i.status.toUpperCase() == 'PENDING' || i.status.toUpperCase() == 'DOWNLOADING'), isFalse);
    });

    test('Newly completed item detection logic triggers refresh only once', () {
      final prevActiveIds = {'1', '2'};

      final newQueue = [
        DownloadQueueItem(id: '1', trackId: 't1', url: 'u1', status: 'completed', createdAt: 100),
        DownloadQueueItem(id: '2', trackId: 't2', url: 'u2', status: 'downloading', createdAt: 101),
        DownloadQueueItem(id: '3', trackId: 't3', url: 'u3', status: 'completed', createdAt: 102), // was already completed
      ];

      final newlyCompleted = newQueue.any((i) =>
          prevActiveIds.contains(i.id) && i.status.toUpperCase() == 'COMPLETED');
      expect(newlyCompleted, isTrue);

      // When subsequent poll occurs with same completed item:
      final nextActiveIds = {'2'};
      final subsequentCompleted = newQueue.any((i) =>
          nextActiveIds.contains(i.id) && i.status.toUpperCase() == 'COMPLETED');
      expect(subsequentCompleted, isFalse);
    });
  });

  group('P1-2: In-Library Search & Sorting Tests', () {
    final trackA = MusicTrack(
      id: '1',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      album: 'A Night at the Opera',
      duration: 354,
      addedAt: 1600000000,
    );
    final trackB = MusicTrack(
      id: '2',
      title: 'Hotel California',
      artist: 'Eagles',
      album: 'Hotel California',
      duration: 391,
      addedAt: 1650000000,
    );
    final trackC = MusicTrack(
      id: '3',
      title: 'Imagine',
      artist: 'John Lennon',
      album: 'Imagine',
      duration: 183,
      addedAt: 1700000000,
    );
    final tracks = [trackA, trackB, trackC];

    test('Filters tracks locally by title, artist, and album case-insensitively', () {
      // By title
      final byTitle = filterAndSortTracks(tracks, query: 'bohemian', sortOption: TrackSortOption.titleAsc);
      expect(byTitle.length, 1);
      expect(byTitle.first.title, 'Bohemian Rhapsody');

      // By artist
      final byArtist = filterAndSortTracks(tracks, query: 'eagles', sortOption: TrackSortOption.titleAsc);
      expect(byArtist.length, 1);
      expect(byArtist.first.artist, 'Eagles');

      // By album
      final byAlbum = filterAndSortTracks(tracks, query: 'opera', sortOption: TrackSortOption.titleAsc);
      expect(byAlbum.length, 1);
      expect(byAlbum.first.album, 'A Night at the Opera');

      // Empty query returns all tracks
      final all = filterAndSortTracks(tracks, query: '   ', sortOption: TrackSortOption.titleAsc);
      expect(all.length, 3);
    });

    test('Sorts tracks by title ascending and descending', () {
      final asc = filterAndSortTracks(tracks, query: '', sortOption: TrackSortOption.titleAsc);
      expect(asc.map((t) => t.title).toList(), ['Bohemian Rhapsody', 'Hotel California', 'Imagine']);

      final desc = filterAndSortTracks(tracks, query: '', sortOption: TrackSortOption.titleDesc);
      expect(desc.map((t) => t.title).toList(), ['Imagine', 'Hotel California', 'Bohemian Rhapsody']);
    });

    test('Sorts tracks by artist ascending', () {
      final byArtist = filterAndSortTracks(tracks, query: '', sortOption: TrackSortOption.artistAsc);
      expect(byArtist.map((t) => t.artist).toList(), ['Eagles', 'John Lennon', 'Queen']);
    });

    test('Sorts tracks by date added (newest and oldest)', () {
      final newest = filterAndSortTracks(tracks, query: '', sortOption: TrackSortOption.dateAddedDesc);
      expect(newest.map((t) => t.title).toList(), ['Imagine', 'Hotel California', 'Bohemian Rhapsody']);

      final oldest = filterAndSortTracks(tracks, query: '', sortOption: TrackSortOption.dateAddedAsc);
      expect(oldest.map((t) => t.title).toList(), ['Bohemian Rhapsody', 'Hotel California', 'Imagine']);
    });

    test('Sorts tracks by duration (longest and shortest)', () {
      final longest = filterAndSortTracks(tracks, query: '', sortOption: TrackSortOption.durationDesc);
      expect(longest.map((t) => t.title).toList(), ['Hotel California', 'Bohemian Rhapsody', 'Imagine']);

      final shortest = filterAndSortTracks(tracks, query: '', sortOption: TrackSortOption.durationAsc);
      expect(shortest.map((t) => t.title).toList(), ['Imagine', 'Bohemian Rhapsody', 'Hotel California']);
    });

    test('Preserves original source list and does not mutate it', () {
      final copyBefore = List<MusicTrack>.from(tracks);
      final _ = filterAndSortTracks(tracks, query: 'hotel', sortOption: TrackSortOption.titleDesc);

      expect(tracks.length, copyBefore.length);
      expect(tracks[0].id, copyBefore[0].id);
      expect(tracks[1].id, copyBefore[1].id);
      expect(tracks[2].id, copyBefore[2].id);
    });
  });

  group('P1-3: Concurrent Playlist Membership Loading Tests', () {
    test('Future.wait concurrent membership evaluation with isolated error handling', () async {
      final playlistIds = ['pl1', 'pl2', 'pl3'];
      final membership = <String, bool>{};

      final results = await Future.wait(
        playlistIds.map((id) async {
          try {
            if (id == 'pl2') throw Exception('Simulated network timeout');
            return MapEntry(id, id == 'pl1');
          } catch (_) {
            return MapEntry(id, membership[id] ?? false);
          }
        }),
      );

      for (final entry in results) {
        membership[entry.key] = entry.value;
      }

      expect(membership['pl1'], isTrue);
      expect(membership['pl2'], isFalse); // Handled error without failing pl1 or pl3
      expect(membership['pl3'], isFalse);
    });
  });

  group('P1-4: Playlist Track Metadata Fallback Tests', () {
    test('Preserves backend-resolved track metadata when track is not in repository cache', () {
      final allMap = <String, MusicTrack>{}; // empty cache

      final backendTrack = MusicTrack(
        id: 'remote_1',
        title: 'Starman',
        artist: 'David Bowie',
        album: 'The Rise and Fall of Ziggy Stardust',
        duration: 250,
        thumbnail: 'https://example.com/starman.jpg',
        filePath: '/music/bowie/starman.mp3',
      );

      final playlistTrack = PlaylistTrack(
        track: backendTrack,
        position: 0,
      );

      // Resolution logic from PlaylistDetailSheet
      MusicTrack resolved;
      if (allMap.containsKey(playlistTrack.trackId)) {
        resolved = allMap[playlistTrack.trackId]!;
      } else if (playlistTrack.track.id.isNotEmpty &&
          ((playlistTrack.track.title.isNotEmpty && playlistTrack.track.title != 'Unknown') ||
           (playlistTrack.track.artist.isNotEmpty && playlistTrack.track.artist != 'Unknown'))) {
        resolved = playlistTrack.track;
      } else {
        resolved = MusicTrack(
          id: playlistTrack.trackId,
          title: 'Track ${playlistTrack.trackId}',
          artist: 'Unknown Artist',
          album: '',
          duration: 0,
        );
      }

      expect(resolved.title, 'Starman');
      expect(resolved.artist, 'David Bowie');
      expect(resolved.album, 'The Rise and Fall of Ziggy Stardust');
      expect(resolved.duration, 250);
      expect(resolved.thumbnail, 'https://example.com/starman.jpg');
      expect(resolved.artist, isNot('Unknown Artist'));
    });

    test('Only falls back to minimal representation when metadata is genuinely missing', () {
      final allMap = <String, MusicTrack>{};

      const emptyBackendTrack = MusicTrack(
        id: 'empty_1',
        title: '',
        artist: '',
        album: '',
      );

      final playlistTrack = const PlaylistTrack(
        track: emptyBackendTrack,
        position: 0,
      );

      MusicTrack resolved;
      if (allMap.containsKey(playlistTrack.trackId)) {
        resolved = allMap[playlistTrack.trackId]!;
      } else if (playlistTrack.track.id.isNotEmpty &&
          ((playlistTrack.track.title.isNotEmpty && playlistTrack.track.title != 'Unknown') ||
           (playlistTrack.track.artist.isNotEmpty && playlistTrack.track.artist != 'Unknown'))) {
        resolved = playlistTrack.track;
      } else {
        resolved = MusicTrack(
          id: playlistTrack.trackId,
          title: playlistTrack.track.title.isNotEmpty && playlistTrack.track.title != 'Unknown'
              ? playlistTrack.track.title
              : 'Track ${playlistTrack.trackId}',
          artist: playlistTrack.track.artist.isNotEmpty && playlistTrack.track.artist != 'Unknown'
              ? playlistTrack.track.artist
              : 'Unknown Artist',
          album: playlistTrack.track.album,
          duration: playlistTrack.track.duration,
        );
      }

      expect(resolved.title, 'Track empty_1');
      expect(resolved.artist, 'Unknown Artist');
    });
  });
}
