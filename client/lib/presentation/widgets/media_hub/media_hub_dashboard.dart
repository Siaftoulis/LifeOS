import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'music_library/music_dashboard_widget.dart';
import 'movie_library/movie_library_dashboard.dart';
import 'youtube_client/youtube_client_dashboard.dart';
import '../../../plugins/gallery/gallery_home_view.dart';

class MediaHubDashboard extends StatelessWidget {
  const MediaHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: EverforestColors.bg0,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg1,
          title: const Text('Media Hub', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Music'),
              Tab(text: 'Movies'),
              Tab(text: 'Gallery'),
              Tab(text: 'YouTube'),
            ],
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            indicatorColor: EverforestColors.green,
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            MusicDashboardWidget(),
            MovieLibraryDashboard(),
            GalleryHomeView(),
            YoutubeClientDashboard(),
          ],
        ),
      ),
    );
  }
}
