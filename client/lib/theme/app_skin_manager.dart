import 'package:flutter/material.dart';
import 'app_skin.dart';
import 'app_skin_registry.dart';
import '../database/preferences_service.dart';

/// Singleton manager for dynamically reading and changing the active LifeOS skin.
class AppSkinManager {
  static final ValueNotifier<AppSkin> currentSkinNotifier =
      ValueNotifier<AppSkin>(AppSkinRegistry.everforest);

  static AppSkin get currentSkin => currentSkinNotifier.value;

  /// Initializes the skin manager with the active preference or default.
  static void init() {
    final savedId = PreferencesService.activeSkin.value;
    currentSkinNotifier.value = AppSkinRegistry.getById(savedId);

    // Listen to changes from PreferencesService (e.g. preset restore)
    PreferencesService.activeSkin.addListener(() {
      final updated = AppSkinRegistry.getById(PreferencesService.activeSkin.value);
      if (currentSkinNotifier.value.id != updated.id) {
        currentSkinNotifier.value = updated;
      }
    });
  }

  /// Changes the active skin, saves to user preferences, and triggers UI updates.
  static Future<void> setSkin(String skinId) async {
    final newSkin = AppSkinRegistry.getById(skinId);
    currentSkinNotifier.value = newSkin;
    await PreferencesService.setActiveSkin(newSkin.id);
  }
}

/// Syntactic sugar to access current skin from any BuildContext.
extension AppSkinContextExtension on BuildContext {
  AppSkin get skin {
    final ext = Theme.of(this).extension<AppSkinExtension>();
    return ext?.skin ?? AppSkinManager.currentSkin;
  }
}
