import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class YoutubeClientDashboard extends StatelessWidget {
  const YoutubeClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final videos = [
      {'title': 'Flutter Crash Course', 'channel': 'Tech Code', 'views': '1.2M views', 'time': '2 weeks ago', 'color': EverforestColors.blue},
      {'title': 'Building a Beautiful UI', 'channel': 'Design Pros', 'views': '850K views', 'time': '1 month ago', 'color': EverforestColors.purple},
      {'title': 'Top 10 Programming Languages', 'channel': 'Code World', 'views': '2.1M views', 'time': '3 months ago', 'color': EverforestColors.orange},
      {'title': 'Everforest Theme Setup', 'channel': 'Rice My Desktop', 'views': '300K views', 'time': '5 days ago', 'color': EverforestColors.green},
      {'title': 'Understanding State Management', 'channel': 'Flutter Guru', 'views': '500K views', 'time': '1 year ago', 'color': EverforestColors.yellow},
      {'title': 'Lofi Beats to Code To', 'channel': 'Chill Station', 'views': '10M views', 'time': 'Live', 'color': EverforestColors.red},
    ];

    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled, color: EverforestColors.red, size: 28),
            SizedBox(width: 12),
            Text('YouTube Client', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: EverforestColors.fg), onPressed: () {}),
          IconButton(icon: const Icon(Icons.account_circle, color: EverforestColors.fg), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1.1,
            crossAxisSpacing: 24,
            mainAxisSpacing: 32,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: video['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow, size: 64, color: EverforestColors.bg0),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Video Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: EverforestColors.bg2,
                      radius: 20,
                      child: Text(
                        (video['channel'] as String)[0],
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video['title'] as String,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${video['channel']} • ${video['views']} • ${video['time']}',
                            style: const TextStyle(
                              color: EverforestColors.grey,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: EverforestColors.grey),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
