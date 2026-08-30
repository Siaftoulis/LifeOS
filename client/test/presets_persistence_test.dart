import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/database/preferences_service.dart';

void main() {
  group('User Presets & Layout Persistence Tests', () {
    test('Saving and applying named layout presets', () async {
      // Set test layout
      final testLayout = [
        ['home', 'rpg_hub', 'configurator'],
        ['media_hub', 'void', 'void']
      ];
      PreferencesService.layout.value = testLayout;

      // Save preset
      await PreferencesService.saveCurrentAsPreset('Work & Media Setup');

      expect(PreferencesService.savedPresets.value.containsKey('Work & Media Setup'), isTrue);
      expect(PreferencesService.activePresetName.value, 'Work & Media Setup');

      // Change layout
      PreferencesService.layout.value = [['home', 'configurator', 'rpg_hub']];

      // Apply saved preset
      final success = await PreferencesService.applyPreset('Work & Media Setup');
      expect(success, isTrue);
      expect(PreferencesService.layout.value.length, 2);
      expect(PreferencesService.layout.value[0][1], 'rpg_hub');
    });

    test('Export and import presets JSON roundtrip', () async {
      final jsonStr = PreferencesService.exportPresetsJson();
      expect(jsonStr.isNotEmpty, isTrue);

      final decoded = jsonDecode(jsonStr);
      expect(decoded.containsKey('savedPresets'), isTrue);
      expect(decoded.containsKey('currentLayout'), isTrue);

      // Import test
      final importOk = await PreferencesService.importPresetsFromJson(jsonStr);
      expect(importOk, isTrue);
    });

    test('Deleting a preset updates savedPresets cleanly', () async {
      await PreferencesService.saveCurrentAsPreset('Temporary Preset');
      expect(PreferencesService.savedPresets.value.containsKey('Temporary Preset'), isTrue);

      await PreferencesService.deletePreset('Temporary Preset');
      expect(PreferencesService.savedPresets.value.containsKey('Temporary Preset'), isFalse);
    });
  });
}
