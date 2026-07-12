import 'package:flutter/foundation.dart';
import 'device_gallery_service.dart';
import 'cloud_gallery_service.dart';
import '../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';

class GallerySyncEngine {
  static final GallerySyncEngine instance = GallerySyncEngine._internal();
  GallerySyncEngine._internal();

  final ValueNotifier<bool> isSyncing = ValueNotifier(false);
  final ValueNotifier<int> totalToSync = ValueNotifier(0);
  final ValueNotifier<int> syncedCount = ValueNotifier(0);

  Future<void> startSync() async {
    if (isSyncing.value) return;
    
    isSyncing.value = true;
    totalToSync.value = 0;
    syncedCount.value = 0;

    try {
      final galleryService = DeviceGalleryService();
      final localItems = await galleryService.fetchAllMedia();
      final cloudIds = await CloudGalleryService.fetchCloudAssetIds();

      final itemsToUpload = localItems.where((item) => !cloudIds.contains(item.id)).toList();
      
      totalToSync.value = itemsToUpload.length;

      for (var i = 0; i < itemsToUpload.length; i++) {
        final item = itemsToUpload[i];
        
        // resolve metadata if it's an asset entity without full info
        GalleryItem resolvedItem = item;
        if (item.assetEntity != null) {
            final file = await item.assetEntity!.file;
            if (file != null) {
              final sizeBytes = await file.length();
              final latLng = await item.assetEntity!.latlngAsync();
              resolvedItem = GalleryItem(
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
            }
        }
        
        final success = await CloudGalleryService.uploadAsset(resolvedItem);
        if (success) {
          syncedCount.value++;
        }
      }
    } catch (e) {
      debugPrint('Sync engine error: $e');
    } finally {
      isSyncing.value = false;
    }
  }
}
