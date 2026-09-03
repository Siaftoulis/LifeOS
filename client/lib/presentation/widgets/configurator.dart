import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';
import '../../database/preferences_service.dart';
import '../../auth_service.dart';
import 'preferences_setting/my_profile_widget.dart';
import 'preferences_setting/admin_console_widget.dart';
import 'preferences_setting/grid_configurator_widget.dart';

import 'preferences_setting/spatial_matrix_editor_widget.dart';
import 'preferences_setting/online_users_list_widget.dart';
import 'preferences_setting/system_updates_widget.dart';
import '../../core/dev_simulation_service.dart';
import '../../app_module_router.dart';

class GridConfigurator extends StatelessWidget {
  const GridConfigurator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        physics: const BouncingScrollPhysics(),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 24.0),
            child: Text(
              'SETTINGS',
              style: TextStyle(
                color: EverforestColors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsMenuTile(
                title: 'Account & Profile',
                subtitle: 'Manage active user profile and roles',
                icon: Icons.person_outline,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ProfileSettingsPage())),
              ),
              _buildDivider(),
              _SettingsMenuTile(
                title: 'System Preferences',
                subtitle: 'Background sync, dev mode, overlays',
                icon: Icons.settings_system_daydream,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SystemPreferencesPage())),
              ),
              _buildDivider(),
              _SettingsMenuTile(
                title: 'System Updates & OTA',
                subtitle: 'Check for updates, install new APK versions',
                icon: Icons.system_update_alt_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SystemUpdatesPage())),
              ),
              _buildDivider(),
              _SettingsMenuTile(
                title: 'User Interface',
                subtitle: 'Spatial matrix and launcher layout',
                icon: Icons.grid_view,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _UiSettingsPage())),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
            child: Text(
              'SPATIAL GRID & MODULES',
              style: TextStyle(
                color: EverforestColors.green,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsMenuTile(
                title: 'Spatial Matrix Editor',
                subtitle: 'Customize grid slots & assign modules (3x3 / 4x4)',
                icon: Icons.grid_goldenratio_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _UiSettingsPage())),
              ),
              _buildDivider(),
              _SettingsMenuTile(
                title: 'All Installed Modules',
                subtitle: 'Browse and launch all 20+ ecosystem hubs & tools',
                icon: Icons.dashboard_customize_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ModulesCatalogPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsMenuTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: Icon(icon, color: EverforestColors.green, size: 28),
      title: Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: EverforestColors.grey),
      onTap: onTap,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
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
}

Widget _buildDivider() {
  return Divider(
    height: 1,
    thickness: 1,
    color: EverforestColors.bg2.withValues(alpha: 0.5),
    indent: 60,
    endIndent: 16,
  );
}

// --- SUB PAGES ---

class _BaseSettingsPage extends StatelessWidget {
  final String title;
  final Widget body;

  const _BaseSettingsPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.green),
        title: Text(
          title,
          style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: body,
    );
  }
}

