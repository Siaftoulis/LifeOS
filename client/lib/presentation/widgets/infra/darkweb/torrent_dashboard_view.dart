import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../theme/everforest_colors.dart';
import '../../../../database/database.dart';
import '../../../../api_client.dart';

class TorrentDashboardView extends StatefulWidget {
  const TorrentDashboardView({super.key});

  @override
  State<TorrentDashboardView> createState() => _TorrentDashboardViewState();
}

class _TorrentDashboardViewState extends State<TorrentDashboardView> {
  @override
  void initState() {
    super.initState();
    _syncTorrentsFromBackend();
  }

  Future<void> _syncTorrentsFromBackend() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/darkweb/torrents');
      if (res is List) {
        final dao = AppDatabase.instance.darkWebDao;
        for (var item in res) {
          final t = item as Map<String, dynamic>;
          
          final entry = TorrentsCompanion(
            id: drift.Value(t['info_hash'] as String),
            name: drift.Value(t['name'] as String),
            status: drift.Value(t['status'] as String),
            progress: drift.Value((t['progress'] as num).toDouble()),
            sizeBytes: const drift.Value(1000000000), // Mock
            downloadSpeed: const drift.Value(1200000), // Mock
            isDirty: const drift.Value(0),
          );

          try {
            await dao.insertTorrent(entry);
          } catch (_) {
            await dao.updateTorrent(entry);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync torrents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            children: [
              const Text(
                'Torrent Client',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildSpeedIndicator(Icons.arrow_downward, '12.4 MB/s', EverforestColors.green),
                  _buildSpeedIndicator(Icons.arrow_upward, '1.2 MB/s', EverforestColors.blue),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Torrent>>(
              stream: AppDatabase.instance.darkWebDao.watchAllTorrents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: EverforestColors.purple));
                }
                final torrents = snapshot.data!;
                if (torrents.isEmpty) {
                  return const Center(child: Text('No active torrents.', style: TextStyle(color: EverforestColors.grey)));
                }
                return ListView.separated(
                  itemCount: torrents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTorrentItem(torrents[index]);
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedIndicator(IconData icon, String speed, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(speed, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTorrentItem(Torrent torrent) {
    final isPaused = torrent.status == 'PAUSED';
    final totalSizeMB = (torrent.sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final downloadedMB = ((torrent.sizeBytes * torrent.progress) / (1024 * 1024)).toStringAsFixed(1);
    final speedKBps = (torrent.downloadSpeed / 1024).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  torrent.name,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: EverforestColors.fg),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close, color: EverforestColors.red),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: torrent.progress,
                    backgroundColor: EverforestColors.bg2,
                    color: torrent.progress == 1.0 ? EverforestColors.green : EverforestColors.blue,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(torrent.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$downloadedMB MB / $totalSizeMB MB',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
              if (torrent.progress < 1.0 && !isPaused)
                Text(
                  '$speedKBps KB/s',
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                )
              else if (isPaused)
                const Text('Paused', style: TextStyle(color: EverforestColors.yellow, fontSize: 12))
              else
                const Text('Seeding', style: TextStyle(color: EverforestColors.green, fontSize: 12))
            ],
          )
        ],
      ),
    );
  }
}
