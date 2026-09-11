import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'playback_controller.dart';

/// Bridges Flutter's [PlaybackController] state with Android native
/// Notification banner (MediaStyle) and Home Screen AppWidget.
class AndroidMediaBridge {
  AndroidMediaBridge._();
  static final AndroidMediaBridge instance = AndroidMediaBridge._();

  static const MethodChannel _channel = MethodChannel('com.lifeos.app/media_session');

  bool _initialized = false;
  String _lastTitle = '';
  String _lastArtist = '';
  bool _lastPlaying = false;

  void init() {
    if (_initialized) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _initialized = true;
    _channel.setMethodCallHandler(_handleNativeCall);
    PlaybackController.instance.addListener(_syncStateToNative);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
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
        _lastPlaying = false;
        _channel.invokeMethod('stopPlayback').catchError((_) => null);
      }
      return;
    }

    final title = item.title;
    final artist = item.artist;

    if (title != _lastTitle || artist != _lastArtist || isPlaying != _lastPlaying) {
      _lastTitle = title;
      _lastArtist = artist;
      _lastPlaying = isPlaying;

      _channel.invokeMethod('updatePlaybackState', {
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
      }).catchError((_) => null);
    }
  }

  void dispose() {
    if (!_initialized) return;
    PlaybackController.instance.removeListener(_syncStateToNative);
    _initialized = false;
  }
}
