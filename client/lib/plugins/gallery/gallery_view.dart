import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../core/device_gallery_service.dart';
import '../../database/preferences_service.dart';
import '../../presentation/widgets/photo_video_gallery/aves_viewer_screen.dart';
import '../../presentation/widgets/photo_video_gallery/gallery_item.dart';
import '../../theme/everforest_colors.dart';
import '../../core/cloud_gallery_service.dart';

class GalleryView extends StatefulWidget {
  final String? albumId;
  final String? albumName;
  const GalleryView({super.key, this.albumId, this.albumName});

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  final DeviceGalleryService _galleryService = DeviceGalleryService();
  List<GalleryItem> _items = [];
  Map<String, List<GalleryItem>> _groupedItems = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  Set<String> _cloudAssetIds = {};
  
  String _sourceMode = 'local'; // 'local' or 'cloud'
  bool _isFolderView = false;
  
  // Filter states
  bool _filterFavorite = false;
  bool _filterVideos = false;
  bool _filterPhotos = false;

  void _toggleFolderView() {
    setState(() {
      _isFolderView = !_isFolderView;
    });
  }

  void _toggleFilter(String filterName) {
    setState(() {
      if (filterName == 'Favorite') _filterFavorite = !_filterFavorite;
      if (filterName == 'Videos') _filterVideos = !_filterVideos;
      if (filterName == 'Photos') _filterPhotos = !_filterPhotos;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<GalleryItem> filtered = _items;
    
    if (_filterFavorite) {
      final favs = PreferencesService.favoriteAssetIds.value;
      filtered = filtered.where((item) => favs.contains(item.id)).toList();
    }
    if (_filterVideos || _filterPhotos) {
      filtered = filtered.where((item) {
        if (_filterVideos && item.type == 'video') return true;
        if (_filterPhotos && item.type == 'photo') return true;
        return false;
      }).toList();
    }

    if (_sourceMode == 'cloud') {
      filtered = filtered.where((item) => _cloudAssetIds.contains(item.id)).toList();
    }

    setState(() {
      _groupedItems = DeviceGalleryService.groupByDate(filtered);
    });
  }

  List<String> _expandedGroups = [];
  void _toggleGroup(String key) {
    setState(() {
      if (_expandedGroups.contains(key)) {
        _expandedGroups.remove(key);
      } else {
        _expandedGroups.add(key);
      }
    });
  }

  // Pinch-to-zoom grid state
  int _crossAxisCount = 4;
  double _baseScaleFactor = 1.0;
  double _currentScaleFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
    });

    final hasPermission = await _galleryService.requestPermission();
    setState(() {
      _hasPermission = hasPermission;
    });

