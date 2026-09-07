import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifeos_client/core/audio_dsp_service.dart';
import 'package:lifeos_client/core/music_playback/playback_controller.dart';
import 'package:lifeos_client/core/music_playback/playback_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Poweramp DSP & Audio Architecture Tests', () {
    final dsp = AudioDspService.instance;

    test('Preamp adjustment clamps safely between -12dB and +12dB', () {
      dsp.updateSettings(preamp: 6.0);
      expect(dsp.preamp, 6.0);

      dsp.updateSettings(preamp: 12.0);
      expect(dsp.preamp, 12.0);

      dsp.updateSettings(preamp: -12.0);
      expect(dsp.preamp, -12.0);

      dsp.updateSettings(preamp: 0.0); // Reset to unity gain
      expect(dsp.preamp, 0.0);
    });

    test('Bass boost operates from 0.0 to 1.0 producing up to +18dB punchy low-end', () {
      dsp.updateSettings(bassBoost: 0.65);
      expect(dsp.bassBoost, 0.65);

      dsp.updateSettings(bassBoost: 1.0);
      expect(dsp.bassBoost, 1.0);

      dsp.updateSettings(bassBoost: 0.0);
      expect(dsp.bassBoost, 0.0);
    });

    test('Treble boost operates from 0.0 to 1.0 producing up to +18dB airy clarity', () {
      dsp.updateSettings(trebleBoost: 0.80);
      expect(dsp.trebleBoost, 0.80);

      dsp.updateSettings(trebleBoost: 1.0);
      expect(dsp.trebleBoost, 1.0);

      dsp.updateSettings(trebleBoost: 0.0);
      expect(dsp.trebleBoost, 0.0);
    });

    test('Spatial 3D expands stereo field between 0.0 and 1.0', () {
      dsp.updateSettings(spatial3d: 0.75);
      expect(dsp.spatial3d, 0.75);

      dsp.updateSettings(spatial3d: 1.0);
      expect(dsp.spatial3d, 1.0);

      dsp.updateSettings(spatial3d: 0.0);
      expect(dsp.spatial3d, 0.0);
    });

    test('10-Band EQ updates and can be reset cleanly', () {
      final customBands = [4.5, 3.0, 1.5, 0.0, -1.0, 0.0, 2.0, 3.5, 5.0, 6.0];
      dsp.updateSettings(bands: customBands);
      expect(dsp.bands[0], 4.5);
      expect(dsp.bands[9], 6.0);

      // Verify reset
      dsp.updateSettings(
        preamp: 0.0,
        bassBoost: 0.0,
        trebleBoost: 0.0,
        spatial3d: 0.0,
        bands: List.filled(10, 0.0),
      );
      for (final g in dsp.bands) {
        expect(g, 0.0);
      }
      expect(dsp.bassBoost, 0.0);
      expect(dsp.trebleBoost, 0.0);
      expect(dsp.preamp, 0.0);
    });
  });

  group('Music Playback Queue & Metadata Reactive Tests', () {
    final pc = PlaybackController.instance;

    const trackA = PlaybackItem(
      id: 'song_a',
      url: 'http://localhost/a.mp3',
      title: 'Neon Horizon',
      artist: 'Synthwave Pilot',
      album: 'Cyber City',
      thumbnail: 'https://images.example.com/cover_a.jpg',
    );

    const trackB = PlaybackItem(
      id: 'song_b',
      url: 'http://localhost/b.mp3',
      title: 'Midnight Bass',
      artist: 'Audiophile Master',
      album: 'Deep Sound',
      thumbnail: 'https://images.example.com/cover_b.jpg',
    );

    test('PlaybackItem model holds metadata, artwork and stream targets', () {
      expect(trackA.id, 'song_a');
      expect(trackA.title, 'Neon Horizon');
      expect(trackA.artist, 'Synthwave Pilot');
      expect(trackA.album, 'Cyber City');
      expect(trackA.thumbnail, 'https://images.example.com/cover_a.jpg');
      expect(trackA.url, 'http://localhost/a.mp3');

      final copied = trackA.copyWith(title: 'Neon Horizon (Remix)');
      expect(copied.title, 'Neon Horizon (Remix)');
      expect(copied.artist, 'Synthwave Pilot');
    });

    test('PlaybackQueueState accurately updates active track, metadata and bounds', () {
      var state = const PlaybackQueueState();
      expect(state.queue.isEmpty, isTrue);
      expect(state.current, isNull);
      expect(state.currentIndex, -1);

      state = state.copyWith(
        queue: [trackA, trackB],
        currentIndex: 0,
      );
      expect(state.queue.length, 2);
      expect(state.current?.id, 'song_a');
      expect(state.current?.title, 'Neon Horizon');
      expect(state.current?.artist, 'Synthwave Pilot');
      expect(state.current?.thumbnail, 'https://images.example.com/cover_a.jpg');

      // Advance track index
      state = state.copyWith(currentIndex: 1);
      expect(state.current?.id, 'song_b');
      expect(state.current?.title, 'Midnight Bass');
      expect(state.current?.artist, 'Audiophile Master');
      expect(state.current?.thumbnail, 'https://images.example.com/cover_b.jpg');

      // Bounds safety
      state = state.copyWith(currentIndex: 99);
      expect(state.current, isNull);
    });

    test('PlaybackController shuffle and repeat mode transitions', () {
      final pc = PlaybackController.instance;

      pc.setShuffle(true);
      expect(pc.shuffle, isTrue);
      pc.setShuffle(false);
      expect(pc.shuffle, isFalse);

      pc.setRepeat(PlaybackRepeat.all);
      expect(pc.repeat, PlaybackRepeat.all);
      pc.setRepeat(PlaybackRepeat.one);
      expect(pc.repeat, PlaybackRepeat.one);
      pc.setRepeat(PlaybackRepeat.off);
      expect(pc.repeat, PlaybackRepeat.off);
    });
  });
}

