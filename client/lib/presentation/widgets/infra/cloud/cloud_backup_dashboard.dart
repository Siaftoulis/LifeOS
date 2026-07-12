import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../theme/everforest_colors.dart';
import '../../../../core/device_backup_service.dart';
import '../../../../database/database.dart';
import '../../../../api_client.dart';

class CloudBackupDashboard extends StatefulWidget {
  const CloudBackupDashboard({super.key});

  @override
  State<CloudBackupDashboard> createState() => _CloudBackupDashboardState();
}

class _CloudBackupDashboardState extends State<CloudBackupDashboard> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _syncBackupsFromBackend();
  }

  Future<void> _syncBackupsFromBackend() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/backup/list');
      if (res is List) {
        final dao = AppDatabase.instance.cloudDao;
        for (var item in res) {
          final backup = item as Map<String, dynamic>;
          final id = backup['id'] as String;
          
          final entry = DeviceBackupsCompanion(
            id: drift.Value(id),
            name: drift.Value(backup['name'] as String? ?? id),
            lastBackup: drift.Value((backup['last_backup'] as num?)?.toInt() ?? 0),
            storagePath: drift.Value(backup['storage_path'] as String? ?? '/data/backups/$id'),
            backupStatus: drift.Value(backup['backup_status'] as String? ?? 'UNKNOWN'),
            updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
            isDirty: const drift.Value(0),
          );

          try {
            await dao.insertBackup(entry);
          } catch (_) {
            // Already exists or unique constraint hit
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync backups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(24.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            children: [
              const Text(
                'Cloud Backup',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_isRestoring)
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: EverforestColors.blue)))
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() => _isRestoring = true);
                        final success = await DeviceBackupService.restoreFromCloud();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Restored successfully from .pds file' : 'Restore failed')));
                          setState(() => _isRestoring = false);
                        }
                      },
                      icon: const Icon(Icons.download, color: EverforestColors.bg0, size: 18),
                      label: const Text('Restore', style: TextStyle(color: EverforestColors.bg0, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EverforestColors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  if (_isBackingUp)
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: EverforestColors.green)))
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() => _isBackingUp = true);
                        final success = await DeviceBackupService.performSmartBackup();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Backup successfully created (.pds)' : 'Backup failed')));
                          setState(() => _isBackingUp = false);
                        }
                      },
                      icon: const Icon(Icons.cloud_upload, color: EverforestColors.bg0),
                      label: const Text('Backup Now', style: TextStyle(color: EverforestColors.bg0, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EverforestColors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildStorageOverview(),
          const SizedBox(height: 32),
          const Text(
            'Recent Backups',
            style: TextStyle(
              color: EverforestColors.fg,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<DeviceBackup>>(
            stream: AppDatabase.instance.cloudDao.watchAllBackups(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: EverforestColors.blue));
              }
              final backups = snapshot.data!;
              if (backups.isEmpty) {
                return const Center(child: Text('No recent backups.', style: TextStyle(color: EverforestColors.grey)));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: backups.length,
                separatorBuilder: (context, index) => const Divider(color: EverforestColors.bg2),
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  final date = DateTime.fromMillisecondsSinceEpoch(backup.lastBackup * 1000);
                  final dateStr = "${date.month}/${date.day}/${date.year}";
                  final isCompleted = backup.backupStatus == 'COMPLETED' || backup.backupStatus == 'Completed';
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: EverforestColors.bg2,
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.sync,
                        color: isCompleted ? EverforestColors.green : EverforestColors.yellow,
                      ),
                    ),
                    title: Text(backup.name, style: const TextStyle(color: EverforestColors.fg)),
                    subtitle: Text(dateStr, style: const TextStyle(color: EverforestColors.grey)),
                    trailing: const Text("--", style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w500)),
                  );
                },
              );
            }
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStorageOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.65,
                  backgroundColor: EverforestColors.bg2,
                  color: EverforestColors.blue,
                  strokeWidth: 8,
                ),
              ),
              const Text(
                '65%',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Storage Usage',
                  style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '180 GB used out of 500 GB',
                  style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildLegendItem('System & Apps', EverforestColors.blue),
                    _buildLegendItem('Downloads', EverforestColors.purple),
                    _buildLegendItem('Other', EverforestColors.bg2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
      ],
    );
  }
}
