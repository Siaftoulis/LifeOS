import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'lifeos_media_kit_player.dart';

/// Custom JustAudioPlatform plugin for LifeOS that seamlessly integrates
/// media_kit with real-time Audiophile DSP (10-Band EQ, Bass, Treble, Reverb).
class LifeOSJustAudioMediaKit extends JustAudioPlatform {
  static final _logger = Logger('LifeOSJustAudioMediaKit');
  final _players = HashMap<String, LifeOSMediaKitPlayer>();

  static void ensureInitialized({
    bool linux = true,
    bool windows = true,
    bool macOS = true,
  }) {
    if (kIsWeb) return;
    if ((Platform.isLinux && linux) ||
        (Platform.isWindows && windows) ||
        (Platform.isMacOS && macOS)) {
      registerWith();
      MediaKit.ensureInitialized();
    }
  }

  static void registerWith() {
    JustAudioPlatform.instance = LifeOSJustAudioMediaKit();
  }

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    if (_players.containsKey(request.id)) {
      throw PlatformException(
        code: 'error',
        message: 'Player ${request.id} already exists!',
      );
    }

    _logger.fine('Instantiating LifeOSMediaKitPlayer ${request.id}');
    final player = LifeOSMediaKitPlayer(request.id);
    _players[request.id] = player;
    await player.ready();
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(DisposePlayerRequest request) async {
    final player = _players.remove(request.id);
    if (player != null) {
      await player.release();
    }
    return DisposePlayerResponse();
  }
}
