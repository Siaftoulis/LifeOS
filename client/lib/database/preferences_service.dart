import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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
  static final ValueNotifier<String> cachedBaseUrl = ValueNotifier(kIsWeb ? Uri.base.origin : 'http://localhost:50051');
  static final ValueNotifier<String> cachedDaemonUrl = ValueNotifier(kIsWeb ? Uri.base.origin : 'http://localhost:50051');
  static final ValueNotifier<bool> showPerformanceOverlay = ValueNotifier(false);
  static final ValueNotifier<bool> showConnectionStatusOverlay = ValueNotifier(false);
  static final ValueNotifier<List<String>> favoriteAssetIds = ValueNotifier([]);
  static final ValueNotifier<List<String>> zenExpanded = ValueNotifier([]);
  static final ValueNotifier<List<String>> zenFavorites = ValueNotifier([]);
  static final ValueNotifier<String> zenWorkspace = ValueNotifier('');
  static final ValueNotifier<double> zenScale = ValueNotifier(1.0);

  // User Custom Layout & Style Presets (Never lost across updates)
  static final ValueNotifier<Map<String, dynamic>> savedPresets = ValueNotifier({});
  static final ValueNotifier<String> activePresetName = ValueNotifier('Default');

  static Directory? _prefsDir;

  static Future<void> load({Directory? dir}) async {
    _prefsDir = dir;
    try {
      final f = await getPrefsFile(dir);
      String content = '';
      if (await f.exists()) {
        content = await f.readAsString();
      } else {
        final backup = File('${f.path}.backup');
        if (await backup.exists()) {
          content = await backup.readAsString();
        }
      }

      if (content.isEmpty) {
        layout.value = sanitizeLayout(layout.value);
        return;
      }

      final data = jsonDecode(content);
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
      cachedBaseUrl.value = data['cachedBaseUrl'] ?? (kIsWeb ? Uri.base.origin : 'http://localhost:50051');
      cachedDaemonUrl.value = data['cachedDaemonUrl'] ?? (kIsWeb ? Uri.base.origin : 'http://localhost:50051');
      if (kIsWeb) {
        if (cachedBaseUrl.value.isEmpty ||
            cachedBaseUrl.value.contains('localhost') ||
            cachedBaseUrl.value.contains('127.0.0.1') ||
            cachedBaseUrl.value.contains('0.0.0.0') ||
            (Uri.base.scheme == 'https' && cachedBaseUrl.value.startsWith('http://'))) {
          cachedBaseUrl.value = Uri.base.origin;
        }
        if (cachedDaemonUrl.value.isEmpty ||
            cachedDaemonUrl.value.contains('localhost') ||
            cachedDaemonUrl.value.contains('127.0.0.1') ||
            cachedDaemonUrl.value.contains('0.0.0.0') ||
            (Uri.base.scheme == 'https' && cachedDaemonUrl.value.startsWith('http://'))) {
          cachedDaemonUrl.value = Uri.base.origin;
        }
      }
      showPerformanceOverlay.value = data['showPerformanceOverlay'] ?? false;
      showConnectionStatusOverlay.value = data['showConnectionStatusOverlay'] ?? false;
      if (data['favoriteAssetIds'] != null) favoriteAssetIds.value = List<String>.from(data['favoriteAssetIds']);
      if (data['zenExpanded'] != null) zenExpanded.value = List<String>.from(data['zenExpanded']);
      if (data['zenFavorites'] != null) zenFavorites.value = List<String>.from(data['zenFavorites']);
      zenWorkspace.value = data['zenWorkspace'] ?? '';
      zenScale.value = (data['zenScale'] as num?)?.toDouble() ?? 1.0;
      if (data['savedPresets'] != null) {
        savedPresets.value = Map<String, dynamic>.from(data['savedPresets']);
      }
      activePresetName.value = data['activePresetName'] ?? 'Default';
    } catch (_) {}
  }

  static Future<void> save() async {
    try {
      final f = await getPrefsFile(_prefsDir);
      final raw = jsonEncode({
        'navProfile': navProfile.value,
        'bgSync': bgSync.value,
        'spatialGestures': spatialGestures.value,
        'devMode': devMode.value,
        'activeProfileId': activeProfileId.value,
        'activeProfileRole': activeProfileRole.value,
        'layout': layout.value,
        'rememberMe': rememberMe.value,
        'hashedPin': hashedPin.value,
        'userProfileJson': userProfileJson.value,
        'appCategories': appCategories.value,
        'appDrawerFolderView': appDrawerFolderView.value,
        'cachedBaseUrl': cachedBaseUrl.value,
        'cachedDaemonUrl': cachedDaemonUrl.value,
        'showPerformanceOverlay': showPerformanceOverlay.value,
        'showConnectionStatusOverlay': showConnectionStatusOverlay.value,
        'favoriteAssetIds': favoriteAssetIds.value,
        'zenExpanded': zenExpanded.value,
        'zenFavorites': zenFavorites.value,
        'zenWorkspace': zenWorkspace.value,
        'zenScale': zenScale.value,
        'savedPresets': savedPresets.value,
        'activePresetName': activePresetName.value,
      });

      await f.writeAsString(raw);

      // Write reliable auto-backup
      try {
        final backup = File('${f.path}.backup');
        await backup.writeAsString(raw);
      } catch (_) {}

      try {
        await _secureStorage.write(key: 'authToken', value: authToken.value).timeout(const Duration(seconds: 2));
      } catch (_) {}
    } catch (_) {}
  }

  /// Saves the current user configuration into a named preset and syncs to Host Daemon
  static Future<void> saveCurrentAsPreset(String name) async {
    final presetData = {
      'layout': layout.value,
      'appCategories': appCategories.value,
      'appDrawerFolderView': appDrawerFolderView.value,
      'navProfile': navProfile.value,
      'spatialGestures': spatialGestures.value,
      'zenWorkspace': zenWorkspace.value,
      'zenFavorites': zenFavorites.value,
      'zenExpanded': zenExpanded.value,
      'zenScale': zenScale.value,
      'savedAt': DateTime.now().toIso8601String(),
    };

    final current = Map<String, dynamic>.from(savedPresets.value);
    current[name] = presetData;
    savedPresets.value = current;
    activePresetName.value = name;
    await save();

    // Background cloud sync to daemon
    _syncPresetToCloud(name, presetData);
  }

  /// Restores a previously saved user preset seamlessly
  static Future<bool> applyPreset(String name) async {
    final preset = savedPresets.value[name];
    if (preset == null || preset is! Map) return false;

    if (preset['layout'] != null) {
      layout.value = sanitizeLayout((preset['layout'] as List).map((r) => List<String>.from(r)).toList());
    }
    if (preset['appCategories'] != null) {
      appCategories.value = (preset['appCategories'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    if (preset['appDrawerFolderView'] != null) {
      appDrawerFolderView.value = preset['appDrawerFolderView'] as bool;
    }
    if (preset['navProfile'] != null) {
      navProfile.value = preset['navProfile'] as String;
    }
    if (preset['spatialGestures'] != null) {
      spatialGestures.value = preset['spatialGestures'] as bool;
    }
    if (preset['zenWorkspace'] != null) {
      zenWorkspace.value = preset['zenWorkspace'] as String;
    }
    if (preset['zenFavorites'] != null) {
      zenFavorites.value = List<String>.from(preset['zenFavorites']);
    }
    if (preset['zenExpanded'] != null) {
      zenExpanded.value = List<String>.from(preset['zenExpanded']);
    }
    if (preset['zenScale'] != null) {
      zenScale.value = (preset['zenScale'] as num).toDouble();
    }

    activePresetName.value = name;
    await save();
    return true;
  }

  /// Deletes a preset locally and from host daemon
  static Future<void> deletePreset(String name) async {
    final current = Map<String, dynamic>.from(savedPresets.value);
    current.remove(name);
    savedPresets.value = current;
    if (activePresetName.value == name) {
      activePresetName.value = 'Default';
    }
    await save();

    _deletePresetFromCloud(name);
  }

  /// Cloud sync helpers
  static Future<void> _syncPresetToCloud(String name, Map<String, dynamic> data) async {
    try {
      final daemonUrl = cachedDaemonUrl.value;
      if (daemonUrl.isEmpty) return;
      final uri = Uri.parse('$daemonUrl/api/v1/system/presets');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'data': data}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  static Future<void> _deletePresetFromCloud(String name) async {
    try {
      final daemonUrl = cachedDaemonUrl.value;
      if (daemonUrl.isEmpty) return;
      final uri = Uri.parse('$daemonUrl/api/v1/system/presets?name=${Uri.encodeComponent(name)}');
      await http.delete(uri).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  static Future<void> syncAllPresetsToCloud() async {
    try {
      final daemonUrl = cachedDaemonUrl.value;
      if (daemonUrl.isEmpty) return;
      final uri = Uri.parse('$daemonUrl/api/v1/system/presets');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'presets': savedPresets.value}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Returns complete JSON string for export
  static String exportPresetsJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'activePresetName': activePresetName.value,
      'currentLayout': layout.value,
      'savedPresets': savedPresets.value,
      'appCategories': appCategories.value,
      'zenWorkspace': zenWorkspace.value,
      'zenFavorites': zenFavorites.value,
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Imports and applies presets from a JSON string
  static Future<bool> importPresetsFromJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr);
      if (data is! Map) return false;

      if (data['savedPresets'] != null && data['savedPresets'] is Map) {
        final merged = Map<String, dynamic>.from(savedPresets.value);
        merged.addAll(Map<String, dynamic>.from(data['savedPresets']));
        savedPresets.value = merged;
      }

      if (data['currentLayout'] != null) {
        layout.value = sanitizeLayout((data['currentLayout'] as List).map((r) => List<String>.from(r)).toList());
      }
      if (data['appCategories'] != null) {
        appCategories.value = (data['appCategories'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      if (data['activePresetName'] != null) {
        activePresetName.value = data['activePresetName'] as String;
      }
      await save();
      syncAllPresetsToCloud();
      return true;
    } catch (_) {
      return false;
    }
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
  static Future<void> setZenExpanded(List<String> v) async { zenExpanded.value = v; await save(); }
  static Future<void> toggleZenFavorite(String path) async {
    final list = List<String>.from(zenFavorites.value);
    if (list.contains(path)) list.remove(path); else list.add(path);
    zenFavorites.value = list; await save();
  }
  static Future<void> setZenWorkspace(String v) async { zenWorkspace.value = v; await save(); }
  static Future<void> setZenScale(double v) async { zenScale.value = v.clamp(0.75, 1.75); await save(); }
}
