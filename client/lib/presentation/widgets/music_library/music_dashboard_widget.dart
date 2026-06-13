import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'music_player_overlay.dart';

class MusicDashboardWidget extends StatelessWidget {
  const MusicDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Music Cloud', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _buildPlaylists()),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: _buildTrackGrid()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.music_note),
            label: const Text('Open Player Mock'),
            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.bg2),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const MusicPlayerOverlay(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylists() {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: ListView(
        children: const [
          ListTile(leading: Icon(Icons.queue_music, color: EverforestColors.green), title: Text('Focus Drive', style: TextStyle(color: EverforestColors.fg))),
          ListTile(leading: Icon(Icons.queue_music, color: EverforestColors.blue), title: Text('Synthwave 80s', style: TextStyle(color: EverforestColors.fg))),
          ListTile(leading: Icon(Icons.queue_music, color: EverforestColors.purple), title: Text('Acoustic Chill', style: TextStyle(color: EverforestColors.fg))),
        ],
      ),
    );
  }

  Widget _buildTrackGrid() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: const [
        _TrackCard(title: 'Nightcall', artist: 'Kavinsky', icon: Icons.album),
        _TrackCard(title: 'Resonance', artist: 'HOME', icon: Icons.album),
        _TrackCard(title: 'Blinding Lights', artist: 'The Weeknd', icon: Icons.album),
        _TrackCard(title: 'A Real Hero', artist: 'College', icon: Icons.album),
      ],
    );
  }
}

class _TrackCard extends StatelessWidget {
  final String title, artist;
  final IconData icon;

  const _TrackCard({required this.title, required this.artist, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(12), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EverforestColors.grey, size: 32),
          const Spacer(),
          Text(title, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          Text(artist, style: const TextStyle(color: EverforestColors.cyan, fontSize: 12)),
        ],
      ),
    );
  }
}
