import 'package:flutter/material.dart';
import '../../../theme/app_skin_manager.dart';
import 'music_library/music_dashboard_widget.dart';
import 'movie_library/movie_library_dashboard.dart';
import 'youtube_client/youtube_client_dashboard.dart';
import '../../../plugins/gallery/gallery_home_view.dart';

class MediaHubDashboard extends StatelessWidget {
  const MediaHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: skin.bg0,
        appBar: AppBar(
          backgroundColor: skin.bg1,
          title: Text('Media Hub', style: TextStyle(color: skin.fg, fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: 'Music'),
              Tab(text: 'Movies'),
              Tab(text: 'Gallery'),
              Tab(text: 'YouTube'),
            ],
            labelColor: skin.accent,
            unselectedLabelColor: skin.textMuted,
            indicatorColor: skin.accent,
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
