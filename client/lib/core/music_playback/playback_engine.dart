import 'playback_engine_io.dart'
    if (dart.library.js_interop) 'playback_engine_web.dart'
    if (dart.library.html) 'playback_engine_web.dart';

/// The real audio engine (just_audio + media_kit on desktop, ExoPlayer on
/// Android, just_audio_web on Web).
final PlaybackEngine playbackEngine = PlaybackEngine();