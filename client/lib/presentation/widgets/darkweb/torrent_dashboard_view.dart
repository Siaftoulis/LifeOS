import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class TorrentDashboardView extends StatelessWidget {
  const TorrentDashboardView({super.key});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Torrent Client',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildSpeedIndicator(Icons.arrow_downward, '12.4 MB/s', EverforestColors.green),
                  const SizedBox(width: 16),
                  _buildSpeedIndicator(Icons.arrow_upward, '1.2 MB/s', EverforestColors.blue),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: mockTorrents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildTorrentItem(mockTorrents[index]);
              },
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

  Widget _buildTorrentItem(MockTorrent torrent) {
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
                icon: Icon(torrent.isPaused ? Icons.play_arrow : Icons.pause, color: EverforestColors.fg),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${torrent.downloaded} / ${torrent.totalSize}',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
              if (torrent.progress < 1.0 && !torrent.isPaused)
                Text(
                  '${torrent.speed} • ETA: ${torrent.eta}',
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                )
              else if (torrent.isPaused)
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

class MockTorrent {
  final String name;
  final double progress;
  final String downloaded;
  final String totalSize;
  final String speed;
  final String eta;
  final bool isPaused;

  MockTorrent({
    required this.name,
    required this.progress,
    required this.downloaded,
    required this.totalSize,
    required this.speed,
    required this.eta,
    this.isPaused = false,
  });
}

final mockTorrents = [
  MockTorrent(
    name: 'Ubuntu 24.04 LTS Desktop (amd64).iso',
    progress: 0.72,
    downloaded: '3.4 GB',
    totalSize: '4.7 GB',
    speed: '8.2 MB/s',
    eta: '2m 14s',
  ),
  MockTorrent(
    name: 'Arch Linux 2026.06.01 (x86_64).iso',
    progress: 1.0,
    downloaded: '950 MB',
    totalSize: '950 MB',
    speed: '0 KB/s',
    eta: '-',
  ),
  MockTorrent(
    name: 'FreeBSD-14.0-RELEASE-amd64-dvd1.iso',
    progress: 0.15,
    downloaded: '600 MB',
    totalSize: '4.0 GB',
    speed: '4.2 MB/s',
    eta: '12m 30s',
    isPaused: true,
  ),
];
