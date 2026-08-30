import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../database/preferences_service.dart';
import '../../../theme/everforest_colors.dart';

class PresetManagerCard extends StatefulWidget {
  const PresetManagerCard({super.key});

  @override
  State<PresetManagerCard> createState() => _PresetManagerCardState();
}

class _PresetManagerCardState extends State<PresetManagerCard> {
  final TextEditingController _presetNameController = TextEditingController();

  Future<void> _showSavePresetDialog() async {
    _presetNameController.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EverforestColors.bg2),
        ),
        title: const Row(
          children: [
            Icon(Icons.bookmark_add_rounded, color: EverforestColors.green),
            SizedBox(width: 10),
            Text('Save Current Layout Preset', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save your current tile arrangement, app drawer folders, and Zen notes setup into a permanent preset.',
              style: TextStyle(color: EverforestColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _presetNameController,
              autofocus: true,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: InputDecoration(
                hintText: 'e.g. Work Focus, Media Hub, Minimalist',
                hintStyle: const TextStyle(color: EverforestColors.grey),
                filled: true,
                fillColor: EverforestColors.bg0,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: EverforestColors.bg2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: EverforestColors.green),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.green,
              foregroundColor: EverforestColors.bg0,
            ),
            onPressed: () {
              final val = _presetNameController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('SAVE PRESET', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await PreferencesService.saveCurrentAsPreset(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EverforestColors.bg1,
            content: Text('Preset "$name" saved successfully!', style: const TextStyle(color: EverforestColors.green)),
          ),
        );
      }
    }
  }

  Future<void> _showImportJsonDialog() async {
    final controller = TextEditingController();
    final jsonStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EverforestColors.bg2),
        ),
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: EverforestColors.blue),
            SizedBox(width: 10),
            Text('Import Presets JSON', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your exported JSON presets below to restore your custom layouts and settings.',
                style: TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(color: EverforestColors.fg, fontSize: 12, fontFamily: 'JetBrainsMono'),
                decoration: InputDecoration(
                  hintText: '{\n  "savedPresets": { ... }\n}',
                  hintStyle: const TextStyle(color: EverforestColors.grey),
                  filled: true,
                  fillColor: EverforestColors.bg0,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EverforestColors.bg2)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: EverforestColors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.blue, foregroundColor: EverforestColors.bg0),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('IMPORT & APPLY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (jsonStr != null && jsonStr.isNotEmpty) {
      final success = await PreferencesService.importPresetsFromJson(jsonStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: success ? EverforestColors.bg1 : EverforestColors.red,
            content: Text(
              success ? 'Presets imported successfully!' : 'Invalid JSON format. Import failed.',
              style: TextStyle(color: success ? EverforestColors.green : Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _exportJson() {
    final jsonStr = PreferencesService.exportPresetsJson();
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: EverforestColors.bg1,
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: EverforestColors.green, size: 18),
            SizedBox(width: 8),
            Text('Presets JSON copied to clipboard!', style: TextStyle(color: EverforestColors.fg)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EverforestColors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dashboard_customize_rounded, color: EverforestColors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Layout & Presets',
                      style: TextStyle(color: EverforestColors.fg, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Persistent across updates • Zero reset guarantee',
                      style: TextStyle(color: EverforestColors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showSavePresetDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Save Preset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EverforestColors.green,
                  foregroundColor: EverforestColors.bg0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Active Preset Header
          ValueListenableBuilder<String>(
            valueListenable: PreferencesService.activePresetName,
            builder: (context, activeName, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: EverforestColors.bg0,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EverforestColors.bg2),
                ),
                child: Row(
                  children: [
                    const Text('ACTIVE PRESET:', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: EverforestColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(activeName, style: const TextStyle(color: EverforestColors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: EverforestColors.grey, size: 16),
                      tooltip: 'Export JSON',
                      onPressed: _exportJson,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.file_upload_outlined, color: EverforestColors.grey, size: 16),
                      tooltip: 'Import JSON',
                      onPressed: _showImportJsonDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Presets List
          ValueListenableBuilder<Map<String, dynamic>>(
            valueListenable: PreferencesService.savedPresets,
            builder: (context, presets, _) {
              if (presets.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  child: const Center(
                    child: Text(
                      'No custom presets saved yet. Click "Save Preset" to capture your current layout!',
                      style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: presets.keys.map((name) {
                  return ValueListenableBuilder<String>(
                    valueListenable: PreferencesService.activePresetName,
                    builder: (context, activeName, _) {
                      final isActive = activeName == name;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: EverforestColors.bg0,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? EverforestColors.green.withValues(alpha: 0.5) : EverforestColors.bg2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.view_quilt_rounded, color: isActive ? EverforestColors.green : EverforestColors.grey, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              name,
                              style: TextStyle(
                                color: isActive ? EverforestColors.green : EverforestColors.fg,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            if (!isActive)
                              TextButton(
                                onPressed: () => PreferencesService.applyPreset(name),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('APPLY', style: TextStyle(color: EverforestColors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: EverforestColors.red, size: 16),
                              tooltip: 'Delete preset',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => PreferencesService.deletePreset(name),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
