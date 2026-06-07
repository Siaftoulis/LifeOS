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
          final layout = PreferencesService.layout.value;
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
                  _buildResizeControlRow(
                    'Matrix Rows:',
                    layout.length,
                    () {
                      final rows = layout.length;
                      final cols = layout[0].length;
                      if (rows > 1 && (rows - 1) * cols >= 2) {
                        final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
                        final rowToDrop = newLayout.last;
                        final protected = ['nexus', 'configurator'];
                        final evicted = <String>[];
                        for (final module in rowToDrop) {
                          if (protected.contains(module)) {
                            evicted.add(module);
                          }
                        }
                        for (final module in evicted) {
                          bool relocated = false;
                          for (int i = 0; i < rows - 1; i++) {
                            for (int j = 0; j < newLayout[i].length; j++) {
                              if (newLayout[i][j] == 'void' || newLayout[i][j] == '') {
                                newLayout[i][j] = module;
                                relocated = true;
                                break;
                              }
                            }
                            if (relocated) break;
                          }
                          if (!relocated) {
                            newLayout[0][0] = module;
                          }
                        }
                        newLayout.removeLast();
                        PreferencesService.setLayout(newLayout);
                      }
                    },
                    () {
                      final cols = layout[0].length;
                      final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
                      newLayout.add(List.filled(cols, 'void'));
                      PreferencesService.setLayout(newLayout);
                    },
                  ),
                  _buildDivider(),
                  _buildResizeControlRow(
                    'Matrix Columns:',
                    layout[0].length,
                    () {
                      final cols = layout[0].length;
                      final rows = layout.length;
                      if (cols > 1 && rows * (cols - 1) >= 2) {
                        final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
                        final protected = ['nexus', 'configurator'];
                        final evicted = <String>[];
                        for (int i = 0; i < newLayout.length; i++) {
                          final module = newLayout[i][cols - 1];
                          if (protected.contains(module)) {
                            evicted.add(module);
                          }
                        }
                        for (final module in evicted) {
                          bool relocated = false;
                          for (int i = 0; i < newLayout.length; i++) {
                            for (int j = 0; j < cols - 1; j++) {
                              if (newLayout[i][j] == 'void' || newLayout[i][j] == '') {
                                newLayout[i][j] = module;
                                relocated = true;
                                break;
                              }
                            }
                            if (relocated) break;
                          }
                          if (!relocated) {
                            newLayout[0][0] = module;
                          }
                        }
                        for (final row in newLayout) {
                          row.removeLast();
                        }
                        PreferencesService.setLayout(newLayout);
                      }
                    },
                    () {
                      final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
                      for (final row in newLayout) {
                        row.add('void');
                      }
                      PreferencesService.setLayout(newLayout);
                    },
                  ),
                ]),
                const SizedBox(height: 16),
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
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: layout[0].length,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: layout.length * layout[0].length,
                          itemBuilder: (context, index) {
                            final r = index ~/ layout[0].length;
                            final c = index % layout[0].length;
                            return _buildMatrixSlot(context, r, c, layout);
                          },
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

  Widget _buildResizeControlRow(String label, int val, VoidCallback onDecrement, VoidCallback onIncrement) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      title: Text(
        label,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Decrease',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.remove, color: EverforestColors.red),
              tooltip: 'Decrease',
              onPressed: onDecrement,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              val.toString(),
              style: const TextStyle(
                color: EverforestColors.fg,
                fontFamily: 'JetBrainsMono',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Semantics(
            label: 'Increase',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.add, color: EverforestColors.green),
              tooltip: 'Increase',
              onPressed: onIncrement,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixSlot(BuildContext context, int r, int c, List<List<String>> layout) {
    final String moduleId = layout[r][c];
    final isNexus = (moduleId == 'nexus');
    
    final Color bgColor = isNexus ? const Color(0x1500E5FF) : const Color(0xFF09090B);
    final Color borderColor = isNexus ? const Color(0xFF00E5FF) : const Color(0xFF27272A);
    final double borderWidth = isNexus ? 2.0 : 1.0;
    
    final String displayText = (moduleId.isEmpty || moduleId == 'void') ? '+' : moduleId.toUpperCase();

    return GestureDetector(
      onTap: () => _showModuleSelector(context, r, c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              color: isNexus ? const Color(0xFF00E5FF) : const Color(0xFFF8FFF4),
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
                        for (int i = 0; i < newLayout.length; i++) {
                          for (int j = 0; j < newLayout[i].length; j++) {
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
