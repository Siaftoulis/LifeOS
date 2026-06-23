import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/everforest_colors.dart';
import '../../database/preferences_service.dart';
import '../../api_client.dart';
import '../../auth_service.dart';
import 'preferences_setting/my_profile_widget.dart';
import 'preferences_setting/admin_console_widget.dart';
import 'preferences_setting/grid_configurator_widget.dart';
import '../../core/dev_simulation_service.dart';

class GridConfigurator extends StatefulWidget {
  const GridConfigurator({super.key});

  @override
  State<GridConfigurator> createState() => _GridConfiguratorState();
}

class _GridConfiguratorState extends State<GridConfigurator> {
  List<dynamic> _nodes = [];
  bool _isLoadingNodes = false;
  String _nodesError = '';

  @override
  void initState() {
    super.initState();
    _fetchNodes();
  }

  Future<void> _fetchNodes() async {
    if (mounted) setState(() => _isLoadingNodes = true);
    try {
      final daemonUrl = ApiClient.discoverBaseUrl().then((baseUrl) async {
        final url = baseUrl.replaceAll(':8080', ':50051');
        final response = await http.get(Uri.parse('$url/api/v1/system/nodes')).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _nodes = data.where((n) {
                final name = (n['name']?.toString() ?? '').toLowerCase();
                return !name.contains('panel') && !name.contains('ingest');
              }).toList();
              _nodesError = '';
            });
          }
        } else {
          throw Exception('Status code ${response.statusCode}');
        }
      });
      await daemonUrl;
    } catch (e) {
      if (mounted) {
        setState(() {
          _nodesError = 'Daemon nodes scan offline';
          // Populate default mockup list for development verification
          _nodes = [
            {'ip': '100.76.247.27', 'name': 'pds-laptop-1', 'online': true},
            {'ip': '100.76.247.28', 'name': 'pds-mobile-android', 'online': false},
          ];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingNodes = false);
    }
  }



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
          PreferencesService.activeProfileRole,
          PreferencesService.activeProfileId,
        ]),
        builder: (context, _) {
          final isChild = PreferencesService.activeProfileRole.value == 'CHILD';
          final currentRole = PreferencesService.activeProfileRole.value;
          final layout = PreferencesService.layout.value;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              
              final leftColumn = <Widget>[
                if (isChild) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: EverforestColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EverforestColors.red, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, color: EverforestColors.red, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Child Account Restriction Active. Administrative Settings Locked.',
                            style: TextStyle(color: EverforestColors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _buildSectionTitle('ACTIVE USER PROFILE'),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MyProfileWidget(),
                    if (AuthService.instance.isAdmin) ...[
                      const SizedBox(height: 16),
                      const AdminConsoleWidget(),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('SYSTEM PREFERENCES'),
                const SizedBox(height: 8),
                _buildCard([
                  _buildToggleTile(
                    'Enable background daemon sync',
                    'Automatically push data mutations to Tailnet server',
                    PreferencesService.bgSync.value,
                    isChild ? null : (val) => PreferencesService.setBgSync(val),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    'Spatial Navigation Gestures',
                    'Navigate modules via swipe and drag events',
                    PreferencesService.spatialGestures.value,
                    isChild ? null : (val) => PreferencesService.setSpatialGestures(val),
                  ),
                  _buildDivider(),
                  _buildToggleTile(
                    'Developer Mode',
                    'Expose low-level diagnostics and logs overlays',
                    PreferencesService.devMode.value,
                    isChild ? null : (val) => PreferencesService.setDevMode(val),
                  ),
                  if (PreferencesService.devMode.value) ...[
                    _buildDivider(),
                    _buildActionTile(
                      'Mount All Modules',
                      'Pre-warm and mount all registered features into memory',
                      Icons.memory,
                      () => DevSimulationService.mountAllModules(context),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      'Capture UI State',
                      'Take screenshots of all active modules and save locally',
                      Icons.camera_alt,
                      () => DevSimulationService.captureScreenshots(context),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      'Trace Runtime Logs',
                      'Analyze and dump all recent system events',
                      Icons.bug_report,
                      () => DevSimulationService.traceLogs(context),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      'Run Full Automation Suite',
                      'Automatically iterate, screenshot, and upload to Daemon',
                      Icons.auto_awesome,
                      () => DevSimulationService.runFullSimulation(context),
                    ),
                  ],
                ]),
                const SizedBox(height: 24),

                _buildSectionTitle('TAILSCALE MESH MONITOR'),
                const SizedBox(height: 8),
                _buildCard([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Connected Node Peers', style: TextStyle(color: EverforestColors.fg, fontSize: 13, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: EverforestColors.green, size: 18),
                          onPressed: _fetchNodes,
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(),
                  if (_isLoadingNodes)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator(color: EverforestColors.green)),
                    )
                  else if (_nodesError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_nodesError, style: const TextStyle(color: EverforestColors.red, fontSize: 11)),
                    )
                  else if (_nodes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No active nodes discovered', style: TextStyle(color: EverforestColors.grey, fontSize: 11)),
                    )
                  else
                    ListTile(
                      leading: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: EverforestColors.green,
                        ),
                      ),
                      title: const Text('Tunnel Connected', style: TextStyle(color: EverforestColors.fg, fontSize: 12, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold)),
                      subtitle: Text('${_nodes.length} Active Relay Nodes', style: const TextStyle(color: EverforestColors.grey, fontSize: 10, fontFamily: 'JetBrainsMono')),
                      trailing: const Text(
                        'SECURE',
                        style: TextStyle(color: EverforestColors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ]),
              ];

              final rightColumn = <Widget>[
                _buildSectionTitle('SPATIAL MATRIX EDITOR'),
                const SizedBox(height: 8),
                _buildCard([
                  _buildResizeControlRow(
                    'Matrix Rows:',
                    layout.length,
                    isChild ? null : () {
                      final rows = layout.length;
                      final cols = layout[0].length;
                      if (rows > 1 && (rows - 1) * cols >= 2) {
                        final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
                        final rowToDrop = newLayout.last;
                        final protected = ['home', 'configurator'];
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
                            for (int i = 0; i < rows - 1; i++) {
                              for (int j = 0; j < cols; j++) {
                                if (!protected.contains(newLayout[i][j])) {
                                  newLayout[i][j] = module;
                                  relocated = true;
                                  break;
                                }
                              }
                              if (relocated) break;
                            }
                          }
                        }
                        newLayout.removeLast();
                        PreferencesService.setLayout(newLayout);
                      }
                    },
                    isChild ? null : () {
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
                    isChild ? null : () {
                      final cols = layout[0].length;
                      final rows = layout.length;
                      if (cols > 1 && rows * (cols - 1) >= 2) {
                        final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
                        final protected = ['home', 'configurator'];
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
                            for (int i = 0; i < rows; i++) {
                              for (int j = 0; j < cols - 1; j++) {
                                if (!protected.contains(newLayout[i][j])) {
                                  newLayout[i][j] = module;
                                  relocated = true;
                                  break;
                                }
                              }
                              if (relocated) break;
                            }
                          }
                        }
                        for (final row in newLayout) {
                          row.removeLast();
                        }
                        PreferencesService.setLayout(newLayout);
                      }
                    },
                    isChild ? null : () {
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
                            return _buildMatrixSlot(context, r, c, layout, isChild);
                          },
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('LAUNCHER LAYOUT GRID'),
                const SizedBox(height: 8),
                const GridConfiguratorWidget(),
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: leftColumn,
                                ),
                              ),
                              const SizedBox(width: 48),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: rightColumn,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...leftColumn,
                              const SizedBox(height: 24),
                              ...rightColumn,
                            ],
                          ),
                  ),
                ),
              );
            },
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
    return Material(
      color: EverforestColors.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: EverforestColors.bg2, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
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

  Widget _buildToggleTile(String title, String subtitle, bool value, ValueChanged<bool>? onChanged) {
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

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: Icon(icon, color: EverforestColors.green),
      title: Text(
        title,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
      ),
      trailing: const Icon(Icons.chevron_right, color: EverforestColors.grey, size: 20),
      onTap: onTap,
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

                            final protected = ['home', 'configurator'];
                            final evicted = currentLayout[r][c];

                            if (foundRow != -1 && foundCol != -1) {
                              newLayout[foundRow][foundCol] = evicted;
                              newLayout[r][c] = targetModuleId;
                            } else {
                              if (protected.contains(evicted) && targetModuleId != evicted) {
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