class _ProfileSettingsPage extends StatelessWidget {
  const _ProfileSettingsPage();

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsPage(
      title: 'Account & Profile',
      body: ListenableBuilder(
        listenable: PreferencesService.activeProfileRole,
        builder: (context, _) {
          final isChild = PreferencesService.activeProfileRole.value == 'CHILD';
          return ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            children: [
              if (isChild) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: EverforestColors.red.withValues(alpha: 0.1),
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
              const MyProfileWidget(),
              if (AuthService.instance.isAdmin) ...[
                const SizedBox(height: 16),
                const AdminConsoleWidget(),
                const SizedBox(height: 16),
                const OnlineUsersListWidget(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SystemPreferencesPage extends StatelessWidget {
  const _SystemPreferencesPage();

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsPage(
      title: 'System Preferences',
      body: ListenableBuilder(
        listenable: Listenable.merge([
          PreferencesService.bgSync,
          PreferencesService.devMode,
          PreferencesService.showPerformanceOverlay,
          PreferencesService.showConnectionStatusOverlay,
          PreferencesService.activeProfileRole,
        ]),
        builder: (context, _) {
          final isChild = PreferencesService.activeProfileRole.value == 'CHILD';
          return ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            children: [
              _SettingsCard(
                children: [
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
                    _buildToggleTile(
                      'Connection Status Overlay',
                      'Toggle real-time LOCAL WI-FI 🏠 vs HEADSCALE MESH 🌐 top badge',
                      PreferencesService.showConnectionStatusOverlay.value,
                      isChild ? null : (val) => PreferencesService.setShowConnectionStatusOverlay(val),
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
                ],
              ),
            ],
          );
        },
      ),
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
        activeThumbColor: EverforestColors.green,
        activeTrackColor: EverforestColors.green.withValues(alpha: 0.2),
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


class _UiSettingsPage extends StatelessWidget {
  const _UiSettingsPage();

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsPage(
      title: 'User Interface',
      body: ListenableBuilder(
        listenable: PreferencesService.activeProfileRole,
        builder: (context, _) {
          final isChild = PreferencesService.activeProfileRole.value == 'CHILD';
          return ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'SPATIAL MATRIX EDITOR',
                  style: TextStyle(
                    color: EverforestColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SpatialMatrixEditorWidget(isChild: isChild),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'LAUNCHER LAYOUT GRID',
                  style: TextStyle(
                    color: EverforestColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const GridConfiguratorWidget(),
            ],
          );
        },
      ),
    );
  }
}

class _SystemUpdatesPage extends StatelessWidget {
  const _SystemUpdatesPage();

  @override
  Widget build(BuildContext context) {
    return const _BaseSettingsPage(
      title: 'System & OTA Updates',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        physics: BouncingScrollPhysics(),
        child: SystemUpdatesWidget(),
      ),
    );
  }
}

class _ModulesCatalogPage extends StatelessWidget {
  const _ModulesCatalogPage();

  static const List<Map<String, dynamic>> _allModules = [
    {'id': 'home', 'name': 'Home View', 'category': 'System', 'desc': 'Daily overview, quick widgets and status', 'icon': Icons.home_rounded},
    {'id': 'prayer_book', 'name': 'Prayer Book & Scripture', 'category': 'Faith', 'desc': 'Προσευχολόγιο, Ψαλτήριον, Αγία Γραφή, Ακολουθίες', 'icon': Icons.auto_stories_rounded},
    {'id': 'obsidian_zen', 'name': 'Obsidian Zen', 'category': 'Knowledge', 'desc': 'Markdown workspace and notes vault', 'icon': Icons.edit_note_rounded},
    {'id': 'books', 'name': 'Book Library', 'category': 'Knowledge', 'desc': 'EPUB reader & digital book library', 'icon': Icons.menu_book_rounded},
    {'id': 'flashcards', 'name': 'Flashcards', 'category': 'Knowledge', 'desc': 'Spaced repetition learning decks', 'icon': Icons.style_rounded},
    {'id': 'knowledge_hub', 'name': 'Knowledge Hub', 'category': 'Knowledge', 'desc': 'Comprehensive knowledge and documents hub', 'icon': Icons.psychology_rounded},
    {'id': 'knowledge_base', 'name': 'Knowledge Base', 'category': 'Knowledge', 'desc': 'Wiki and structured knowledge base', 'icon': Icons.account_tree_rounded},
    {'id': 'chat_hub', 'name': 'Messenger & P2P Chat', 'category': 'Social', 'desc': 'Tailscale mesh encrypted messaging & calls', 'icon': Icons.chat_bubble_rounded},
    {'id': 'project_infinity', 'name': 'Project Infinity', 'category': 'AI & Automation', 'desc': 'Interactive generative AI canvas', 'icon': Icons.all_inclusive_rounded},
    {'id': 'media_hub', 'name': 'Media Hub', 'category': 'Media', 'desc': 'Music player, Movies, YouTube, Gallery', 'icon': Icons.perm_media_rounded},
    {'id': 'finance', 'name': 'Finance Hub', 'category': 'Finance', 'desc': 'Banking, accounting, transactions & assets', 'icon': Icons.account_balance_rounded},
    {'id': 'rpg_hub', 'name': 'RPG Quest Board', 'category': 'Gamification', 'desc': 'Daily quests, star points & leveling', 'icon': Icons.military_tech_rounded},
    {'id': 'chtm', 'name': 'CHTM Tracker', 'category': 'Productivity', 'desc': 'Calendar, Habits, Tasks & Matrix', 'icon': Icons.calendar_today_rounded},
    {'id': 'infra', 'name': 'Infrastructure Hub', 'category': 'DevOps', 'desc': 'Servers, Hyper-V, Tailnet & Docker', 'icon': Icons.dns_rounded},
    {'id': 'home_management', 'name': 'Smart Home', 'category': 'IoT', 'desc': 'Home Assistant devices & scene triggers', 'icon': Icons.cottage_rounded},
    {'id': 'maps_live_tracking', 'name': 'Maps & Live Tracking', 'category': 'Geo', 'desc': 'Offline maps & real-time GPS tracking', 'icon': Icons.map_rounded},
    {'id': 'nexus', 'name': 'Nexus Dashboard', 'category': 'System', 'desc': 'Central system monitoring & telemetry', 'icon': Icons.hub_rounded},
    {'id': 'app_drawer', 'name': 'Android App Drawer', 'category': 'System', 'desc': 'Installed device application launcher', 'icon': Icons.apps_rounded},
    {'id': 'configurator', 'name': 'Settings & Updates', 'category': 'System', 'desc': 'System preferences & OTA updates', 'icon': Icons.settings_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsPage(
      title: 'Installed Modules Directory',
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        itemCount: _allModules.length,
        itemBuilder: (context, idx) {
          final mod = _allModules[idx];
          return Card(
            color: EverforestColors.bg1,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: EverforestColors.bg2),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EverforestColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(mod['icon'] as IconData, color: EverforestColors.green, size: 22),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      mod['name'] as String,
                      style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      mod['category'] as String,
                      style: const TextStyle(color: EverforestColors.grey, fontSize: 10),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  mod['desc'] as String,
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: EverforestColors.grey, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: EverforestColors.bg0,
                        title: Text(mod['name'] as String, style: const TextStyle(color: EverforestColors.fg, fontSize: 16)),
                        iconTheme: const IconThemeData(color: EverforestColors.green),
                      ),
                      body: AppModuleRouter.buildModule(mod['id'] as String),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
