import 'package:flutter/material.dart';
import '../../../theme/app_skin_manager.dart';
import 'music_library/music_dashboard_widget.dart';
import 'movie_library/movie_library_dashboard.dart';
import 'youtube_client/youtube_client_dashboard.dart';
import '../../../plugins/gallery/gallery_home_view.dart';

class MediaHubDashboard extends StatefulWidget {
  const MediaHubDashboard({super.key});

  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  static void switchTab(int index) {
    if (index >= 0 && index < 4) {
      activeTabNotifier.value = index;
    }
  }

  @override
  State<MediaHubDashboard> createState() => _MediaHubDashboardState();
}

class _MediaHubDashboardState extends State<MediaHubDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: MediaHubDashboard.activeTabNotifier.value.clamp(0, 3),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        MediaHubDashboard.activeTabNotifier.value = _tabController.index;
      }
    });
    MediaHubDashboard.activeTabNotifier.addListener(_onExternalTabChange);
  }

  void _onExternalTabChange() {
    final target = MediaHubDashboard.activeTabNotifier.value.clamp(0, 3);
    if (_tabController.index != target && mounted) {
      _tabController.animateTo(target);
    }
  }

  @override
  void dispose() {
    MediaHubDashboard.activeTabNotifier.removeListener(_onExternalTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Scaffold(
      backgroundColor: skin.bg0,
      appBar: AppBar(
        backgroundColor: skin.bg1,
        title: Text('Media Hub',
            style: TextStyle(color: skin.fg, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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
      body: TabBarView(
        controller: _tabController,
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: const [
          MusicDashboardWidget(),
          MovieLibraryDashboard(),
          GalleryHomeView(),
          YoutubeClientDashboard(),
        ],
      ),
    );
  }
}
