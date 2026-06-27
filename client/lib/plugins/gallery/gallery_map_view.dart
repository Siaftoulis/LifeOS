import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../theme/everforest_colors.dart';
import '../../core/device_gallery_service.dart';
import '../../presentation/widgets/photo_video_gallery/gallery_item.dart';
import '../../presentation/widgets/photo_video_gallery/aves_viewer_screen.dart';
import 'dart:io';

class GalleryMapView extends StatefulWidget {
  const GalleryMapView({super.key});

  @override
  State<GalleryMapView> createState() => _GalleryMapViewState();
}

class _GalleryMapViewState extends State<GalleryMapView> {
  final DeviceGalleryService _galleryService = DeviceGalleryService();
  List<GalleryItem> _mappedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMappedMedia();
  }

  Future<void> _loadMappedMedia() async {
    final hasPermission = await _galleryService.requestPermission();
    if (!hasPermission) {
      setState(() => _isLoading = false);
      return;
    }

    // Fetch up to 5000 items to find locations
    final items = await _galleryService.fetchAllMedia(maxItems: 5000);
    List<GalleryItem> mapped = [];

    // Process in chunks to avoid overwhelming the platform channel
    const chunkSize = 50;
    for (var i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize);
      await Future.wait(chunk.map((item) async {
        if (item.assetEntity != null) {
          final latlng = await item.assetEntity!.latlngAsync();
          if (latlng != null && latlng.latitude != null && latlng.longitude != null && latlng.latitude != 0.0 && latlng.longitude != 0.0) {
            mapped.add(GalleryItem(
              id: item.id,
              label: item.label,
              pathOrUrl: item.pathOrUrl,
              type: item.type,
              date: item.date,
              tags: item.tags,
              sizeBytes: item.sizeBytes,
              resolution: item.resolution,
              camera: item.camera,
              lens: item.lens,
              latitude: latlng.latitude,
              longitude: latlng.longitude,
              isLocal: item.isLocal,
              assetEntity: item.assetEntity,
            ));
          }
        }
      }));
      
      // Update UI incrementally every 500 items to show progress
      if (i % 500 == 0 && mapped.isNotEmpty) {
        setState(() {
          _mappedItems = List.from(mapped);
        });
      }
    }

    setState(() {
      _mappedItems = mapped;
      _isLoading = false;
    });
  }

  void _openViewer(GalleryItem item) {
    final index = _mappedItems.indexOf(item);
    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => AvesViewerScreen(
        items: _mappedItems,
        initialIndex: index,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }

    if (_mappedItems.isEmpty) {
      return const Center(
        child: Text(
          'No photos with location metadata found.',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }

    // Calculate bounding box or average center
    double avgLat = 0.0;
    double avgLng = 0.0;
    for (final item in _mappedItems) {
      avgLat += item.latitude!;
      avgLng += item.longitude!;
    }
    avgLat /= _mappedItems.length;
    avgLng /= _mappedItems.length;

    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        title: const Text('Photo Map', style: TextStyle(color: EverforestColors.fg)),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(avgLat, avgLng),
          initialZoom: 5.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.lifeos.client',
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(50),
              maxZoom: 15,
              markers: _mappedItems.map((item) {
                return Marker(
                  point: LatLng(item.latitude!, item.longitude!),
                  width: 48,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _openViewer(item),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: EverforestColors.green, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.assetEntity != null
                          ? AssetEntityImage(
                              item.assetEntity!,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize.square(50),
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(item.pathOrUrl),
                              fit: BoxFit.cover,
                              cacheWidth: 50,
                            ),
                    ),
                  ),
                );
              }).toList(),
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EverforestColors.green.withOpacity(0.9),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Center(
                    child: Text(
                      markers.length.toString(),
                      style: const TextStyle(
                        color: EverforestColors.bg0,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
