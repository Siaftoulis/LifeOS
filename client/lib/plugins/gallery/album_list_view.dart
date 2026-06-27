import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../core/device_gallery_service.dart';
import '../../theme/everforest_colors.dart';
import 'gallery_view.dart';

class AlbumListView extends StatefulWidget {
  const AlbumListView({super.key});

  @override
  State<AlbumListView> createState() => _AlbumListViewState();
}

class _AlbumListViewState extends State<AlbumListView> {
  final DeviceGalleryService _galleryService = DeviceGalleryService();
  List<AlbumInfo> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final hasPerm = await _galleryService.requestPermission();
    if (hasPerm) {
      final albums = await _galleryService.fetchAlbums();
      setState(() {
        _albums = albums;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }

    if (_albums.isEmpty) {
      return const Center(
        child: Text('No albums found.', style: TextStyle(color: EverforestColors.fg)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: Text(album.name, style: const TextStyle(color: EverforestColors.fg)),
                    backgroundColor: EverforestColors.bg0,
                    iconTheme: const IconThemeData(color: EverforestColors.fg),
                  ),
                  backgroundColor: EverforestColors.bg0,
                  body: GalleryView(albumId: album.id, albumName: album.name),
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: EverforestColors.bg1,
                    width: double.infinity,
                    child: album.coverAsset != null
                        ? AssetEntityImage(
                            album.coverAsset!,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize.square(300),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.folder, color: EverforestColors.green, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${album.assetCount} items',
                style: const TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
