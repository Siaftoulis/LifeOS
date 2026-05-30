import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class PreferencesService {
  static final ValueNotifier<String> navProfile = ValueNotifier('Swipe');

  static File get _file {
    if (Platform.isAndroid) return File('/data/user/0/com.lifeos.app/cache/prefs.json');
    return File('prefs.json');
  }

  static Future<void> load() async {
    try {
      if (await _file.exists()) {
        final data = jsonDecode(await _file.readAsString());
        navProfile.value = data['navProfile'] ?? 'Swipe';
      }
    } catch (_) {}
  }

  static Future<void> setNavProfile(String val) async {
    navProfile.value = val;
    try {
      await _file.writeAsString(jsonEncode({'navProfile': val}));
    } catch (_) {}
  }
}