    if (hasPermission) {
      final items = await _galleryService.fetchAllMedia(albumId: widget.albumId);
      final cloudIds = await CloudGalleryService.fetchCloudAssetIds();
      
      setState(() {
        _items = items;
        _cloudAssetIds = cloudIds;
        _applyFilters();
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Raw pointer state for pinch zoom
  final Map<int, Offset> _activePointers = {};
  double _initialDistance = 0.0;

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;
    if (_activePointers.length == 2) {
      final points = _activePointers.values.toList();
      _initialDistance = (points[0] - points[1]).distance;
      _baseScaleFactor = _currentScaleFactor;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointers.containsKey(event.pointer)) {
      _activePointers[event.pointer] = event.position;
    }

    if (_activePointers.length == 2) {
      final points = _activePointers.values.toList();
      final distance = (points[0] - points[1]).distance;
      if (_initialDistance > 0) {
        final scale = distance / _initialDistance;
        _handleScale(scale);
      }
    }
  }

  void _onPointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
  }

  void _handleScale(double scale) {
    setState(() {
      _currentScaleFactor = (_baseScaleFactor * scale).clamp(0.5, 3.0);
      
      if (_currentScaleFactor < 0.7) {
        _crossAxisCount = 6;
      } else if (_currentScaleFactor < 1.0) {
        _crossAxisCount = 5;
      } else if (_currentScaleFactor < 1.5) {
        _crossAxisCount = 4;
      } else if (_currentScaleFactor < 2.2) {
        _crossAxisCount = 3;
      } else {
        _crossAxisCount = 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library, size: 64, color: EverforestColors.fg),
            const SizedBox(height: 16),
            const Text(
              'Permission required to access device photos.',
              style: TextStyle(color: EverforestColors.fg),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMedia,
              style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
              child: const Text('Grant Permission', style: TextStyle(color: EverforestColors.bg0)),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty && _sourceMode == 'local') {
      return const Center(
        child: Text('No media found on device.', style: TextStyle(color: EverforestColors.fg)),
      );
    }

    final slivers = <Widget>[
      SliverAppBar(
        backgroundColor: EverforestColors.bg0,
        floating: true,
        pinned: false,
        title: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'local', label: Text('Local'), icon: Icon(Icons.phone_android, size: 18)),
            ButtonSegment(value: 'cloud', label: Text('Cloud'), icon: Icon(Icons.cloud_outlined, size: 18)),
          ],
          selected: {_sourceMode},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _sourceMode = newSelection.first;
              _applyFilters();
            });
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: EverforestColors.bg1,
            selectedForegroundColor: EverforestColors.bg0,
            selectedBackgroundColor: EverforestColors.green,
            side: const BorderSide(color: EverforestColors.bg2),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFolderView ? Icons.grid_view : Icons.folder_copy_outlined, color: EverforestColors.fg), 
            onPressed: _toggleFolderView,
            tooltip: 'Toggle Folders',
          ),
          IconButton(icon: const Icon(Icons.search, color: EverforestColors.fg), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: EverforestColors.fg), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip('Favorite', Icons.favorite, EverforestColors.red, _filterFavorite),
                const SizedBox(width: 8),
                _buildFilterChip('Videos', Icons.play_circle_filled, EverforestColors.blue, _filterVideos),
                const SizedBox(width: 8),
                _buildFilterChip('Photos', Icons.image, EverforestColors.yellow, _filterPhotos),
              ],
            ),
          ),
        ),
      )
    ];


      if (_isFolderView) {
      // Samsung Mobile Folder View
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.all(12.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dateKey = _groupedItems.keys.elementAt(index);
                final groupItems = _groupedItems[dateKey]!;
                return _buildDateFolderCard(dateKey, groupItems);
              },
              childCount: _groupedItems.length,
            ),
          ),
        )
      );
    } else {
      // Flat Sticky Header View
      _groupedItems.forEach((dateKey, groupItems) {
        // Group Header
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                dateKey,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );

        // Group Grid
        slivers.add(
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = groupItems[index];
                final globalIndex = _items.indexOf(item);
                final tag = 'gallery_hero_${item.id}';
                
                return GestureDetector(
                  onTap: () => Navigator.push(context, PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (_, __, ___) => AvesViewerScreen(
                      items: _items,
                      initialIndex: globalIndex,
                    ),
                  )),
                  child: Hero(
                    tag: tag,
                    child: _buildThumbnail(item),
                  ),
                );
              },
              childCount: groupItems.length,
            ),
          ),
        );
      });
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  Widget _buildThumbnail(GalleryItem item) {
    Widget imageWidget;
    if (item.assetEntity != null) {
      imageWidget = AssetEntityImage(
        item.assetEntity!,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize.square(300),
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image.file(
        File(item.pathOrUrl),
        fit: BoxFit.cover,
        cacheWidth: 300,
      );
    }

    return ValueListenableBuilder<List<String>>(
      valueListenable: PreferencesService.favoriteAssetIds,
      builder: (context, favorites, child) {
        final isFavorite = favorites.contains(item.id);
        return ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget,
              if (_cloudAssetIds.contains(item.id))
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.cloud_done, color: EverforestColors.green, size: 20),
                ),
              if (isFavorite)
                const Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(Icons.favorite, color: EverforestColors.red, size: 18),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color, bool isActive) {
    return GestureDetector(
      onTap: () => _toggleFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : EverforestColors.bg1,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isActive ? color : color.withOpacity(0.5)),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(
                color: isActive ? color : EverforestColors.fg, 
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFolderCard(String title, List<GalleryItem> items) {
    final previews = items.take(4).toList();
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: EverforestColors.bg0,
            appBar: AppBar(
              backgroundColor: EverforestColors.bg0,
              title: Text(title, style: const TextStyle(color: EverforestColors.fg)),
              iconTheme: const IconThemeData(color: EverforestColors.fg),
            ),
            body: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                   onTap: () => Navigator.push(context, PageRouteBuilder(
                     pageBuilder: (_, __, ___) => AvesViewerScreen(items: items, initialIndex: index),
                   )),
                   child: Hero(tag: 'folder_hero_${item.id}', child: _buildThumbnail(item)),
                );
              },
            ),
          )
        ));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: EverforestColors.bg1,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              clipBehavior: Clip.antiAlias,
              child: previews.length >= 4 
                ? Column(
                    children: [
                      Expanded(child: Row(
                        children: [
                          Expanded(child: _buildThumbnail(previews[0])),
                          const SizedBox(width: 2),
                          Expanded(child: _buildThumbnail(previews[1])),
                        ]
                      )),
                      const SizedBox(height: 2),
                      Expanded(child: Row(
                        children: [
                          Expanded(child: _buildThumbnail(previews[2])),
                          const SizedBox(width: 2),
                          Expanded(child: _buildThumbnail(previews[3])),
                        ]
                      )),
                    ],
                  )
                : _buildThumbnail(previews[0]),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              title,
              style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              '${items.length} items',
              style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
