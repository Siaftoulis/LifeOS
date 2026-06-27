import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../presentation/widgets/photo_video_gallery/gallery_item.dart';

/// DeviceGalleryService — native device media provider using photo_manager.
/// Handles permissions, paginated fetching, date grouping, and album listing.
class DeviceGalleryService {
  static final DeviceGalleryService _instance = DeviceGalleryService._();
  factory DeviceGalleryService() => _instance;
  DeviceGalleryService._();

  static const int _pageSize = 80;
  bool _hasPermission = false;

  /// Request storage/media permissions. Returns true if granted.
  Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    _hasPermission = state.isAuth || state.hasAccess;
    
    if (_hasPermission) {
      if (Platform.isAndroid) {
        await Permission.accessMediaLocation.request();
      }
    }
    
    return _hasPermission;
  }

  bool get hasPermission => _hasPermission;

  /// Fetch a page of device media assets (images + videos), newest first.
  /// Returns converted [GalleryItem] list.
  Future<List<GalleryItem>> fetchMediaPage({int page = 0, String? albumId}) async {
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) return [];
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (albums.isEmpty) return [];

    AssetPathEntity targetAlbum = albums.first;
    if (albumId != null) {
      final found = albums.where((a) => a.id == albumId).toList();
      if (found.isNotEmpty) targetAlbum = found.first;
    }

    final int totalCount = await targetAlbum.assetCountAsync;

    final int start = page * _pageSize;
    if (start >= totalCount) return [];

    final List<AssetEntity> assets = await targetAlbum.getAssetListPaged(
      page: page,
      size: _pageSize,
    );

    // Convert AssetEntity → GalleryItem
    final List<GalleryItem> items = [];
    for (final asset in assets) {
      final String resolution = '${asset.width}x${asset.height}';
      final String type = asset.type == AssetType.video ? 'video' : 'photo';

      items.add(GalleryItem(
        id: asset.id,
        label: asset.title ?? 'Asset ${asset.id}',
        pathOrUrl: '', // Will be resolved lazily on-demand
        type: type,
        date: asset.createDateTime,
        tags: const [],
        sizeBytes: 0, // Will be resolved lazily on-demand
        resolution: resolution,
        camera: '',
        lens: '',
        latitude: asset.latitude,
        longitude: asset.longitude,
        isLocal: true,
        assetEntity: asset,
      ));
    }

    return items;
  }

  /// Fetch ALL media (paginated internally, returns flat list).
  /// Useful for initial grid load. Caps at [maxItems] to avoid OOM.
  Future<List<GalleryItem>> fetchAllMedia({int maxItems = 10000, String? albumId}) async {
    final List<GalleryItem> allItems = [];
    int page = 0;

    while (allItems.length < maxItems) {
      final batch = await fetchMediaPage(page: page, albumId: albumId);
      if (batch.isEmpty) break;
      allItems.addAll(batch);
      page++;
    }

    if (allItems.length > maxItems) {
      allItems.removeRange(maxItems, allItems.length);
    }
    
    // Ensure strict chronological descending order
    allItems.sort((a, b) => b.date.compareTo(a.date));
    
    return allItems;
  }

  /// Group items by date category for sticky headers.
  static Map<String, List<GalleryItem>> groupByDate(List<GalleryItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    final Map<String, List<GalleryItem>> groups = {};

    for (final item in items) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
      String key;

      if (itemDate == today) {
        key = 'Today';
      } else if (itemDate == yesterday) {
        key = 'Yesterday';
      } else if (itemDate.isAfter(thisWeekStart)) {
        key = 'This Week';
      } else if (itemDate.isAfter(thisMonthStart)) {
        key = 'This Month';
      } else if (itemDate.year == now.year) {
        key = _monthName(itemDate.month);
      } else {
        key = '${_monthName(itemDate.month)} ${itemDate.year}';
      }

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(item);
    }

    return groups;
  }

  /// Fetch album list with counts.
  Future<List<AlbumInfo>> fetchAlbums() async {
    if (!_hasPermission) return [];

    final albums = await PhotoManager.getAssetPathList(type: RequestType.common);
    final List<AlbumInfo> result = [];

    for (final album in albums) {
      final count = await album.assetCountAsync;
      if (count > 0) {
        final assets = await album.getAssetListPaged(page: 0, size: 1);
        AssetEntity? coverAsset;
        if (assets.isNotEmpty) coverAsset = assets.first;
        
        result.add(AlbumInfo(
          id: album.id,
          name: album.name,
          assetCount: count,
          coverAsset: coverAsset,
        ));
      }
    }

    return result;
  }

  /// Delete an asset by its ID. Returns true if successful.
  Future<bool> deleteAsset(String assetId) async {
    final List<String> ids = [assetId];
    final result = await PhotoManager.editor.deleteWithIds(ids);
    return result.isNotEmpty;
  }

  static String _monthName(int month) {
    const names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month];
  }
}

/// Simple album info model.
class AlbumInfo {
  final String id;
  final String name;
  final int assetCount;
  final AssetEntity? coverAsset;

  const AlbumInfo({
    required this.id,
    required this.name,
    required this.assetCount,
    this.coverAsset,
  });
}
