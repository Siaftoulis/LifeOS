import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'database/preferences_service.dart';

class UserProfile {
  final String id;
  final String username;
  final String role;
  final String displayName;
  final String status;
  final String avatarAsset;

  UserProfile({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    required this.status,
    required this.avatarAsset,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'USER',
      displayName: json['display_name'] ?? '',
      status: json['status'] ?? '',
      avatarAsset: json['avatar_asset'] ?? '',
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  AuthService._internal();

  final ValueNotifier<UserProfile?> currentUser = ValueNotifier(null);
  String? _token;

  bool get isAuthenticated => currentUser.value != null;
  bool get isAdmin => currentUser.value?.role == 'ADMIN';
  String? get token => _token;

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
          await PreferencesService.setUserProfileJson(res['user'] != null ? jsonEncode(res['user']) : '');
        } else {
          await PreferencesService.setRememberMe(false);
          await PreferencesService.setAuthToken('');
          await PreferencesService.setUserProfileJson('');
        }
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Login Failed: $e');
    }
    return false;
  }

  void restoreSession(String token, String userJson) {
    _token = token;
    if (userJson.isNotEmpty) {
      try {
        currentUser.value = UserProfile.fromJson(jsonDecode(userJson));
      } catch (e) {
        debugPrint('Error restoring user session: $e');
      }
    }
  }

  void logout() {
    _token = null;
    currentUser.value = null;
    PreferencesService.setRememberMe(false);
    PreferencesService.setAuthToken('');
    PreferencesService.setUserProfileJson('');
  }

  Future<bool> updateProfile({
    required String displayName,
    required String status,
    required String avatarAsset,
  }) async {
    if (currentUser.value == null) return false;
    
    try {
      final res = await ApiClient.instance.putDaemon('/api/v1/auth/profile', {
        'username': currentUser.value!.username,
        'display_name': displayName,
        'status': status,
        'avatar_asset': avatarAsset,
      });
      
      if (res['success'] == true) {
        // Update local state
        currentUser.value = UserProfile(
          id: currentUser.value!.id,
          username: currentUser.value!.username,
          role: currentUser.value!.role,
          displayName: displayName,
          status: status,
          avatarAsset: avatarAsset,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Profile update error: $e');
    }
    return false;
  }
}
