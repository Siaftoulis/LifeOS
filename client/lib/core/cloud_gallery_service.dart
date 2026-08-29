import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';
import '../api_client.dart';
import '../database/database.dart';
import '../database/gallery_dao.dart';

class SmartAnalysis {
  final String hash;
  final int width;
  final int height;
  final List<String> colors;
  final String source;
  final String title;
  final List<String> tags;

  const SmartAnalysis({
    required this.hash,
    required this.width,
    required this.height,
    required this.colors,
    required this.source,
    required this.title,
    required this.tags,
  });

  factory SmartAnalysis.fromJson(Map<String, dynamic> e) => SmartAnalysis(
        hash: e['hash'] ?? '',
        width: e['width'] ?? 0,
        height: e['height'] ?? 0,
        colors: (e['colors'] as List?)?.cast<String>() ?? [],
        source: e['source'] ?? '',
        title: e['title'] ?? '',
        tags: (e['tags'] as List?)?.cast<String>() ?? [],
      );
}

class UploadResult {
  final bool success;
  final String id;
  final String? duplicateOf;
  final SmartAnalysis? analysis;

  const UploadResult({required this.success, required this.id, this.duplicateOf, this.analysis});
}

class CloudGalleryService {
  static String get baseUrl => '${ApiClient.instance.daemonUrl}/api/v1/gallery';
  static const String userId = 'u-pds-123';
  static const String deviceId = 'dev-mobile-01';

  static GalleryDao get _dao => AppDatabase.instance.galleryDao;

  /// Fetch cloud assets with pagination, using local cache first
  static Future<List<GalleryItem>> fetchCloudAssets({int limit = 50, int offset = 0, bool useCache = true}) async {
    // Try local cache first
    if (useCache) {
      final cached = await _dao.getCloudAssets(limit: limit, offset: offset);
      if (cached.isNotEmpty) {
        return cached.map(_cloudAssetToGalleryItem).toList();
      }
    }

    // Fallback to network
    try {
      final uri = Uri.parse('$baseUrl/assets').replace(queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> assets = data['assets'] ?? [];
        
        // Cache the results
        if (assets.isNotEmpty) {
          await _cacheCloudAssets(assets);
        }
        
        return assets.map<GalleryItem>((e) {
           return GalleryItem(
             id: e['id'],
             label: e['title'] != null && e['title'].toString().isNotEmpty
                 ? e['title']
                 : e['filename'] ?? 'cloud_item',
             pathOrUrl: '$baseUrl/stream?id=${e['id']}',
             type: e['type'] != null ? e['type'].toString().toLowerCase() : 'photo',
             date: DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now(),
             tags: (e['tags'] as List?)?.cast<String>() ?? [],
             sizeBytes: e['size_bytes'] ?? 0,
             resolution: '${e['width'] ?? ''}x${e['height'] ?? ''}',
             camera: e['source'] ?? '',
             lens: e['place'] ?? '',
             latitude: (e['lat'] as num?)?.toDouble(),
             longitude: (e['lng'] as num?)?.toDouble(),
             isLocal: false,
             isBackedUp: true,
             isCloudOnly: true,
           );
        }).toList();
      }
    } catch (e) {
      print('Error fetching cloud assets: $e');
    }
    return [];
  }

