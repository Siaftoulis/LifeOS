import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/preferences_service.dart';
import '../../../core/spatial_matrix_manager.dart';

class SpatialMatrixEditorWidget extends StatelessWidget {
  final bool isChild;
  
  const SpatialMatrixEditorWidget({super.key, required this.isChild});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PreferencesService.layout,
      builder: (context, _) {
        final layout = PreferencesService.layout.value;
        return Material(
          color: EverforestColors.bg1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: EverforestColors.bg2, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildResizeControlRow(
                'Matrix Rows:',
                layout.length,
                isChild ? null : () => SpatialMatrixManager.dropRow(),
                isChild ? null : () => SpatialMatrixManager.addRow(),
              ),
              _buildDivider(),
              _buildResizeControlRow(
                'Matrix Columns:',
                layout[0].length,
                isChild ? null : () => SpatialMatrixManager.dropColumn(),
                isChild ? null : () => SpatialMatrixManager.addColumn(),
              ),
              const SizedBox(height: 16),
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
                        return _buildMatrixSlot(context, r, c, layout, isChild);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResizeControlRow(String label, int val, VoidCallback? onDecrement, VoidCallback? onIncrement) {
    final disabled = onDecrement == null || onIncrement == null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      title: Text(
        label,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: EverforestColors.red),
            onPressed: disabled ? null : onDecrement,
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
          IconButton(
            icon: const Icon(Icons.add, color: EverforestColors.green),
            onPressed: disabled ? null : onIncrement,
          ),
        ],
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

  Widget _buildMatrixSlot(BuildContext context, int r, int c, List<List<String>> layout, bool isChild) {
    final String moduleId = layout[r][c];
    final isHome = (moduleId == 'home');
    
    final Color bgColor = isHome ? const Color(0x1500E5FF) : const Color(0xFF09090B);
    final Color borderColor = isHome ? const Color(0xFF00E5FF) : const Color(0xFF27272A);
    final double borderWidth = isHome ? 2.0 : 1.0;
    
    final String displayText = (moduleId.isEmpty || moduleId == 'void') ? '+' : moduleId.toUpperCase();

    return GestureDetector(
      onTap: isChild ? null : () => _showModuleSelector(context, r, c),
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
              color: isHome ? const Color(0xFF00E5FF) : const Color(0xFFF8FFF4),
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
    // For now we use the static definitions representing the OS ecosystem scope.
    // Future architectural step: merge with FeatureRegistry.
    final groupedModules = {
      'System & Core': [
        {'id': 'home', 'name': 'Home View'},
        {'id': 'configurator', 'name': 'System Config'},
        {'id': 'tailscale_mesh', 'name': 'Tailscale Mesh Monitor'},
        {'id': 'app_drawer', 'name': 'App Drawer'},
        {'id': 'capture', 'name': 'Fast Capture'},
        {'id': 'void', 'name': 'Void / Empty'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Productivity & Knowledge': [
        {'id': 'obsidian_zen', 'name': 'Obsidian Zen Editor'},
        {'id': 'knowledge_base', 'name': 'Knowledge Base'},
        {'id': 'flashcards', 'name': 'Flashcards / SRS'},
        {'id': 'books', 'name': 'Book Library'},
        {'id': 'project_infinity', 'name': 'Project Infinity'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Gamification & Tasks': [
        {'id': 'point_star_system', 'name': 'Point Star System'},
        {'id': 'quests', 'name': 'Quest Board'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Media & Entertainment': [
        {'id': 'photo_video_gallery', 'name': 'Photo Video Gallery'},
        {'id': 'movie_library', 'name': 'Movie Library'},
        {'id': 'music_library', 'name': 'Music Library'},
        {'id': 'youtube_client', 'name': 'YouTube Client'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Finance': [
        {'id': 'accounting', 'name': 'Accounting'},
        {'id': 'banking', 'name': 'Banking System'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Infrastructure & Utils': [
        {'id': 'infra', 'name': 'Infra Hub'},
        {'id': 'cloud', 'name': 'Cloud Backups'},
        {'id': 'darkweb', 'name': 'Dark Web / Torrents'},
        {'id': 'home_management', 'name': 'Home Management'},
        {'id': 'maps_live_tracking', 'name': 'Maps & Live Tracking'},
        {'id': 'virtual_machine', 'name': 'Virtual Machine Management'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
    };

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
                  itemCount: groupedModules.keys.length,
                  itemBuilder: (context, index) {
                    final category = groupedModules.keys.elementAt(index);
                    final modules = groupedModules[category]!;
                    
                    return ExpansionTile(
                      iconColor: EverforestColors.green,
                      collapsedIconColor: EverforestColors.grey,
                      title: Text(
                        category,
                        style: const TextStyle(
                          color: EverforestColors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: modules.map((item) {
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
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

                            final evicted = currentLayout[r][c];

                            if (foundRow != -1 && foundCol != -1) {
                              newLayout[foundRow][foundCol] = evicted;
                              newLayout[r][c] = targetModuleId;
                            } else {
                              if (SpatialMatrixManager.protectedModules.contains(evicted) && targetModuleId != evicted) {
                                bool relocated = false;
                                for (int i = 0; i < newLayout.length; i++) {
                                  for (int j = 0; j < newLayout[i].length; j++) {
                                    if (newLayout[i][j] == 'void' || newLayout[i][j] == '') {
                                      newLayout[i][j] = evicted;
                                      relocated = true;
                                      break;
                                    }
                                  }
                                  if (relocated) break;
                                }
                                
                                if (!relocated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cannot replace protected module. Add a void slot first.')),
                                  );
                                  Navigator.pop(context);
                                  return;
                                }
                              }
                              newLayout[r][c] = targetModuleId;
                            }

                            PreferencesService.setLayout(newLayout);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
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
