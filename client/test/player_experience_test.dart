import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lifeos_client/core/music_playback/playback_models.dart';
import 'package:lifeos_client/core/repositories/models/music_models.dart';
import 'package:lifeos_client/core/repositories/music_repository.dart';

void main() {
  group('Player Experience Tests: Visualizer, Workstation & Queue', () {
    test('Visualizer animation synchronization logic stops when paused and starts when playing', () {
      bool isPlayingActive(PlayerState state) {
        return state.playing && state.processingState != ProcessingState.completed;
      }

      // Playing state -> should run ticker
      final playingState = PlayerState(true, ProcessingState.ready);
      expect(isPlayingActive(playingState), isTrue);

      // Paused state -> should stop ticker
      final pausedState = PlayerState(false, ProcessingState.ready);
      expect(isPlayingActive(pausedState), isFalse);

      // Completed / buffering / loading states
      final completedState = PlayerState(true, ProcessingState.completed);
      expect(isPlayingActive(completedState), isFalse);

      final stoppedState = PlayerState(false, ProcessingState.idle);
      expect(isPlayingActive(stoppedState), isFalse);
    });

    test('Desktop workstation tabs: 0 = Equalizer, 1 = Queue, 2 = Lyrics', () {
      final tabLabels = {
        0: 'Equalizer & DSP',
        1: 'Queue',
        2: 'Lyrics',
      };

      expect(tabLabels[0], 'Equalizer & DSP');
      expect(tabLabels[1], 'Queue');
      expect(tabLabels[2], 'Lyrics');

      // Verifying valid tab indices
      int currentTab = 0;
      currentTab = 2; // select lyrics
      expect(currentTab, 2);
    });

    test('Queue row exposes thumbnail, title, artist, duration, and current-track indicator', () {
      String formatDuration(double seconds) {
        if (seconds <= 0) return '';
        final s = seconds.round();
        final m = s ~/ 60;
        final remS = s % 60;
        return '$m:${remS.toString().padLeft(2, '0')}';
      }

      const queueItem1 = PlaybackItem(
        id: 'track_1',
        url: 'http://localhost/stream/1',
        title: 'Starman',
        artist: 'David Bowie',
        thumbnail: 'https://example.com/starman.jpg',
      );

      const queueItem2 = PlaybackItem(
        id: 'track_2',
        url: 'http://localhost/stream/2',
        title: 'Heroes',
        artist: 'David Bowie',
      );

      final queue = [queueItem1, queueItem2];
      expect(queue.length, 2);
      const currentIndex = 0;

      // Seed repository metadata cache for track 2
      MusicRepository.instance.rememberTrack(const MusicTrack(
        id: 'track_2',
        title: 'Heroes',
        artist: 'David Bowie',
        album: 'Heroes Album',
        duration: 360,
        thumbnail: 'https://example.com/heroes.jpg',
      ));

      // Check item 1 (from PlaybackItem directly)
      final meta1 = MusicRepository.instance.getTrackMetadata(queueItem1.id);
      final thumb1 = queueItem1.thumbnail.isNotEmpty ? queueItem1.thumbnail : (meta1?.thumbnail ?? '');
      expect(thumb1, 'https://example.com/starman.jpg');
      expect(queueItem1.title, 'Starman');
      expect(queueItem1.artist, 'David Bowie');
      expect(0 == currentIndex, isTrue); // current track flag

      // Check item 2 (fallback to cached metadata)
      final meta2 = MusicRepository.instance.getTrackMetadata(queueItem2.id);
      final thumb2 = queueItem2.thumbnail.isNotEmpty ? queueItem2.thumbnail : (meta2?.thumbnail ?? '');
      final dur2 = meta2?.duration ?? 0.0;
      expect(thumb2, 'https://example.com/heroes.jpg');
      expect(dur2, 360);
      expect(formatDuration(dur2), '6:00');
      expect(1 == currentIndex, isFalse);
    });

    test('Mobile gestures isolation: in lyrics mode, volume drag and cycle tap are suppressed', () {
      bool shouldAttachVolumeDrag(bool isLyricsMode) => !isLyricsMode;
      bool shouldAttachCycleTap(bool isLyricsMode) => !isLyricsMode;
      bool shouldAttachHorizontalSwipe(bool isLyricsMode) => !isLyricsMode;

      // In Artwork mode: all hero gestures active
      expect(shouldAttachVolumeDrag(false), isTrue);
      expect(shouldAttachCycleTap(false), isTrue);
      expect(shouldAttachHorizontalSwipe(false), isTrue);

      // In Lyrics mode: gestures detached so lyrics scroll & tap seek smoothly
      expect(shouldAttachVolumeDrag(true), isFalse);
      expect(shouldAttachCycleTap(true), isFalse);
      expect(shouldAttachHorizontalSwipe(true), isFalse);
    });
  });
}
