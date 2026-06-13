import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'active_session_timer_overlay.dart';
import 'downloaded_videos_list.dart';

class YoutubeClientDashboard extends StatelessWidget {
  const YoutubeClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YouTube Client', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
              ActiveSessionTimerOverlay(),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _VideoSearchPanel()),
                SizedBox(width: 16),
                Expanded(flex: 3, child: DownloadedVideosList()),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _VideoSearchPanel extends StatelessWidget {
  const _VideoSearchPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Search & Download', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter YouTube URL...',
              hintStyle: const TextStyle(color: EverforestColors.grey),
              filled: true,
              fillColor: EverforestColors.bg0,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: IconButton(icon: const Icon(Icons.download, color: EverforestColors.green), onPressed: () {}),
            ),
            style: const TextStyle(color: EverforestColors.fg),
          ),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(child: Icon(Icons.video_library, size: 64, color: EverforestColors.bg2)),
          )
        ],
      ),
    );
  }
}
