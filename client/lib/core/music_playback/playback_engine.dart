import 'package:flutter/foundation.dart';
import 'playback_engine_io.dart'
    if (dart.library.js_interop) 'playback_engine_web.dart'
    if (dart.library.html) 'playback_engine_web.dart';

/// The real audio engine (just_audio + media_kit on desktop, ExoPlayer on
/// Android). On web this resolves to a no-op stub — LifeOS music playback is
/// native-only by design (see AGENTS.md).
final PlaybackEngine playbackEngine = PlaybackEngine();