import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/music_playback/playback_controller.dart';
import 'package:lifeos_client/core/music_playback/playback_models.dart';
import 'package:lifeos_client/core/repositories/models/music_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Music Playback, Queue & Playlist Integration Tests', () {
    test('Local track PlaybackItem retains valid filePath and direct url for playback', () {
      const localPath = r'C:\Music\Pink Floyd - Time.mp3';
      const coverPath = r'C:\Users\AppData\album_covers\pf_time.jpg';

      const localTrack = MusicTrack(
        id: 'local_e99a18c428cb38d5f260853678922e03',
        title: 'Time',
        artist: 'Pink Floyd',
        album: 'The Dark Side of the Moon',
        thumbnail: coverPath,
        thumbnailUrl: coverPath,
        filePath: localPath,
        duration: 425.0,
      );

      final item = PlaybackItem(
        id: localTrack.id,
        url: localTrack.filePath.isNotEmpty ? localTrack.filePath : '',
        title: localTrack.title,
        artist: localTrack.artist,
        album: localTrack.album,
        thumbnail: localTrack.thumbnail,
        filePath: localTrack.filePath,
      );

      expect(item.id, equals('local_e99a18c428cb38d5f260853678922e03'));
      expect(item.filePath, equals(localPath));
      expect(item.url, equals(localPath));
      expect(item.thumbnail, equals(coverPath));
    });

    test('PlaybackController manages queue and next track insertions for local items', () {
      final controller = PlaybackController.instance;

      const item1 = PlaybackItem(
        id: 'local_1',
        url: r'C:\Music\Song1.mp3',
        title: 'Song 1',
        artist: 'Artist 1',
        filePath: r'C:\Music\Song1.mp3',
      );
      const item2 = PlaybackItem(
        id: 'local_2',
        url: r'C:\Music\Song2.mp3',
        title: 'Song 2',
        artist: 'Artist 2',
        filePath: r'C:\Music\Song2.mp3',
      );
      const itemNext = PlaybackItem(
        id: 'local_next',
        url: r'C:\Music\SongNext.mp3',
        title: 'Song Next',
        artist: 'Artist Next',
        filePath: r'C:\Music\SongNext.mp3',
      );

      controller.setQueue([item1, item2], currentIndex: 0);
      expect(controller.queue.length, equals(2));
      expect(controller.currentItem?.id, equals('local_1'));

      // Test playNext (insertNext)
      controller.insertNext(itemNext);
      expect(controller.queue.length, equals(3));
      expect(controller.queue[1].id, equals('local_next'));

      // Test addToQueue
      const itemQueue = PlaybackItem(
        id: 'local_queued',
        url: r'C:\Music\SongQueued.mp3',
        title: 'Song Queued',
        artist: 'Artist Queued',
        filePath: r'C:\Music\SongQueued.mp3',
      );
      controller.addToQueue(itemQueue);
      expect(controller.queue.length, equals(4));
      expect(controller.queue.last.id, equals('local_queued'));
      expect(controller.queue.last.filePath, equals(r'C:\Music\SongQueued.mp3'));
    });

    test('PlaylistTrack deserialization and local track mapping preserves metadata', () {
      final jsonPayload = {
        'position': 3,
        'track': {
          'id': 'local_123',
          'title': 'Echoes',
          'artist': 'Pink Floyd',
          'album': 'Meddle',
          'thumbnail': r'C:\Covers\meddle.jpg',
          'thumbnail_url': r'C:\Covers\meddle.jpg',
          'file_path': r'C:\Music\echoes.flac',
          'duration': 1410.0,
        },
      };

      final playlistTrack = PlaylistTrack.fromJson(jsonPayload);
      expect(playlistTrack.position, equals(3));
      expect(playlistTrack.trackId, equals('local_123'));
      expect(playlistTrack.track.title, equals('Echoes'));
      expect(playlistTrack.track.filePath, equals(r'C:\Music\echoes.flac'));
      expect(playlistTrack.track.thumbnail, equals(r'C:\Covers\meddle.jpg'));
    });

    test('Smart Playlist models serialize and deserialize smartType and smartConfig correctly', () {
      final create = PlaylistCreate(
        name: '80s Rock Anthems',
        description: 'Auto generated mix for 1980s rock',
        isSmart: true,
        smartType: 'genre',
        smartConfig: 'Rock',
      );

      final json = create.toJson();
      expect(json['name'], equals('80s Rock Anthems'));
      expect(json['is_smart'], isTrue);
      expect(json['smart_type'], equals('genre'));
      expect(json['smart_config'], equals('Rock'));

      final playlist = Playlist.fromJson({
        'id': 'pl_smart_123',
        'name': '80s Rock Anthems',
        'description': 'Auto generated mix for 1980s rock',
        'is_smart': true,
        'smart_type': 'genre',
        'smart_config': 'Rock',
        'track_count': 42,
        'total_duration': 9800,
        'created_at': 1726084800,
        'updated_at': 1726084800,
      });

      expect(playlist.id, equals('pl_smart_123'));
      expect(playlist.isSmart, isTrue);
      expect(playlist.smartType, equals('genre'));
      expect(playlist.smartConfig, equals('Rock'));
      expect(playlist.trackCount, equals(42));
      expect(playlist.totalDuration, equals(9800));
    });

    test('Offline track radio seeds properly and retains local file playback paths', () {
      final controller = PlaybackController.instance;

      const offlineSeed = PlaybackItem(
        id: 'local_offline_seed_99',
        url: r'C:\Music\Rock\Queen - Bohemian Rhapsody.flac',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        genre: 'Rock',
        year: 1975,
        filePath: r'C:\Music\Rock\Queen - Bohemian Rhapsody.flac',
      );

      controller.setQueue([offlineSeed], currentIndex: 0);
      expect(controller.currentItem?.id, equals('local_offline_seed_99'));
      expect(controller.currentItem?.filePath, equals(r'C:\Music\Rock\Queen - Bohemian Rhapsody.flac'));
      expect(controller.currentItem?.artist, equals('Queen'));
      expect(controller.currentItem?.genre, equals('Rock'));

      // Simulate appending local recommendations to radio queue
      const radioPick1 = PlaybackItem(
        id: 'local_offline_rec_1',
        url: r'C:\Music\Rock\Led Zeppelin - Stairway to Heaven.flac',
        title: 'Stairway to Heaven',
        artist: 'Led Zeppelin',
        genre: 'Rock',
        year: 1971,
        filePath: r'C:\Music\Rock\Led Zeppelin - Stairway to Heaven.flac',
      );
      controller.addToQueue(radioPick1);

      expect(controller.queue.length, equals(2));
      expect(controller.queue.last.id, equals('local_offline_rec_1'));
      expect(controller.queue.last.filePath, equals(r'C:\Music\Rock\Led Zeppelin - Stairway to Heaven.flac'));
    });
  });
}
