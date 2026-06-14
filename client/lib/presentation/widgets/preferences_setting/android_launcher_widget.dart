import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import 'package:drift/drift.dart' as drift;

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
      final apps = await InstalledApps.getInstalledApps(true, true);
      if (mounted) {
        setState(() {
          _apps = apps.where((a) => a.packageName != 'com.example.lifeos_client').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading apps: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
              style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.accent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Launch & Pay'),
            ),
          ],
        )
      );

      if (confirm == true) {
        await _deductPoints();
        InstalledApps.startApp(app.packageName!);
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

  @override
  Widget build(BuildContext context) {
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
              const Text('App Drawer (Launcher)', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.star, color: EverforestColors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Text('$_currentPoints pts', style: const TextStyle(color: EverforestColors.yellow, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: EverforestColors.accent))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
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
                              Image.memory(app.icon!, width: 48, height: 48)
                            else
                              const Icon(Icons.android, size: 48, color: EverforestColors.green),
                            const SizedBox(height: 8),
                            Text(
                              app.name ?? 'Unknown',
                              style: const TextStyle(color: EverforestColors.fg, fontSize: 12),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
