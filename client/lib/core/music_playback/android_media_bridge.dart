import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../repositories/models/music_models.dart';
import '../repositories/music_repository.dart';
import 'playback_controller.dart';

/// Bridges Flutter's [PlaybackController] state with Android native
/// Notification banner (MediaStyle / MediaSessionCompat) and Home Screen AppWidget.
class AndroidMediaBridge {
  AndroidMediaBridge._();
  static final AndroidMediaBridge instance = AndroidMediaBridge._();

  static const MethodChannel _channel = MethodChannel('com.lifeos.app/media_session');

  static final ValueNotifier<Map<String, dynamic>?> latestLaunchIntent = ValueNotifier(null);

  bool _initialized = false;
  String _lastTitle = '';
  String _lastArtist = '';
  String _lastThumb = '';
  bool _lastPlaying = false;
  bool _lastLiked = false;
  Timer? _positionTimer;

  void init() {
    if (_initialized) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _initialized = true;
    _channel.setMethodCallHandler(_handleNativeCall);
    PlaybackController.instance.addListener(_syncStateToNative);
    MusicRepository.instance.likedTrackIds.addListener(_syncStateToNative);

    // Periodic timer while playing to keep Android seekbar position updated
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (PlaybackController.instance.isPlaying) {
        _syncPositionToNative();
      }
    });

    _channel.invokeMethod('getInitialWidgetLaunch').then((res) {
      if (res != null && res is Map) {
        latestLaunchIntent.value = Map<String, dynamic>.from(res);
      }
    }).catchError((_) => null);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onWidgetLaunch') {
      final args = call.arguments;
      if (args != null && args is Map) {
        latestLaunchIntent.value = Map<String, dynamic>.from(args);
      }
      return;
    }
    if (call.method == 'onMediaAction') {
      final action = call.arguments as String?;
      switch (action) {
        case 'playPause':
          PlaybackController.instance.togglePlayPause();
          break;
        case 'play':
          PlaybackController.instance.play();
          break;
        case 'pause':
          PlaybackController.instance.pause();
          break;
        case 'next':
          PlaybackController.instance.next();
          break;
        case 'previous':
          PlaybackController.instance.previous();
          break;
        case 'toggleLike':
          final item = PlaybackController.instance.currentItem;
          if (item != null) {
            final track = MusicTrack(
              id: item.id,
              title: item.title,
              artist: item.artist,
              album: item.album,
              thumbnail: item.thumbnail,
              duration: 0,
            );
            await MusicRepository.instance.toggleLike(track);
            _syncStateToNative();
          }
          break;
      }
      return;
    }
    if (call.method == 'onSeekTo') {
      final pos = call.arguments;
      if (pos is num) {
        PlaybackController.instance.seek(Duration(milliseconds: pos.toInt()));
      }
      return;
    }
  }

  void _syncPositionToNative() {
    if (!_initialized) return;
    final controller = PlaybackController.instance;
    final item = controller.currentItem;
    if (item == null) return;

    final posMs = controller.player?.position.inMilliseconds ?? 0;
    final durMs = controller.player?.duration?.inMilliseconds ?? 0;
    final isLiked = MusicRepository.instance.likedTrackIds.value.contains(item.id);

    _channel.invokeMethod('updatePlaybackState', {
      'title': item.title,
      'artist': item.artist,
      'album': item.album,
      'thumbnail': item.thumbnail,
      'isPlaying': controller.isPlaying,
      'positionMs': posMs,
      'durationMs': durMs,
      'isLiked': isLiked,
    }).catchError((_) => null);
  }

  void _syncStateToNative() {
    if (!_initialized) return;

    final controller = PlaybackController.instance;
    final item = controller.currentItem;
    final isPlaying = controller.isPlaying;

    if (item == null) {
      if (_lastTitle.isNotEmpty) {
        _lastTitle = '';
        _lastArtist = '';
        _lastThumb = '';
        _lastPlaying = false;
        _lastLiked = false;
        _channel.invokeMethod('stopPlayback').catchError((_) => null);
      }
      return;
    }

    final title = item.title;
    final artist = item.artist;
    final thumb = item.thumbnail;
    final isLiked = MusicRepository.instance.likedTrackIds.value.contains(item.id);

    if (title != _lastTitle ||
        artist != _lastArtist ||
        thumb != _lastThumb ||
        isPlaying != _lastPlaying ||
        isLiked != _lastLiked) {
      _lastTitle = title;
      _lastArtist = artist;
      _lastThumb = thumb;
      _lastPlaying = isPlaying;
      _lastLiked = isLiked;

      final posMs = controller.player?.position.inMilliseconds ?? 0;
      final durMs = controller.player?.duration?.inMilliseconds ?? 0;

      _channel.invokeMethod('updatePlaybackState', {
        'title': title,
        'artist': artist,
        'album': item.album,
        'thumbnail': thumb,
        'isPlaying': isPlaying,
        'positionMs': posMs,
        'durationMs': durMs,
        'isLiked': isLiked,
      }).catchError((_) => null);
    }
  }

  /// Sends updated widget appearance and destination config to Android AppWidget
  Future<void> updateWidgetConfig({
    required bool showArtwork,
    required int opacity,
    required String themeStyle,
    String targetTab = 'music_player',
    String widgetType = 'standard',
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('updateWidgetConfig', {
        'showArtwork': showArtwork,
        'opacity': opacity,
        'themeStyle': themeStyle,
        'targetTab': targetTab,
        'widgetType': widgetType,
      });
    } catch (_) {}
  }

  void dispose() {
    if (!_initialized) return;
    _positionTimer?.cancel();
    PlaybackController.instance.removeListener(_syncStateToNative);
    MusicRepository.instance.likedTrackIds.removeListener(_syncStateToNative);
    _initialized = false;
  }
}
