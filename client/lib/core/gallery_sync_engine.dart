import 'dart:async';
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

  static const int _maxConcurrentUploads = 4;

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
      if (itemsToUpload.isEmpty) return;

      // Process in batches with controlled concurrency
      final semaphore = _Semaphore(_maxConcurrentUploads);
      final futures = <Future<void>>[];

      for (final item in itemsToUpload) {
        await semaphore.acquire();
        futures.add(_uploadWithSemaphore(item, semaphore));
      }

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Sync engine error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _uploadWithSemaphore(GalleryItem item, _Semaphore semaphore) async {
    try {
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
      
      final result = await CloudGalleryService.uploadAsset(resolvedItem);
      if (result.success) {
        syncedCount.value++;
      }
    } finally {
      semaphore.release();
    }
  }
}

class _Semaphore {
  final int _max;
  int _current = 0;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this._max);

  Future<void> acquire() async {
    if (_current < _max) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _current--;
    }
  }
}
