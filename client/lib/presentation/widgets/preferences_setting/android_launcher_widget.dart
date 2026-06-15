import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/preferences_service.dart';
import '../../../api_client.dart';

class AndroidLauncherWidget extends StatefulWidget {
  const AndroidLauncherWidget({super.key});

  @override
  State<AndroidLauncherWidget> createState() => _AndroidLauncherWidgetState();
}

class _AndroidLauncherWidgetState extends State<AndroidLauncherWidget> {
  List<AppInfo> _apps = [];
  bool _isLoading = true;
  int _currentPoints = 0;
  final int _costPerAppLaunch = 10;
  final Map<String, bool> _expandedFolders = {};

  @override
  void initState() {
    super.initState();
    _loadApps();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final user = await AppDatabase.instance.pointsDao.getUserProfile('admin');
      if (user != null && mounted) {
        setState(() {
          _currentPoints = user.currentPoints;
        });
      }
    } catch (e) {
      debugPrint('Error loading points: $e');
    }
  }

  Future<void> _deductPoints() async {
    try {
      final user = await AppDatabase.instance.pointsDao.getUserProfile('admin');
      if (user != null) {
        await AppDatabase.instance.pointsDao.updateUser(user.copyWith(currentPoints: user.currentPoints - _costPerAppLaunch));
        _loadPoints();
      }
    } catch (e) {
      debugPrint('Error deducting points: $e');
    }
  }

  Future<void> _loadApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
      if (mounted) {
        // Detect old categories schema and trigger reset
        final cached = PreferencesService.appCategories.value;
        final hasOldCategories = cached.values.any((cat) =>
          cat == 'Chat & Communication' ||
          cat == 'Social Media' ||
          cat == 'Productivity' ||
          cat == 'Entertainment' ||
          cat == 'Travel & Navigation' ||
          cat == 'System & Utilities' ||
          cat == 'Other'
        );
        if (hasOldCategories) {
          PreferencesService.appCategories.value = {};
          await PreferencesService.save();
        }

        setState(() {
          _apps = apps.where((a) => a.packageName != 'com.example.lifeos_client').toList();
          _isLoading = false;
        });
        await _categorizeMissingApps();
      }
    } catch (e) {
      debugPrint("Error loading apps: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _categorizeMissingApps() async {
    final cached = PreferencesService.appCategories.value;
    final List<AppInfo> missing = [];
    for (final app in _apps) {
      if (!cached.containsKey(app.packageName)) {
        missing.add(app);
      }
    }

    if (missing.isEmpty) return;

    try {
      final response = await ApiClient.instance.postDaemon('/api/v1/system/apps/categorize', {
        'apps': missing.map((app) => {
          'package_name': app.packageName,
          'name': app.name,
        }).toList(),
      });

      if (response != null && response['categories'] != null) {
        final Map<String, dynamic> cats = response['categories'];
        final Map<String, String> newCategories = cats.map((k, v) => MapEntry(k, v.toString()));
        await PreferencesService.saveAppCategories(newCategories);
        if (mounted) setState(() {});
        return;
      }
    } catch (e) {
      debugPrint("Daemon categorization failed, falling back to heuristics: $e");
    }

    // Local fallback
    final Map<String, String> localCats = {};
    for (final app in missing) {
      localCats[app.packageName] = _classifyHeuristically(app.packageName, app.name);
    }
    await PreferencesService.saveAppCategories(localCats);
    if (mounted) setState(() {});
  }

  String _classifyHeuristically(String packageName, String appName) {
    final pkg = packageName.toLowerCase();
    final name = appName.toLowerCase();

    // 1. Games
    if (pkg.contains("game") ||
        pkg.contains("gaming") ||
        pkg.contains("arcade") ||
        pkg.contains("puzzle") ||
        pkg.contains("sport") ||
        pkg.contains("play.games") ||
        pkg.contains("xbox") ||
        pkg.contains("playstation") ||
        pkg.contains("steam") ||
        pkg.contains("retroarch") ||
        name.contains("game") ||
        name.contains("toy")) {
      if (!pkg.contains("vending") && !pkg.contains("play.services")) {
        return "Games";
      }
    }

    // 2. Photographs
    if (pkg.contains("camera") ||
        pkg.contains("gallery") ||
        pkg.contains("photo") ||
        pkg.contains("image") ||
        pkg.contains("paint") ||
        pkg.contains("draw") ||
        pkg.contains("sketch") ||
        pkg.contains("photograph") ||
        pkg.contains("picture") ||
        pkg.contains("lens") ||
        pkg.contains("snapseed") ||
        pkg.contains("photoshop") ||
        pkg.contains("gopro") ||
        name.contains("camera") ||
        name.contains("photo") ||
        name.contains("gallery") ||
        name.contains("picture")) {
      return "Photographs";
    }

    // 3. Google Archives
    if (pkg.contains("com.google") ||
        pkg.contains("google.android") ||
        pkg.contains("chrome") ||
        pkg.contains("youtube") ||
        pkg.contains("gmail") ||
        pkg.contains("vending") ||
        pkg.contains("com.google.android.gm") ||
        name.contains("google") ||
        name.contains("chrome") ||
        name.contains("youtube") ||
        name.contains("gmail") ||
        name.contains("drive") ||
        name.contains("hangouts") ||
        name.contains("sheets") ||
        name.contains("docs") ||
        name.contains("slides") ||
        name.contains("meet") ||
        name.contains("duo")) {
      return "Google Archives";
    }

    return "Everything Else";
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Games':
        return EverforestColors.red;
      case 'Photographs':
        return EverforestColors.blue;
      case 'Google Archives':
        return EverforestColors.yellow;
      default:
        return EverforestColors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Games':
        return Icons.sports_esports_outlined;
      case 'Photographs':
        return Icons.camera_alt_outlined;
      case 'Google Archives':
        return Icons.archive_outlined;
      default:
        return Icons.folder_open_outlined;
    }
  }

  Map<String, List<AppInfo>> _getGroupedApps() {
    final Map<String, List<AppInfo>> grouped = {
      'Games': [],
      'Photographs': [],
      'Google Archives': [],
      'Everything Else': [],
    };

    final cached = PreferencesService.appCategories.value;
    for (final app in _apps) {
      final cat = cached[app.packageName] ?? 'Everything Else';
      if (grouped.containsKey(cat)) {
        grouped[cat]!.add(app);
      } else {
        grouped['Everything Else']!.add(app);
      }
    }

    grouped.removeWhere((key, list) => list.isEmpty);
    return grouped;
  }

  void _openApp(AppInfo app) async {
    if (_currentPoints >= _costPerAppLaunch) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: EverforestColors.bg1,
          title: Text('Launch ${app.name}?', style: const TextStyle(color: EverforestColors.fg)),
          content: Text('Launching this app will cost $_costPerAppLaunch Star Points.\n\nCurrent Points: $_currentPoints', style: const TextStyle(color: EverforestColors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Launch & Pay'),
            ),
          ],
        )
      );

      if (confirm == true) {
        await _deductPoints();
        InstalledApps.startApp(app.packageName);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough points! You need $_costPerAppLaunch to launch this app.'),
          backgroundColor: EverforestColors.red,
        )
      );
    }
  }

  Widget _buildFlatView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _apps.length,
      itemBuilder: (context, index) {
        final app = _apps[index];
        return GestureDetector(
          onTap: () => _openApp(app),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (app.icon != null)
                Image.memory(app.icon!, width: 44, height: 44)
              else
                const Icon(Icons.android, size: 44, color: EverforestColors.green),
              const SizedBox(height: 6),
              Text(
                app.name,
                style: const TextStyle(color: EverforestColors.fg, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFolderView() {
    final grouped = _getGroupedApps();
    final categories = grouped.keys.toList();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final appsInCategory = grouped[category]!;
        final isExpanded = _expandedFolders[category] ?? true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _expandedFolders[category] = !isExpanded;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: EverforestColors.bg2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${appsInCategory.length})',
                      style: const TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: EverforestColors.grey,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: appsInCategory.length,
                itemBuilder: (context, idx) {
                  final app = appsInCategory[idx];
                  return GestureDetector(
                    onTap: () => _openApp(app),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (app.icon != null)
                          Image.memory(app.icon!, width: 40, height: 40)
                        else
                          const Icon(Icons.android, size: 40, color: EverforestColors.green),
                        const SizedBox(height: 6),
                        Text(
                          app.name,
                          style: const TextStyle(color: EverforestColors.fg, fontSize: 11),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFolderView = PreferencesService.appDrawerFolderView.value;

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('App Drawer', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Flat Grid View',
                    icon: Icon(
                      Icons.grid_view,
                      color: !isFolderView ? EverforestColors.green : EverforestColors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      PreferencesService.setAppDrawerFolderView(false);
                      setState(() {});
                    },
                  ),
                  IconButton(
                    tooltip: 'Folder View',
                    icon: Icon(
                      Icons.folder_open_outlined,
                      color: isFolderView ? EverforestColors.green : EverforestColors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      PreferencesService.setAppDrawerFolderView(true);
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: EverforestColors.yellow, size: 20),
                  const SizedBox(width: 4),
                  Text('$_currentPoints pts', style: const TextStyle(color: EverforestColors.yellow, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: EverforestColors.green))
                : (isFolderView ? _buildFolderView() : _buildFlatView()),
          ),
        ],
      ),
    );
  }
}