  static Future<void> _cacheCloudAssets(List<dynamic> assets) async {
    await _dao.transaction(() async {
      for (final e in assets) {
        await _dao.insertOrUpdateCloudAsset(CloudAssetsCompanion(
          id: Value(e['id'] as String),
          userId: Value(e['user_id'] as String? ?? ''),
          filename: Value(e['filename'] as String? ?? ''),
          type: Value(e['type'] as String? ?? ''),
          createdAt: Value(e['created_at'] as String? ?? ''),
          sizeBytes: Value(e['size_bytes'] as int? ?? 0),
          hash: Value(e['hash'] as String?),
          width: Value(e['width'] as int?),
          height: Value(e['height'] as int?),
          source: Value(e['source'] as String?),
          title: Value(e['title'] as String?),
          tags: Value(jsonEncode(e['tags'])),
          colors: Value(jsonEncode(e['colors'])),
          lat: Value((e['lat'] as num?)?.toDouble()),
          lng: Value((e['lng'] as num?)?.toDouble()),
          place: Value(e['place'] as String?),
          thumbnailUrl: Value('${ApiClient.instance.daemonUrl}/api/v1/gallery/thumbnail?id=${e['id']}'),
          streamUrl: Value('$baseUrl/stream?id=${e['id']}'),
          syncedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
      }
    });
  }

  static GalleryItem _cloudAssetToGalleryItem(CloudAsset e) => GalleryItem(
    id: e.id,
    label: e.title?.isNotEmpty == true ? e.title! : e.filename,
    pathOrUrl: e.streamUrl ?? '$baseUrl/stream?id=${e.id}',
    type: e.type.toLowerCase(),
    date: DateTime.tryParse(e.createdAt) ?? DateTime.now(),
    tags: const [],
    sizeBytes: e.sizeBytes,
    resolution: '${e.width ?? 0}x${e.height ?? 0}',
    camera: e.source ?? '',
    lens: e.place ?? '',
    latitude: e.lat,
    longitude: e.lng,
    isLocal: false,
    isBackedUp: true,
    isCloudOnly: true,
  );

  /// Fetch all cloud asset IDs (for sync comparison)
  static Future<Set<String>> fetchCloudAssetIds() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assets?limit=10000'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> assets = data['assets'] ?? [];
        return assets.map((e) => e['id'] as String).toSet();
      }
    } catch (e) {
      print('Error fetching cloud asset IDs: $e');
    }
    return {};
  }

  /// Upload a local asset to the cloud.
  static Future<UploadResult> uploadAsset(GalleryItem item) async {
    if (item.assetEntity == null) return const UploadResult(success: false, id: '');

    try {
      final file = await item.assetEntity!.file;
      if (file == null) return const UploadResult(success: false, id: '');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.fields['user_id'] = userId;
      request.fields['device_id'] = deviceId;
      request.fields['asset_id'] = item.id;
      request.fields['type'] = item.type.toUpperCase();
      request.fields['created_at'] = item.date.toUtc().toIso8601String();
      if (item.latitude != null && item.longitude != null) {
        request.fields['lat'] = '${item.latitude}';
        request.fields['lng'] = '${item.longitude}';
      }
      if (item.resolution.isNotEmpty) {
        final parts = item.resolution.split('x');
        if (parts.length == 2) {
          request.fields['width'] = parts[0];
          request.fields['height'] = parts[1];
        }
      }

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send().timeout(const Duration(minutes: 5));
      final body = await response.stream.bytesToString();
      final Map<String, dynamic> data = body.isEmpty ? {} : jsonDecode(body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Invalidate cache so next fetch gets fresh data
        await _dao.clearCloudAssets();
        
        return UploadResult(
          success: true,
          id: data['id'] ?? item.id,
          duplicateOf: data['duplicate_of'],
          analysis: data['title'] != null
              ? SmartAnalysis(
                  hash: data['hash'] ?? '',
                  width: data['width'] ?? 0,
                  height: data['height'] ?? 0,
                  colors: (data['colors'] as List?)?.cast<String>() ?? [],
                  source: data['source'] ?? '',
                  title: data['title'] ?? '',
                  tags: (data['tags'] as List?)?.cast<String>() ?? [],
                )
              : null,
        );
      }
    } catch (e) {
      print('Error uploading asset: $e');
    }
    return const UploadResult(success: false, id: '');
  }

  /// Smart picker endpoint: analyze a file without saving it.
  static Future<SmartAnalysis?> analyzeAsset(
    String filePath, {
    String type = 'PHOTO',
    String place = '',
    DateTime? date,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));
      request.fields['type'] = type;
      if (place.isNotEmpty) request.fields['place'] = place;
      if (date != null) request.fields['date'] = date.toUtc().toIso8601String();
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send().timeout(const Duration(minutes: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return SmartAnalysis.fromJson(data);
      }
    } catch (e) {
      print('Error analyzing asset: $e');
    }
    return null;
  }

  /// Fetch duplicate groups
  static Future<List<Map<String, dynamic>>> fetchDuplicates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/duplicates'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching duplicates: $e');
    }
    return [];
  }

  /// Update title/tags/source for a cloud asset.
  static Future<bool> updateAssetMeta({
    required String id,
    String? title,
    List<String>? tags,
    String? source,
    String? place,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/meta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          if (title != null) 'title': title,
          if (tags != null) 'tags': tags,
          if (source != null) 'source': source,
          if (place != null) 'place': place,
        }),
      );
      if (response.statusCode == 200) {
        await _dao.clearCloudAssets(); // Invalidate cache
      }
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating asset meta: $e');
      return false;
    }
  }

  /// Delete a cloud asset from the server and clear local cache
  static Future<bool> deleteAsset(String assetId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/asset?id=$assetId'));
      if (response.statusCode == 200) {
        await _dao.deleteCloudAsset(assetId);
        return true;
      }
    } catch (e) {
      print('Error deleting asset: $e');
    }
    return false;
  }
}
