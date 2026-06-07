import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class PreferencesService {
  static final ValueNotifier<String> navProfile = ValueNotifier('Swipe');
  static final ValueNotifier<bool> bgSync = ValueNotifier(true);
  static final ValueNotifier<bool> spatialGestures = ValueNotifier(true);
  static final ValueNotifier<bool> devMode = ValueNotifier(false);
  static final ValueNotifier<List<List<String>>> layout = ValueNotifier([
    ['radar', 'obsidian', 'infra'],
    ['quests', 'home', 'media'],
    ['capture', 'configurator', 'void']
  ]);

  static File get _file {
    if (Platform.isAndroid) return File('/data/user/0/com.lifeos.app/cache/prefs.json');
    return File('prefs.json');
  }

  static Future<void> load() async {
    try {
      if (await _file.exists()) {
        final data = jsonDecode(await _file.readAsString());
        navProfile.value = data['navProfile'] ?? 'Swipe';
        bgSync.value = data['bgSync'] ?? true;
        spatialGestures.value = data['spatialGestures'] ?? true;
        devMode.value = data['devMode'] ?? false;
        if (data['layout'] != null) {
          final List<dynamic> rawLayout = data['layout'];
          layout.value = rawLayout.map((row) => List<String>.from(row)).toList();
        }
      }
    } catch (_) {}
  }

  static Future<void> save() async {
    try {
      final data = {
        'navProfile': navProfile.value,
        'bgSync': bgSync.value,
        'spatialGestures': spatialGestures.value,
        'devMode': devMode.value,
        'layout': layout.value,
      };
      await _file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> setNavProfile(String val) async {
    navProfile.value = val;
    await save();
  }

  static Future<void> setBgSync(bool val) async {
    bgSync.value = val;
    await save();
  }

  static Future<void> setSpatialGestures(bool val) async {
    spatialGestures.value = val;
    await save();
  }

  static Future<void> setDevMode(bool val) async {
    devMode.value = val;
    await save();
  }

  static Future<void> setLayout(List<List<String>> val) async {
    layout.value = val;
    await save();
  }
}
