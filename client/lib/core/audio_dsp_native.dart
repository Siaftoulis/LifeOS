import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'audio_dsp_service.dart';

class NativeAudioDspEngine {
  static final Set<Player> _activePlayers = {};
  static String _currentFilterString = '';

  static void registerPlayer(Player player) {
    _activePlayers.add(player);
    applyFiltersToPlayer(player);
  }

  static void unregisterPlayer(Player player) {
    _activePlayers.remove(player);
  }

  static Future<void> applyFiltersToPlayer(Player player) async {
    final filter = _currentFilterString.isNotEmpty
        ? _currentFilterString
        : AudioDspService.instance.buildMpvFilterString();
    _currentFilterString = filter;
    await _setFilter(player, filter);
  }

  static Future<void> _setFilter(Player player, String filterString) async {
    try {
      final platform = player.platform;
      if (platform is NativePlayer) {
        await (platform as dynamic).setProperty('af', filterString);
        debugPrint('NativeAudioDspEngine: Injected "af" -> "$filterString"');
      }
    } catch (e) {
      debugPrint('NativeAudioDspEngine error applying filter: $e');
    }
  }

  static void applyMpvFilters(String filterString) {
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;
    _currentFilterString = filterString;
    for (final player in _activePlayers) {
      _setFilter(player, filterString);
    }
  }
}
