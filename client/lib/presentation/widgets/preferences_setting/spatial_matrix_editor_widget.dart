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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = layout[0].length;
                    final rows = layout.length;
                    final double slotSize = (constraints.maxWidth / cols).clamp(60.0, 140.0);
                    final double gridWidth = cols * slotSize + (cols - 1) * 12.0;

                    return Center(
                      child: SizedBox(
                        width: gridWidth,
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
                                crossAxisCount: cols,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: rows * cols,
                              itemBuilder: (context, index) {
                                final r = index ~/ cols;
                                final c = index % cols;
                                return _buildMatrixSlot(context, r, c, layout, isChild, slotSize);
                              },
                            ),
                          ],
                        ),
                      ),
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
      color: EverforestColors.bg2.withValues(alpha: 0.5),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildMatrixSlot(BuildContext context, int r, int c, List<List<String>> layout, bool isChild, double slotSize) {
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
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isHome ? const Color(0xFF00E5FF) : const Color(0xFFF8FFF4),
              fontFamily: 'JetBrainsMono',
              fontSize: (slotSize * 0.1).clamp(9.0, 12.0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<Map<String, String>>> _getGroupedModules() {
    return {
      'System & Settings': [
        {'id': 'home', 'name': 'Home View (Αρχική)'},
        {'id': 'configurator', 'name': 'Settings (Ρυθμίσεις & Updates)'},
        {'id': 'preferences_setting', 'name': 'Preferences & System Updates'},
        {'id': 'app_drawer', 'name': 'App Drawer (Εφαρμογές)'},
        {'id': 'nexus', 'name': 'Nexus System Dashboard'},
        {'id': 'void', 'name': 'Void / Κενό (Empty Slot)'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Faith & Scripture': [
        {'id': 'prayer_book', 'name': 'Prayer Book & Scripture (Προσευχολόγιο)'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Knowledge & Reading': [
        {'id': 'obsidian_zen', 'name': 'Obsidian Zen (Σημειώσεις & Έγγραφα)'},
        {'id': 'books', 'name': 'Book Library & EPUBs (Βιβλιοθήκη)'},
        {'id': 'knowledge_hub', 'name': 'Knowledge Hub'},
        {'id': 'knowledge_base', 'name': 'Knowledge Base & Wiki'},
        {'id': 'flashcards', 'name': 'Flashcards (Κάρτες Μάθησης)'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Communications & AI': [
        {'id': 'chat_hub', 'name': 'Messenger & P2P Chat'},
        {'id': 'project_infinity', 'name': 'Project Infinity (AI Canvas)'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Media & Entertainment': [
        {'id': 'media_hub', 'name': 'Media Hub (Μουσική, Ταινίες, Gallery)'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Finance & Banking': [
        {'id': 'finance', 'name': 'Finance Hub (Τράπεζες, Λογιστική)'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Gamification & Tasks': [
        {'id': 'rpg_hub', 'name': 'RPG Quest Board & Stars'},
        {'id': 'chtm', 'name': 'CHTM (Ημερολόγιο, Συνήθειες, Tasks)'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
      'Infrastructure & Smart Home': [
        {'id': 'infra', 'name': 'Infrastructure Hub (Servers, VMs)'},
        {'id': 'home_management', 'name': 'Smart Home (Έξυπνο Σπίτι)'},
        {'id': 'maps_live_tracking', 'name': 'Maps & Live Tracking (Χάρτες)'},
      ]..sort((a, b) => a['name']!.compareTo(b['name']!)),
    };
  }

  void _showModuleSelector(BuildContext context, int r, int c) {
    // For now we use the static definitions representing the OS ecosystem scope.
    // Future architectural step: merge with FeatureRegistry.
    final groupedModules = _getGroupedModules();

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
