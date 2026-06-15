import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PreferencesService {
  static final ValueNotifier<String> navProfile = ValueNotifier('Swipe');
  static final ValueNotifier<bool> bgSync = ValueNotifier(true);
  static final ValueNotifier<bool> spatialGestures = ValueNotifier(true);
  static final ValueNotifier<bool> devMode = ValueNotifier(false);
  static final ValueNotifier<String> activeProfileId = ValueNotifier('prof-admin');
  static final ValueNotifier<String> activeProfileRole = ValueNotifier('ADMIN'); // 'ADMIN', 'NORMAL', 'CHILD'
  static final ValueNotifier<int> dailyLimitMinutes = ValueNotifier(0);
  static final ValueNotifier<bool> rememberMe = ValueNotifier(false);
  static final ValueNotifier<String> authToken = ValueNotifier('');
  static final ValueNotifier<String> userProfileJson = ValueNotifier('');
  static final ValueNotifier<List<List<String>>> layout = ValueNotifier([
    ['home', 'configurator']
  ]);
  static final ValueNotifier<Map<String, String>> appCategories = ValueNotifier({});
  static final ValueNotifier<bool> appDrawerFolderView = ValueNotifier(true);

  static Future<File> get _file async {
    if (Platform.isAndroid) {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/prefs.json');
    }
    return File('prefs.json');
  }

  static Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString());
        navProfile.value = data['navProfile'] ?? 'Swipe';
        bgSync.value = data['bgSync'] ?? true;
        spatialGestures.value = data['spatialGestures'] ?? true;
        devMode.value = data['devMode'] ?? false;
        activeProfileId.value = data['activeProfileId'] ?? 'prof-admin';
        activeProfileRole.value = data['activeProfileRole'] ?? 'ADMIN';
        dailyLimitMinutes.value = data['dailyLimitMinutes'] ?? 0;
        rememberMe.value = data['rememberMe'] ?? false;
        authToken.value = data['authToken'] ?? '';
        userProfileJson.value = data['userProfileJson'] ?? '';
        if (data['layout'] != null) {
          final List<dynamic> rawLayout = data['layout'];
          layout.value = rawLayout.map((row) => List<String>.from(row)).toList();
        }
        if (data['appCategories'] != null) {
          final Map<String, dynamic> rawCategories = data['appCategories'];
          appCategories.value = rawCategories.map((key, value) => MapEntry(key, value.toString()));
        }
        appDrawerFolderView.value = data['appDrawerFolderView'] ?? true;
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
        'activeProfileId': activeProfileId.value,
        'activeProfileRole': activeProfileRole.value,
        'layout': layout.value,
        'rememberMe': rememberMe.value,
        'authToken': authToken.value,
        'userProfileJson': userProfileJson.value,
        'appCategories': appCategories.value,
        'appDrawerFolderView': appDrawerFolderView.value,
      };
      final f = await _file;
      await f.writeAsString(jsonEncode(data));
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

  static Future<void> setActiveProfile(String id, String role) async {
    activeProfileId.value = id;
    activeProfileRole.value = role;
    await save();
  }

  static Future<void> setDailyLimitMinutes(int val) async {
    dailyLimitMinutes.value = val;
    await save();
  }

  static Future<void> setLayout(List<List<String>> val) async {
    layout.value = val;
    await save();
  }

  static Future<void> setRememberMe(bool val) async {
    rememberMe.value = val;
    await save();
  }

  static Future<void> setAuthToken(String val) async {
    authToken.value = val;
    await save();
  }

  static Future<void> setUserProfileJson(String val) async {
    userProfileJson.value = val;
    await save();
  }

  static Future<void> setAppDrawerFolderView(bool val) async {
    appDrawerFolderView.value = val;
    await save();
  }

  static Future<void> saveAppCategories(Map<String, String> newCategories) async {
    final current = Map<String, String>.from(appCategories.value);
    current.addAll(newCategories);
    appCategories.value = current;
    await save();
  }
}
