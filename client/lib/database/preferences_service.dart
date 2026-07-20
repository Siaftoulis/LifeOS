import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'layout_sanitizer.dart';

class PreferencesService {
  static const _secureStorage = FlutterSecureStorage();
  static final ValueNotifier<String> navProfile = ValueNotifier('Swipe');
  static final ValueNotifier<bool> bgSync = ValueNotifier(true);
  static final ValueNotifier<bool> spatialGestures = ValueNotifier(true);
  static final ValueNotifier<bool> devMode = ValueNotifier(false);
  static final ValueNotifier<String> activeProfileId = ValueNotifier('prof-admin');
  static final ValueNotifier<String> activeProfileRole = ValueNotifier('ADMIN');
  static final ValueNotifier<int> dailyLimitMinutes = ValueNotifier(0);
  static final ValueNotifier<bool> rememberMe = ValueNotifier(false);
  static final ValueNotifier<String> hashedPin = ValueNotifier('');
  static final ValueNotifier<String> authToken = ValueNotifier('');
  static final ValueNotifier<String> userProfileJson = ValueNotifier('');
  static final ValueNotifier<List<List<String>>> layout = ValueNotifier([['home', 'configurator', 'rpg_hub']]);
  static final ValueNotifier<Map<String, String>> appCategories = ValueNotifier({});
  static final ValueNotifier<bool> appDrawerFolderView = ValueNotifier(true);
  static final ValueNotifier<String> cachedBaseUrl = ValueNotifier('http://192.168.1.47:50051');
  static final ValueNotifier<String> cachedDaemonUrl = ValueNotifier('http://192.168.1.47:50051');
  static final ValueNotifier<bool> showPerformanceOverlay = ValueNotifier(false);
  static final ValueNotifier<bool> showConnectionStatusOverlay = ValueNotifier(false);
  static final ValueNotifier<List<String>> favoriteAssetIds = ValueNotifier([]);

  static Future<void> load({Directory? dir}) async {
    try {
      final f = await getPrefsFile(dir);
      if (!await f.exists()) {
        layout.value = sanitizeLayout(layout.value);
        return;
      }
      final data = jsonDecode(await f.readAsString());
      navProfile.value = data['navProfile'] ?? 'Swipe';
      bgSync.value = data['bgSync'] ?? true;
      spatialGestures.value = data['spatialGestures'] ?? true;
      devMode.value = data['devMode'] ?? false;
      activeProfileId.value = data['activeProfileId'] ?? 'prof-admin';
      activeProfileRole.value = data['activeProfileRole'] ?? 'ADMIN';
      dailyLimitMinutes.value = data['dailyLimitMinutes'] ?? 0;
      rememberMe.value = data['rememberMe'] ?? false;
      hashedPin.value = data['hashedPin'] ?? '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4';
      try {
        authToken.value = await _secureStorage.read(key: 'authToken').timeout(const Duration(seconds: 2)) ?? '';
      } catch (_) {
        authToken.value = '';
      }
      userProfileJson.value = data['userProfileJson'] ?? '';
      if (data['layout'] != null) layout.value = sanitizeLayout((data['layout'] as List).map((r) => List<String>.from(r)).toList());
      if (data['appCategories'] != null) appCategories.value = (data['appCategories'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      appDrawerFolderView.value = data['appDrawerFolderView'] ?? true;
      cachedBaseUrl.value = data['cachedBaseUrl'] ?? 'http://192.168.1.47:50051';
      cachedDaemonUrl.value = data['cachedDaemonUrl'] ?? 'http://192.168.1.47:50051';
      showPerformanceOverlay.value = data['showPerformanceOverlay'] ?? false;
      showConnectionStatusOverlay.value = data['showConnectionStatusOverlay'] ?? false;
      if (data['favoriteAssetIds'] != null) favoriteAssetIds.value = List<String>.from(data['favoriteAssetIds']);
    } catch (_) {}
  }

  static Future<void> save() async {
    try {
      final f = await getPrefsFile(null);
      await f.writeAsString(jsonEncode({
        'navProfile': navProfile.value, 'bgSync': bgSync.value, 'spatialGestures': spatialGestures.value,
        'devMode': devMode.value, 'activeProfileId': activeProfileId.value, 'activeProfileRole': activeProfileRole.value,
        'layout': layout.value, 'rememberMe': rememberMe.value, 'hashedPin': hashedPin.value,
        'userProfileJson': userProfileJson.value, 'appCategories': appCategories.value,
        'appDrawerFolderView': appDrawerFolderView.value, 'cachedBaseUrl': cachedBaseUrl.value,
        'cachedDaemonUrl': cachedDaemonUrl.value, 'showPerformanceOverlay': showPerformanceOverlay.value,
        'showConnectionStatusOverlay': showConnectionStatusOverlay.value,
        'favoriteAssetIds': favoriteAssetIds.value,
      }));
      try {
        await _secureStorage.write(key: 'authToken', value: authToken.value).timeout(const Duration(seconds: 2));
      } catch (_) {}
    } catch (_) {}
  }

  static Future<void> setCachedUrls(String b, String d) async { cachedBaseUrl.value = b; cachedDaemonUrl.value = d; await save(); }
  static Future<void> setNavProfile(String v) async { navProfile.value = v; await save(); }
  static Future<void> toggleFavorite(String id) async {
    final list = List<String>.from(favoriteAssetIds.value);
    if (list.contains(id)) list.remove(id); else list.add(id);
    favoriteAssetIds.value = list; await save();
  }
  static Future<void> setBgSync(bool v) async { bgSync.value = v; await save(); }
  static Future<void> setSpatialGestures(bool v) async { spatialGestures.value = v; await save(); }
  static Future<void> setDevMode(bool v) async { devMode.value = v; await save(); }
  static Future<void> setActiveProfile(String id, String role) async { activeProfileId.value = id; activeProfileRole.value = role; await save(); }
  static Future<void> setDailyLimitMinutes(int v) async { dailyLimitMinutes.value = v; await save(); }
  static Future<void> setLayout(List<List<String>> v) async { layout.value = sanitizeLayout(v); await save(); }
  static Future<void> setRememberMe(bool v) async { rememberMe.value = v; await save(); }
  static Future<void> setAuthToken(String v) async { authToken.value = v; await save(); }
  static Future<void> setUserProfileJson(String v) async { userProfileJson.value = v; await save(); }
  static Future<void> setAppDrawerFolderView(bool v) async { appDrawerFolderView.value = v; await save(); }
  static Future<void> saveAppCategories(Map<String, String> cats) async {
    final cur = Map<String, String>.from(appCategories.value)..addAll(cats);
    appCategories.value = cur; await save();
  }
  static Future<void> setShowPerformanceOverlay(bool v) async { showPerformanceOverlay.value = v; await save(); }
  static Future<void> setShowConnectionStatusOverlay(bool v) async { showConnectionStatusOverlay.value = v; await save(); }
}
