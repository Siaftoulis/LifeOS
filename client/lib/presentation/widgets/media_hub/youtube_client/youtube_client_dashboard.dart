import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../theme/everforest_colors.dart';
import '../../../../database/database.dart';
import '../../../../api_client.dart';

class YoutubeClientDashboard extends StatefulWidget {
  const YoutubeClientDashboard({super.key});

  @override
  State<YoutubeClientDashboard> createState() => _YoutubeClientDashboardState();
}

class _YoutubeClientDashboardState extends State<YoutubeClientDashboard> {
  @override
  void initState() {
    super.initState();
    _syncVideosFromBackend();
  }

  Future<void> _syncVideosFromBackend() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/youtube/videos');
      if (res is List) {
        final dao = AppDatabase.instance.youtubeDao;
        for (var item in res) {
          final video = item as Map<String, dynamic>;
          
          final entry = YoutubeDownloadsCompanion(
            id: drift.Value(video['id'] as String),
            videoId: drift.Value(video['id'] as String),
            title: drift.Value(video['title'] as String),
            filePath: const drift.Value('/data/media/stub.mp4'),
            sizeBytes: drift.Value(int.tryParse(video['size'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
            createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
            isDirty: const drift.Value(0),
          );

          try {
            await dao.insertDownload(entry);
          } catch (_) {
            // update if needed
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync videos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: StreamBuilder<List<YoutubeDownload>>(
          stream: AppDatabase.instance.youtubeDao.watchDownloads(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: EverforestColors.red));
            }
            final videos = snapshot.data!;
            if (videos.isEmpty) {
              return const Center(child: Text('No videos downloaded.', style: TextStyle(color: EverforestColors.grey)));
            }
            return GridView.builder(
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
                          color: EverforestColors.bg1,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.play_arrow, size: 64, color: EverforestColors.fg),
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
                            video.title.isNotEmpty ? video.title[0] : 'Y',
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
                                video.title,
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
                                'Size: ${(video.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
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
            );
          },
        ),
      ),
    );
  }
}
