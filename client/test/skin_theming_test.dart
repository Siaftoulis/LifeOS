import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/theme/app_skin.dart';
import 'package:lifeos_client/theme/app_skin_registry.dart';
import 'package:lifeos_client/theme/app_skin_manager.dart';
import 'package:lifeos_client/database/preferences_service.dart';

void main() {
  group('LifeOS Multi-Skin & Theming Architecture Tests', () {
    test('Registry contains all 13 world-class themes', () {
      expect(AppSkinRegistry.allSkins.length, 13);

      final ids = AppSkinRegistry.allSkins.map((s) => s.id).toSet();
      expect(ids.contains('oled'), isTrue);
      expect(ids.contains('everforest'), isTrue);
      expect(ids.contains('catppuccin_mocha'), isTrue);
      expect(ids.contains('catppuccin_latte'), isTrue);
      expect(ids.contains('dracula'), isTrue);
      expect(ids.contains('tokyo_night'), isTrue);
      expect(ids.contains('nord'), isTrue);
      expect(ids.contains('gruvbox_dark'), isTrue);
      expect(ids.contains('rose_pine'), isTrue);
      expect(ids.contains('synthwave'), isTrue);
      expect(ids.contains('default_dark'), isTrue);
      expect(ids.contains('default_light'), isTrue);
      expect(ids.contains('solarized_light'), isTrue);
    });

    test('OLED skin satisfies pitch-black and high-contrast requirements', () {
      final oled = AppSkinRegistry.getById('oled');
      expect(oled.id, 'oled');
      expect(oled.isOled, isTrue);
      expect(oled.isDark, isTrue);
      expect(oled.bg0, const Color(0xFF000000)); // Pure black
      expect(oled.fg, const Color(0xFFEDEDED)); // Soft white without blinding glare
      expect(oled.tags.contains('OLED'), isTrue);
    });

    test('Safe fallback returns Everforest Dark for unknown or empty IDs', () {
      final fallback1 = AppSkinRegistry.getById('non_existent_skin_id');
      expect(fallback1.id, 'everforest');

      final fallback2 = AppSkinRegistry.getById(null);
      expect(fallback2.id, 'everforest');
    });

    test('toThemeData produces coherent ThemeData with AppSkinExtension', () {
      final tokyo = AppSkinRegistry.getById('tokyo_night');
      final themeData = tokyo.toThemeData();

      expect(themeData.brightness, Brightness.dark);
      expect(themeData.scaffoldBackgroundColor, tokyo.bg0);
      expect(themeData.colorScheme.surface, tokyo.bg1);
      expect(themeData.colorScheme.primary, tokyo.accent);

      final ext = themeData.extension<AppSkinExtension>();
      expect(ext, isNotNull);
      expect(ext!.skin.id, 'tokyo_night');
    });

    test('AppSkinManager switches active skin and updates PreferencesService', () async {
      AppSkinManager.init();

      await AppSkinManager.setSkin('dracula');
      expect(AppSkinManager.currentSkin.id, 'dracula');
      expect(PreferencesService.activeSkin.value, 'dracula');

      await AppSkinManager.setSkin('oled');
      expect(AppSkinManager.currentSkin.id, 'oled');
      expect(PreferencesService.activeSkin.value, 'oled');
    });

    test('Preset saving and restoring captures and restores active skin', () async {
      // Set to Synthwave
      await AppSkinManager.setSkin('synthwave');
      expect(PreferencesService.activeSkin.value, 'synthwave');

      // Save preset
      await PreferencesService.saveCurrentAsPreset('Retro Synthwave Setup');
      final presetData = PreferencesService.savedPresets.value['Retro Synthwave Setup'];
      expect(presetData, isNotNull);
      expect(presetData['activeSkin'], 'synthwave');

      // Switch to OLED
      await AppSkinManager.setSkin('oled');
      expect(PreferencesService.activeSkin.value, 'oled');

      // Apply the preset
      final success = await PreferencesService.applyPreset('Retro Synthwave Setup');
      expect(success, isTrue);
      expect(PreferencesService.activeSkin.value, 'synthwave');
      expect(AppSkinManager.currentSkin.id, 'synthwave');
    });
  });
}
