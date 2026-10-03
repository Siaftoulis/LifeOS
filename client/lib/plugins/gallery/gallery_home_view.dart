import 'package:flutter/material.dart';
import 'gallery_view.dart';
import 'album_list_view.dart';

import 'gallery_map_view.dart';
import 'cloud_view.dart';
import 'smart_picker_view.dart';

import '../../theme/app_skin_manager.dart';

class GalleryHomeView extends StatefulWidget {
  const GalleryHomeView({super.key});

  @override
  State<GalleryHomeView> createState() => _GalleryHomeViewState();
}

class _GalleryHomeViewState extends State<GalleryHomeView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSkinManager.currentSkinNotifier,
      builder: (context, _) {
        final skin = context.skin;
        final pages = [
          KeyedSubtree(key: ValueKey('gallery_view_${skin.id}'), child: const GalleryView()),
          KeyedSubtree(key: ValueKey('gallery_albums_${skin.id}'), child: const AlbumListView()),
          KeyedSubtree(key: ValueKey('gallery_map_${skin.id}'), child: const GalleryMapView()),
          KeyedSubtree(key: ValueKey('gallery_cloud_${skin.id}'), child: const CloudView()),
          KeyedSubtree(key: ValueKey('gallery_smart_${skin.id}'), child: const SmartPickerView()),
        ];

        return Scaffold(
          backgroundColor: skin.bg0,
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: skin.bg0,
            selectedItemColor: skin.accent,
            unselectedItemColor: skin.textMuted,
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
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome),
                label: 'Smart',
              ),
            ],
          ),
        );
      },
    );
  }
}
