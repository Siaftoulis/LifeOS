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
import 'preferences_setting/tailscale_monitor_widget.dart';
import 'preferences_setting/spatial_matrix_editor_widget.dart';
import '../../core/dev_simulation_service.dart';

class GridConfigurator extends StatefulWidget {
  const GridConfigurator({super.key});

  @override
  State<GridConfigurator> createState() => _GridConfiguratorState();
}

class _GridConfiguratorState extends State<GridConfigurator> {



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
          PreferencesService.showPerformanceOverlay,
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
                    'Developer Mode',
                    'Expose low-level diagnostics and logs overlays',
                    PreferencesService.devMode.value,
                    isChild ? null : (val) => PreferencesService.setDevMode(val),
                  ),
                  if (PreferencesService.devMode.value) ...[
                    _buildDivider(),
                    _buildToggleTile(
                      'Performance Overlay',
                      'Toggle real-time FPS and rendering performance graphs',
                      PreferencesService.showPerformanceOverlay.value,
                      isChild ? null : (val) => PreferencesService.setShowPerformanceOverlay(val),
                    ),
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
                const TailscaleMonitorWidget(),
              ];

              final rightColumn = <Widget>[
                _buildSectionTitle('SPATIAL MATRIX EDITOR'),
                const SizedBox(height: 8),
                SpatialMatrixEditorWidget(isChild: isChild),
                const SizedBox(height: 24),
                _buildSectionTitle('LAUNCHER LAYOUT GRID'),
                const SizedBox(height: 8),
                const GridConfiguratorWidget(),
              ];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
                    sliver: SliverToBoxAdapter(
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
                    ),
                  ),
                ],
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
}
