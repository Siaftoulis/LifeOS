import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';
import '../../database/preferences_service.dart';

class GridConfigurator extends StatelessWidget {
  const GridConfigurator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          PreferencesService.bgSync,
          PreferencesService.spatialGestures,
          PreferencesService.devMode,
          PreferencesService.navProfile,
          PreferencesService.layout,
        ]),
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('SYSTEM PREFERENCES'),
                const SizedBox(height: 8),
                _buildCard([
                  _buildToggleTile(
                    'Enable background daemon sync',
                    'Automatically push data mutations to Tailnet server',
                    PreferencesService.bgSync.value,
                    (val) => PreferencesService.setBgSync(val),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    'Spatial Navigation Gestures',
                    'Navigate modules via swipe and drag events',
                    PreferencesService.spatialGestures.value,
                    (val) => PreferencesService.setSpatialGestures(val),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    'Developer Mode',
                    'Expose low-level diagnostics and logs overlays',
                    PreferencesService.devMode.value,
                    (val) => PreferencesService.setDevMode(val),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle('SPATIAL MATRIX EDITOR'),
                const SizedBox(height: 8),
                _buildCard([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Tap any slot to assign or swap a module.',
                          style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: EverforestColors.bg1,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: EverforestColors.bg2, width: 1),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: [
                              for (int r = 0; r < 3; r++)
                                for (int c = 0; c < 3; c++)
                                  _buildMatrixSlot(context, r, c),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: EverforestColors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: EverforestColors.bg2.withOpacity(0.5),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      title: Text(
        title,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
      ),
      trailing: Switch(
        value: value,
        activeColor: EverforestColors.green,
        activeTrackColor: EverforestColors.green.withOpacity(0.2),
        inactiveThumbColor: EverforestColors.grey,
        inactiveTrackColor: EverforestColors.bg2,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMatrixSlot(BuildContext context, int r, int c) {
    final layout = PreferencesService.layout.value;
    final String moduleId = layout[r][c];
    final String name = _getModuleName(moduleId);
    final bool isCenter = (r == 1 && c == 1);

    return GestureDetector(
      onTap: () => _showModuleSelector(context, r, c),
      child: Container(
        decoration: BoxDecoration(
          color: isCenter ? EverforestColors.green.withOpacity(0.15) : EverforestColors.bg0,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCenter ? EverforestColors.green : EverforestColors.bg2,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '[$r,$c]',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 9, fontFamily: 'JetBrainsMono'),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCenter ? EverforestColors.green : EverforestColors.fg,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModuleName(String id) {
    switch (id) {
      case 'radar': return 'Radar';
      case 'obsidian': return 'Obsidian';
      case 'infra': return 'Infra';
      case 'quests': return 'Quests';
      case 'home': return 'HOME';
      case 'media': return 'Media';
      case 'capture': return 'Capture';
      case 'configurator': return 'Config';
      case 'void': return 'Void';
      default: return 'Empty';
    }
  }

  void _showModuleSelector(BuildContext context, int r, int c) {
    final modules = [
      {'id': 'radar', 'name': 'Radar & Vision'},
      {'id': 'obsidian', 'name': 'Zen Workspace'},
      {'id': 'infra', 'name': 'Infra Hub'},
      {'id': 'quests', 'name': 'Quest Board'},
      {'id': 'home', 'name': 'Home View'},
      {'id': 'media', 'name': 'Media Vault'},
      {'id': 'capture', 'name': 'Fast Capture'},
      {'id': 'configurator', 'name': 'System Config'},
      {'id': 'void', 'name': 'Void / Empty'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign to Slot [$r, $c]',
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final item = modules[index];
                    return ListTile(
                      title: Text(
                        item['name']!,
                        style: const TextStyle(color: EverforestColors.fg),
                      ),
                      onTap: () {
                        final currentLayout = PreferencesService.layout.value;
                        final List<List<String>> newLayout = currentLayout.map((row) => List<String>.from(row)).toList();
                        
                        final String targetModuleId = item['id']!;
                        int foundRow = -1;
                        int foundCol = -1;
                        for (int i = 0; i < 3; i++) {
                          for (int j = 0; j < 3; j++) {
                            if (newLayout[i][j] == targetModuleId && targetModuleId != 'void') {
                              foundRow = i;
                              foundCol = j;
                            }
                          }
                        }

                        if (foundRow != -1 && foundCol != -1) {
                          newLayout[foundRow][foundCol] = currentLayout[r][c];
                        }
                        newLayout[r][c] = targetModuleId;

                        PreferencesService.setLayout(newLayout);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
