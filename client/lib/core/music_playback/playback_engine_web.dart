/// No-op audio engine for Flutter Web.
///
/// LifeOS music playback is native-only by design: the web portal shows the
/// music UI and the downloaded library, but never plays audio.
class PlaybackEngine {
  bool get isAvailable => false;

  dynamic get player => null;

  Future<void> init() async {}

  Future<void> setUrl(String url) async {}

  Future<void> play() async {}

  Future<void> pause() async {}

  Future<void> stop() async {}

  Future<void> seek(Duration position) async {}

  Future<void> setRepeatOne(bool one) async {}

  void dispose() {}
}