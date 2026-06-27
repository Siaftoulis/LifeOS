import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:extended_image/extended_image.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/preferences_service.dart';
import 'gallery_item.dart';
import 'metadata_sheet.dart';
import 'video_player_widget.dart';

class AvesViewerScreen extends StatefulWidget {
  final List<GalleryItem> items;
  final int initialIndex;

  const AvesViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<AvesViewerScreen> createState() => _AvesViewerScreenState();
}

class _AvesViewerScreenState extends State<AvesViewerScreen> with SingleTickerProviderStateMixin {
  late ExtendedPageController _pageController;
  late int _currentIndex;
  bool _isImmersive = false;
  double _bgOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = ExtendedPageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleImmersive() {
    setState(() {
      _isImmersive = !_isImmersive;
      if (_isImmersive) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Future<GalleryItem> _resolveFullMetadata(GalleryItem item) async {
    if (item.assetEntity == null) return item;
    
    // If already fully resolved, return it
    if (item.pathOrUrl.isNotEmpty && item.sizeBytes > 0) {
      return item;
    }

    final file = await item.assetEntity!.file;
    if (file == null) return item;

    final sizeBytes = await file.length();
    final latLng = await item.assetEntity!.latlngAsync();

    // Create resolved item
    final resolvedItem = GalleryItem(
      id: item.id,
      label: item.label,
      pathOrUrl: file.path,
      type: item.type,
      date: item.date,
      tags: item.tags,
      sizeBytes: sizeBytes,
      resolution: item.resolution,
      camera: item.camera,
      lens: item.lens,
      latitude: (latLng?.latitude != null && latLng!.latitude != 0) ? latLng.latitude : null,
      longitude: (latLng?.longitude != null && latLng!.longitude != 0) ? latLng.longitude : null,
      isLocal: item.isLocal,
      assetEntity: item.assetEntity,
    );

    // Update item cache
    final index = widget.items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      widget.items[index] = resolvedItem;
    }
    return resolvedItem;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      child: ExtendedImageSlidePage(
        slideAxis: SlideAxis.both,
        slideType: SlideType.onlyImage,
        slidePageBackgroundHandler: (Offset offset, Size pageSize) {
          double opacity = (1.0 - offset.dy.abs() / (pageSize.height / 2)).clamp(0.0, 1.0);
          return _isImmersive ? Colors.black : EverforestColors.bg0.withOpacity(opacity);
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              ExtendedImageGesturePageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  final item = widget.items[index];
                  return _buildImageProvider(item, index);
                },
              ),
              
              // Top AppBar Overlay
              AnimatedOpacity(
                opacity: _isImmersive ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: kToolbarHeight + MediaQuery.paddingOf(context).top,
                    padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: EverforestColors.fg),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
  
              // Bottom Actions Overlay
              AnimatedOpacity(
                opacity: _isImmersive ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 80 + MediaQuery.paddingOf(context).bottom,
                    padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: EverforestColors.fg),
                          onPressed: _showInfoSheet,
                          tooltip: 'Info',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: EverforestColors.fg),
                          onPressed: _editImage,
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: EverforestColors.fg),
                          onPressed: _shareImage,
                          tooltip: 'Share',
                        ),
                        ValueListenableBuilder<List<String>>(
                          valueListenable: PreferencesService.favoriteAssetIds,
                          builder: (context, favorites, _) {
                            final item = widget.items[_currentIndex];
                            final isFavorite = favorites.contains(item.id);
                            return IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? EverforestColors.red : EverforestColors.fg,
                              ),
                              onPressed: () => PreferencesService.toggleFavorite(item.id),
                              tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: EverforestColors.fg),
                          onPressed: _deleteImage,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoSheet() {
    final item = widget.items[_currentIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<GalleryItem>(
          future: _resolveFullMetadata(item),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: EverforestColors.green),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text('Error loading metadata', style: TextStyle(color: EverforestColors.fg)),
                ),
              );
            }
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: MetadataSheet(item: snapshot.data!),
            );
          },
        );
      },
    );
  }

  void _editImage() async {
    final item = widget.items[_currentIndex];
    final targetItem = await _resolveFullMetadata(item);
    if (targetItem.pathOrUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot locate image file.')));
      return;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: targetItem.pathOrUrl,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Edit',
            toolbarColor: EverforestColors.bg0,
            toolbarWidgetColor: EverforestColors.fg,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            activeControlsWidgetColor: EverforestColors.green,
            backgroundColor: EverforestColors.bg0,
            dimmedLayerColor: Colors.black.withOpacity(0.8),
        ),
      ],
    );

    if (croppedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: ${croppedFile.path}')));
      // In a production build, update the local registry and notify grid.
    }
  }

  void _shareImage() async {
    final item = widget.items[_currentIndex];
    final targetItem = await _resolveFullMetadata(item);
    if (targetItem.pathOrUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot locate image for share.')));
      return;
    }

    try {
      await Share.shareXFiles([XFile(targetItem.pathOrUrl)], text: targetItem.label);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    }
  }

  void _deleteImage() async {
    final item = widget.items[_currentIndex];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Delete Image', style: TextStyle(color: EverforestColors.fg)),
        content: const Text('Are you sure you want to delete this image from your device?', style: TextStyle(color: EverforestColors.fg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: EverforestColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (item.assetEntity != null) {
      try {
        final result = await PhotoManager.editor.deleteWithIds([item.id]);
        if (result.isNotEmpty) {
          setState(() {
            widget.items.removeAt(_currentIndex);
            if (widget.items.isEmpty) {
              Navigator.pop(context);
            } else {
              if (_currentIndex >= widget.items.length) {
                _currentIndex = widget.items.length - 1;
              }
              _pageController.jumpToPage(_currentIndex);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image deleted from device.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting image: $e')));
      }
    } else if (item.pathOrUrl.isNotEmpty) {
      try {
        final f = File(item.pathOrUrl);
        if (await f.exists()) {
          await f.delete();
          setState(() {
            widget.items.removeAt(_currentIndex);
            if (widget.items.isEmpty) {
              Navigator.pop(context);
            } else {
              if (_currentIndex >= widget.items.length) {
                _currentIndex = widget.items.length - 1;
              }
              _pageController.jumpToPage(_currentIndex);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting file: $e')));
      }
    }
  }

  Widget _buildImageProvider(GalleryItem item, int index) {
    if (item.type == 'video') {
      return VideoPlayerWidget(
        item: item,
        isImmersive: _isImmersive,
        onTap: _toggleImmersive,
      );
    }

    final imageProvider = item.assetEntity != null
        ? AssetEntityImageProvider(item.assetEntity!, isOriginal: true)
        : FileImage(File(item.pathOrUrl)) as ImageProvider;

    final imageWidget = Hero(
      tag: 'gallery_hero_${item.id}',
      child: ExtendedImage(
        image: imageProvider,
        fit: BoxFit.contain,
        mode: ExtendedImageMode.gesture,
        enableSlideOutPage: true,
        initGestureConfigHandler: (state) {
          return GestureConfig(
            minScale: 0.9,
            animationMinScale: 0.7,
            maxScale: 5.0,
            animationMaxScale: 5.5,
            speed: 1.0,
            inertialSpeed: 100.0,
            initialScale: 1.0,
            inPageView: true,
            initialAlignment: InitialAlignment.center,
          );
        },
        onDoubleTap: (ExtendedImageGestureState state) {
          final pointerDownPosition = state.pointerDownPosition;
          final begin = state.gestureDetails!.totalScale;
          double end;
  
          if (begin == 1.0) {
            end = 3.0;
          } else {
            end = 1.0;
          }
  
          state.handleDoubleTap(scale: end, doubleTapPosition: pointerDownPosition);
        },
      ),
    );

    return GestureDetector(
      onTap: _toggleImmersive,
      child: imageWidget,
    );
  }
}
