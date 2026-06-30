import 'package:photo_manager/photo_manager.dart';

class GalleryItem {
  final String id;
  final String label;
  final String pathOrUrl;
  final String type; // 'photo' or 'video'
  final DateTime date;
  final List<String> tags;
  final int sizeBytes;
  final String resolution;
  final String camera;
  final String lens;
  double? latitude;
  double? longitude;
  final bool isLocal;
  final bool isBackedUp;
  final bool isCloudOnly;
  final AssetEntity? assetEntity;

  GalleryItem({
    required this.id,
    required this.label,
    required this.pathOrUrl,
    required this.type,
    required this.date,
    required this.tags,
    required this.sizeBytes,
    required this.resolution,
    required this.camera,
    required this.lens,
    this.latitude,
    this.longitude,
    required this.isLocal,
    this.isBackedUp = false,
    this.isCloudOnly = false,
    this.assetEntity,
  });
}
