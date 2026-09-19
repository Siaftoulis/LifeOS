import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'database/preferences_service.dart';
import 'oauth_browser.dart';

class UserProfile {
  final String id;
  final String username;
  final String email;
  final String role;
  final String displayName;
  final String status;
  final String avatarAsset;
  final String frame;
  final String nameStyle;

  UserProfile({
    required this.id,
    required this.username,
    this.email = '',
    required this.role,
    required this.displayName,
    required this.status,
    required this.avatarAsset,
    this.frame = 'none',
    this.nameStyle = 'default',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      displayName: json['display_name'] ?? '',
      status: json['status'] ?? '',
      avatarAsset: json['avatar_asset'] ?? '',
      frame: json['frame'] ?? 'none',
      nameStyle: json['name_style'] ?? 'default',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'role': role,
    'display_name': displayName,
    'status': status,
    'avatar_asset': avatarAsset,
    'frame': frame,
    'name_style': nameStyle,
  };
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  AuthService._internal();

  final ValueNotifier<UserProfile?> currentUser = ValueNotifier(null);
  String? _token;

  static bool get isLocalhost {
    if (!kIsWeb) return false;
    final host = Uri.base.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0' || host == '';
  }

  void ensureLocalhostUser() {
    if (currentUser.value == null) {
      currentUser.value = UserProfile(
        id: 'u-admin-1',
        username: 'panospds',
        email: 'panagiotissiaftoulis@gmail.com',
        role: 'ADMIN',
        displayName: 'Panos PDS',
        status: 'Online',
        avatarAsset: 'assets/avatars/admin.png',
      );
    }
  }

  bool get isAuthenticated => currentUser.value != null;
  bool get isAdmin => currentUser.value?.role == 'ADMIN';
  String? get token => _token;

  Future<void> initSession() async {
    if (kIsWeb) {
      final token = oauthReadToken();
      if (token != null && token.isNotEmpty) {
        _token = token;
        final ok = await validateSession();
        if (!ok) {
          _token = null;
        }
      }
    } else {
      if (PreferencesService.rememberMe.value) {
        final token = PreferencesService.authToken.value;
        final userJson = PreferencesService.userProfileJson.value;
        if (token.isNotEmpty && userJson.isNotEmpty) {
          restoreSession(token, userJson);
        }
      }
    }
  }

  Future<List<UserProfile>> getPublicProfiles() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/auth/profiles');
      if (res is List) {
        return res.map((item) => UserProfile.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching public profiles: $e');
    }
    // Safe default fallback profiles
    return [
      UserProfile(
        id: 'u-admin-1',
        username: 'panospds',
        email: 'panagiotissiaftoulis@gmail.com',
        role: 'ADMIN',
        displayName: 'Panos PDS',
        status: 'System Administrator',
        avatarAsset: '',
      ),
      UserProfile(
        id: 'u-anna-2',
        username: 'annadim',
        email: 'adimopoulou1234@gmail.com',
        role: 'USER',
        displayName: 'Anna Dimopoulou',
        status: 'Family Member',
        avatarAsset: '',
      ),
    ];
  }

  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    try {
      final res = await ApiClient.instance.postDaemon('/api/v1/auth/login', {
        'username': username,
        'password': password,
      });

      if (res['authenticated'] == true) {
        _token = res['token'];
        if (res['user'] != null) {
          currentUser.value = UserProfile.fromJson(res['user']);
        }
        if (rememberMe) {
          await PreferencesService.setRememberMe(true);
          await PreferencesService.setAuthToken(_token ?? '');
          await PreferencesService.setUserProfileJson(currentUser.value != null ? jsonEncode(currentUser.value!.toJson()) : '');
        } else {
          await PreferencesService.setRememberMe(false);
          await PreferencesService.setAuthToken('');
          await PreferencesService.setUserProfileJson('');
        }
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      final errorStr = e.toString();
      if (errorStr.contains('timed out') || 
          errorStr.contains('Connection refused') || 
          errorStr.contains('SocketException') ||
          errorStr.contains('SocketHTTP') ||
          errorStr.contains('50051')) {
        debugPrint('Daemon server unreachable. Falling back to local offline mode.');
        _token = 'offline_session_token';
        final userObj = {
          'id': 'local_${username.toLowerCase()}',
          'username': username,
          'email': username == 'annadim' ? 'adimopoulou1234@gmail.com' : 'panagiotissiaftoulis@gmail.com',
          'role': username == 'panospds' ? 'ADMIN' : 'USER',
          'display_name': username == 'annadim' ? 'Anna Dimopoulou' : username,
          'status': 'Local Mode',
          'avatar_asset': '',
        };
        currentUser.value = UserProfile.fromJson(userObj);
        if (rememberMe) {
          await PreferencesService.setRememberMe(true);
          await PreferencesService.setAuthToken(_token!);
          await PreferencesService.setUserProfileJson(jsonEncode(userObj));
        }
        return true;
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
    return false;
  }

  Future<bool> validateSession() async {
    if (_token == null || _token!.isEmpty) return false;
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/auth/me');
      if (res['authenticated'] == true && res['user'] != null) {
        currentUser.value = UserProfile.fromJson(res['user']);
        return true;
      }
    } catch (e) {
      debugPrint('Session validation network check failed (offline fallback active): $e');
      if (currentUser.value != null) return true;
    }
    return false;
  }

  // OAuth (web): daemon redirects back with the JWT in localStorage
  void startOAuth(String provider) {
    oauthStart(provider, ApiClient.instance.daemonUrl);
  }

  Future<bool> tryOAuthToken() async {
    final token = oauthReadToken();
    if (token == null || token.isEmpty) return false;
    _token = token;
    final ok = await validateSession();
    if (!ok) {
      _token = null;
    } else {
      // Persistent session: keep in localStorage and preferences so refresh does NOT log out!
      if (currentUser.value != null) {
        await PreferencesService.setRememberMe(true);
        await PreferencesService.setAuthToken(_token ?? '');
        await PreferencesService.setUserProfileJson(jsonEncode(currentUser.value!.toJson()));
      }
    }
    return ok;
  }

  void restoreSession(String token, String userJson) {
    _token = token;
    if (userJson.isNotEmpty) {
      try {
        currentUser.value = UserProfile.fromJson(jsonDecode(userJson));
        validateSession();
      } catch (e) {
        debugPrint('Error restoring user session: $e');
      }
    }
  }

  void logout() {
    _token = null;
    currentUser.value = null;
    oauthClearToken();
    PreferencesService.setRememberMe(false);
    PreferencesService.setAuthToken('');
    PreferencesService.setUserProfileJson('');
  }

  Future<bool> updateProfile({
    String? newUsername,
    required String displayName,
    required String status,
    required String avatarAsset,
    String frame = 'none',
    String nameStyle = 'default',
  }) async {
    if (currentUser.value == null) return false;
    
    try {
      final res = await ApiClient.instance.putDaemon('/api/v1/auth/profile', {
        'new_username': newUsername ?? currentUser.value!.username,
        'display_name': displayName,
        'status': status,
        'avatar_asset': avatarAsset,
        'frame': frame,
        'name_style': nameStyle,
      });
      
      if (res['success'] == true) {
        if (res['token'] != null && (res['token'] as String).isNotEmpty) {
          _token = res['token'];
          await PreferencesService.setAuthToken(_token!);
        }

        if (res['user'] != null) {
          currentUser.value = UserProfile.fromJson(Map<String, dynamic>.from(res['user']));
        } else {
          currentUser.value = UserProfile(
            id: currentUser.value!.id,
            username: newUsername ?? currentUser.value!.username,
            email: currentUser.value!.email,
            role: currentUser.value!.role,
            displayName: displayName,
            status: status,
            avatarAsset: avatarAsset,
            frame: frame,
            nameStyle: nameStyle,
          );
        }

        if (PreferencesService.rememberMe.value) {
          await PreferencesService.setUserProfileJson(jsonEncode(currentUser.value!.toJson()));
        }
        return true;
      }
    } catch (e) {
      debugPrint('Profile update error: $e');
      rethrow;
    }
    return false;
  }

  Future<void> sendHeartbeat() async {
    if (!isAuthenticated) return;
    try {
      await ApiClient.instance.postDaemon('/api/v1/auth/heartbeat', {});
    } catch (_) {}
  }
}
