import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';
import '../database/database.dart';
import '../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';
import 'cloud_gallery_service.dart';
import 'geocoding_service.dart';

class SmartPickResult {
  final GalleryItem item;
  final String place;
  final SmartAnalysis analysis;
  bool applied = false;

  SmartPickResult({required this.item, required this.place, required this.analysis});
}

/// Smart picker pipeline: resolve GPS -> reverse geocode -> server analysis
/// (hash/colors/source/title/tags) -> apply locally (tags DB) + cloud.
class SmartPickerService {
  static final SmartPickerService instance = SmartPickerService._();
  SmartPickerService._();

  final GeocodingService _geocoding = GeocodingService();

  /// Run the smart picker on one item. Returns null if analysis fails.
  Future<SmartPickResult?> pick(GalleryItem item) async {
    // Resolve GPS metadata + file path
    GalleryItem resolved = item;
    if (item.assetEntity != null) {
      final file = await item.assetEntity!.file;
      final latLng = await item.assetEntity!.latlngAsync();
      resolved = GalleryItem(
        id: item.id,
        label: item.label,
        pathOrUrl: file?.path ?? item.pathOrUrl,
        type: item.type,
        date: item.date,
        tags: item.tags,
        sizeBytes: item.sizeBytes,
        resolution: item.resolution,
        camera: item.camera,
        lens: item.lens,
        latitude: (latLng?.latitude != null && latLng!.latitude != 0) ? latLng.latitude : item.latitude,
        longitude: (latLng?.longitude != null && latLng!.longitude != 0) ? latLng.longitude : item.longitude,
        isLocal: item.isLocal,
        assetEntity: item.assetEntity,
      );
    }

    if (resolved.pathOrUrl.isEmpty) return null;

    // Reverse geocode to a place name (works offline-capable: fails -> empty)
    var place = '';
    if (resolved.latitude != null && resolved.longitude != null) {
      place = await _geocoding.reverse(LatLng(resolved.latitude!, resolved.longitude!));
    }

    final analysis = await CloudGalleryService.analyzeAsset(
      resolved.pathOrUrl,
      type: item.type == 'video' ? 'VIDEO' : 'PHOTO',
      place: place,
      date: resolved.date,
    );
    if (analysis == null) return null;

    return SmartPickResult(item: resolved, place: place, analysis: analysis);
  }

  /// Persist title/tags: local DB (MediaAssets filename + MediaTags rows) and
  /// cloud metadata (if the asset is already backed up).
  Future<bool> apply(SmartPickResult result) async {
    try {
      final db = AppDatabase.instance;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.galleryDao.insertOrUpdateAsset(MediaAssetsCompanion(
        id: Value(result.item.id),
        filename: Value(result.analysis.title),
        filePath: Value(result.item.pathOrUrl),
        fileSize: Value(result.item.sizeBytes),
        fileType: Value(result.item.type),
        latitude: Value(result.item.latitude),
        longitude: Value(result.item.longitude),
        captureTime: Value(result.item.date.millisecondsSinceEpoch),
        scanStatus: const Value('SMART_PICKED'),
        updatedAt: Value(now),
        isDirty: const Value(0),
      ));

      // Replace tags for this asset
      await db.customStatement('DELETE FROM media_tags WHERE asset_id = ?', [result.item.id]);
      for (final tag in result.analysis.tags) {
        await db.galleryDao.insertTag(MediaTagsCompanion(
          id: Value('tag_${result.item.id}_${tag.hashCode.abs()}'),
          assetId: Value(result.item.id),
          tagName: Value(tag),
          tagType: const Value('smart'),
          confidence: const Value(1.0),
          isDirty: const Value(0),
        ));
      }

      // If already backed up, update cloud metadata too
      if (result.item.isBackedUp) {
        await CloudGalleryService.updateAssetMeta(
          id: result.item.id,
          title: result.analysis.title,
          tags: result.analysis.tags,
          source: result.analysis.source,
          place: result.place,
        );
      }

      result.applied = true;
      return true;
    } catch (e) {
      print('Smart picker apply failed: $e');
      return false;
    }
  }

  /// Convenience: pick + apply + upload in one shot for a local item.
  Future<SmartPickResult?> pickAndUpload(GalleryItem item) async {
    final result = await pick(item);
    if (result == null) return null;

    // Upload to cloud (server dedupes + stores analysis); then apply tags locally
    if (item.assetEntity != null) {
      await CloudGalleryService.uploadAsset(item);
    }
    await apply(result);
    return result;
  }
}
