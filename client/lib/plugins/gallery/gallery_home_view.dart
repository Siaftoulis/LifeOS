import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';
import 'gallery_view.dart';
import 'album_list_view.dart';

import 'gallery_map_view.dart';
import 'cloud_view.dart';

class GalleryHomeView extends StatefulWidget {
  const GalleryHomeView({super.key});

  @override
  State<GalleryHomeView> createState() => _GalleryHomeViewState();
}

class _GalleryHomeViewState extends State<GalleryHomeView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    GalleryView(),
    AlbumListView(),
    GalleryMapView(),
    CloudView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: EverforestColors.bg0,
        selectedItemColor: EverforestColors.green,
        unselectedItemColor: EverforestColors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Photos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Albums',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Cloud',
          ),
        ],
      ),
    );
  }
}
