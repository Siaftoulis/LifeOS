import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/music_playback/playback_controller.dart';
import 'package:lifeos_client/core/music_playback/playback_models.dart';
import 'package:lifeos_client/core/repositories/models/music_models.dart';

void main() {
  group('P0-1: Shuffle & Repeat PlaybackController Tests', () {
    test('PlaybackController shuffle control functions properly', () {
      final pc = PlaybackController.instance;
      // Reset initial state
      pc.setShuffle(false);
      expect(pc.shuffle, isFalse);

      // Explicit setShuffle
      pc.setShuffle(true);
      expect(pc.shuffle, isTrue);

      pc.setShuffle(false);
      expect(pc.shuffle, isFalse);

      // Toggle
      pc.toggleShuffle();
      expect(pc.shuffle, isTrue);

      pc.toggleShuffle();
      expect(pc.shuffle, isFalse);
    });

    test('PlaybackController repeat control sets correctly', () {
      final pc = PlaybackController.instance;
      pc.setRepeat(PlaybackRepeat.off);
      expect(pc.repeat, PlaybackRepeat.off);

      pc.setRepeat(PlaybackRepeat.all);
      expect(pc.repeat, PlaybackRepeat.all);

      pc.setRepeat(PlaybackRepeat.one);
      expect(pc.repeat, PlaybackRepeat.one);

      pc.setRepeat(PlaybackRepeat.off);
      expect(pc.repeat, PlaybackRepeat.off);
    });
  });

  group('P0-2: Download Queue Item & Metadata Tests', () {
    test('DownloadQueueItem displayTitle, artist, thumbnail fallback priority', () {
      // 1. Raw item without custom metadata: falls back to trackId
      final rawItem = DownloadQueueItem(
        id: '1',
        trackId: 'dQw4w9WgXcQ',
        url: 'https://youtube.com/watch?v=dQw4w9WgXcQ',
        status: 'pending',
        createdAt: 1000,
      );
      expect(rawItem.displayTitle(), 'dQw4w9WgXcQ');
      expect(rawItem.displayArtist(), 'LifeOS Library');
      expect(rawItem.displayThumbnail(), '');

      // 2. Item with custom metadata (from library/search cache)
      final enrichedItem = rawItem.copyWith(
        customTitle: 'Never Gonna Give You Up',
        customArtist: 'Rick Astley',
        customThumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      );
      expect(enrichedItem.displayTitle(), 'Never Gonna Give You Up');
      expect(enrichedItem.displayArtist(), 'Rick Astley');
      expect(enrichedItem.displayThumbnail(), 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg');
    });

    test('DownloadQueueItem handles failed status and errorMessage', () {
      final failedItem = DownloadQueueItem(
        id: '3',
        trackId: 'abc1234',
        url: 'https://youtube.com/watch?v=abc1234',
        status: 'failed',
        errorMessage: 'HTTP 403: Private video or copyright restriction',
        createdAt: 2000,
      );

      expect(failedItem.status, 'failed');
      expect(failedItem.errorMessage, contains('HTTP 403'));
    });

    test('Active queue state checks for polling', () {
      final pendingItem = DownloadQueueItem(id: '1', trackId: 'v1', url: 'u1', status: 'pending', createdAt: 1);
      final downloadingItem = DownloadQueueItem(id: '2', trackId: 'v2', url: 'u2', status: 'downloading', createdAt: 2);
      final completedItem = DownloadQueueItem(id: '3', trackId: 'v3', url: 'u3', status: 'completed', createdAt: 3);
      final failedItem = DownloadQueueItem(id: '4', trackId: 'v4', url: 'u4', status: 'failed', createdAt: 4);

      final activeList = [pendingItem, downloadingItem, completedItem];
      final hasActive = activeList.any((i) => i.status == 'pending' || i.status == 'downloading');
      expect(hasActive, isTrue);

      final inactiveList = [completedItem, failedItem];
      final hasInactiveActive = inactiveList.any((i) => i.status == 'pending' || i.status == 'downloading');
      expect(hasInactiveActive, isFalse);
    });
  });
}
