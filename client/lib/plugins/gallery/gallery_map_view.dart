import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../theme/everforest_colors.dart';
import '../../core/device_gallery_service.dart';
import '../../presentation/widgets/photo_video_gallery/gallery_item.dart';
import '../../presentation/widgets/photo_video_gallery/aves_viewer_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class GalleryMapView extends StatefulWidget {
  const GalleryMapView({super.key});

  @override
  State<GalleryMapView> createState() => _GalleryMapViewState();
}

class _GalleryMapViewState extends State<GalleryMapView> {
  final DeviceGalleryService _galleryService = DeviceGalleryService();
  List<GalleryItem> _mappedItems = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();
  List<Marker> _mapMarkers = [];
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSub;

  @override
  void initState() {
    super.initState();
    _loadMappedMedia();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    
    // Initial fetch to ensure we have something immediately
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (_) {}

    // Continuous high-accuracy live tracking stream
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMappedMedia() async {
    final hasPermission = await _galleryService.requestPermission();
    if (!hasPermission) {
      setState(() => _isLoading = false);
      return;
    }

    // Load custom dataset cache for map locations
    final dir = await getApplicationDocumentsDirectory();
    final cacheFile = File('${dir.path}/map_locations_cache_v2.json');
    Map<String, dynamic> locationCache = {};
    if (await cacheFile.exists()) {
      try {
        locationCache = jsonDecode(await cacheFile.readAsString());
      } catch (e) {
        // Ignore cache parse errors
      }
    }

    // Fetch up to 5000 items to find locations
    final items = await _galleryService.fetchAllMedia(maxItems: 5000);
    List<GalleryItem> mapped = [];
    List<GalleryItem> unmapped = [];

    // Filter items using the fast JSON cache or synchronously available coordinates
    for (final item in items) {
      if (item.latitude != null && item.longitude != null && 
          item.latitude != 0.0 && item.longitude != 0.0) {
        mapped.add(item);
      } else if (locationCache.containsKey(item.id)) {
        final loc = locationCache[item.id];
        if (loc[0] != 0.0 && loc[1] != 0.0) {
          item.latitude = loc[0];
          item.longitude = loc[1];
          mapped.add(item);
        }
      } else {
        unmapped.add(item);
      }
    }

    // Instantly load the map with whatever is already cached
    if (mounted) {
      setState(() {
        _mappedItems = List.from(mapped);
        _isLoading = false;
        _updateMarkers();
      });
    }

    // Start background processor for unmapped photos
    if (unmapped.isNotEmpty) {
      _processUnmappedItems(unmapped, locationCache, cacheFile);
    }
  }

  Future<void> _processUnmappedItems(List<GalleryItem> unmapped, Map<String, dynamic> locationCache, File cacheFile) async {
    const chunkSize = 20;
    bool cacheUpdated = false;

    for (var i = 0; i < unmapped.length; i += chunkSize) {
      if (!mounted) return;
      
      final chunk = unmapped.skip(i).take(chunkSize);
      final List<GalleryItem> newlyMapped = [];

      // Query Exif dynamically in small chunks so we don't freeze the app
      await Future.wait(chunk.map((item) async {
        if (item.assetEntity != null) {
          final latlng = await item.assetEntity!.latlngAsync();
          if (latlng != null && latlng.latitude != null && latlng.longitude != null && latlng.latitude != 0.0 && latlng.longitude != 0.0) {
            item.latitude = latlng.latitude;
            item.longitude = latlng.longitude;
            newlyMapped.add(item);
            locationCache[item.id] = [latlng.latitude, latlng.longitude];
            cacheUpdated = true;
          } else {
            // Cache empty locations as well so we don't query them again
            locationCache[item.id] = [0.0, 0.0];
            cacheUpdated = true;
          }
        }
      }));

      if (newlyMapped.isNotEmpty && mounted) {
        setState(() {
          _mappedItems.addAll(newlyMapped);
          _updateMarkers();
        });
      }
    }

    if (cacheUpdated) {
      await cacheFile.writeAsString(jsonEncode(locationCache));
    }
  }

  void _updateMarkers() {
    _mapMarkers = _mappedItems.map((item) {
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
    }).toList();
  }

  void _openViewer(GalleryItem initialItem) {
    final index = _mappedItems.indexOf(initialItem);
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
    
    if (_mappedItems.isNotEmpty) {
      for (final item in _mappedItems) {
        avgLat += item.latitude!;
        avgLng += item.longitude!;
      }
      avgLat /= _mappedItems.length;
      avgLng /= _mappedItems.length;
    } else if (_currentLocation != null) {
      avgLat = _currentLocation!.latitude;
      avgLng = _currentLocation!.longitude;
    }

    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        title: const Text('Photo Map', style: TextStyle(color: EverforestColors.fg)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(avgLat, avgLng),
              initialZoom: 5.0,
              minZoom: 2.0,
              maxZoom: 19.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lifeos.client',
                keepBuffer: 3,
                maxZoom: 19.0,
              ),
              MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(50),
              maxZoom: 15,
              markers: _mapMarkers,
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
          if (_currentLocation != null)
            MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: StreamBuilder<MapEvent>(
            stream: _mapController.mapEventStream,
            builder: (context, snapshot) {
              final rot = _mapController.camera.rotation;
              return AnimatedOpacity(
                opacity: rot != 0.0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: EverforestColors.bg1.withOpacity(0.9),
                  onPressed: () {
                    _mapController.rotate(0.0);
                  },
                  child: Transform.rotate(
                    angle: -rot * math.pi / 180,
                    child: const Icon(Icons.navigation, color: EverforestColors.red),
                  ),
                ),
              );
            }
          ),
        ),
      ],
    ),
    );
  }
}
