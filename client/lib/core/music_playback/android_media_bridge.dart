import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'playback_controller.dart';

/// Bridges Flutter's [PlaybackController] state with Android native
/// Notification banner (MediaStyle) and Home Screen AppWidget.
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

  void init() {
    if (_initialized) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _initialized = true;
    _channel.setMethodCallHandler(_handleNativeCall);
    PlaybackController.instance.addListener(_syncStateToNative);

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
        case 'next':
          PlaybackController.instance.next();
          break;
        case 'previous':
          PlaybackController.instance.previous();
          break;
      }
    }
  }

  void _syncStateToNative() {
    if (!_initialized) return;

    final controller = PlaybackController.instance;
    final item = controller.currentItem;
    final isPlaying = controller.player?.playing ?? false;

    if (item == null) {
      if (_lastTitle.isNotEmpty) {
        _lastTitle = '';
        _lastArtist = '';
        _lastThumb = '';
        _lastPlaying = false;
        _channel.invokeMethod('stopPlayback').catchError((_) => null);
      }
      return;
    }

    final title = item.title;
    final artist = item.artist;
    final thumb = item.thumbnail;

    if (title != _lastTitle || artist != _lastArtist || thumb != _lastThumb || isPlaying != _lastPlaying) {
      _lastTitle = title;
      _lastArtist = artist;
      _lastThumb = thumb;
      _lastPlaying = isPlaying;

      _channel.invokeMethod('updatePlaybackState', {
        'title': title,
        'artist': artist,
        'thumbnail': thumb,
        'isPlaying': isPlaying,
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
    PlaybackController.instance.removeListener(_syncStateToNative);
    _initialized = false;
  }
}
